
[CmdletBinding()]
[OutputType()]
param (
	[Parameter(Mandatory)]
	[string]$InvoiceTitle,
	[Parameter(Mandatory)]
	[string]$InvoiceNumber,
	[Parameter(Mandatory)]
	[string]$ClientCompany,
	[Parameter(Mandatory)]
	[string]$ClientName,
	[Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
	[hashtable[]]$Item,
	[Parameter()]
	[string]$TopNote,
	[Parameter()]
	[string]$BottomNote,
	[Parameter()]
	[switch]$Force,
	[Parameter()]
	[ValidateScript({ Test-Path -Path $_ -PathType Leaf})]
	[string]$TemplateXmlFilePath = "$PSScriptRoot\InvoiceTemplate.xml",
	[Parameter()]
	[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
	[string]$TemplateXslFilePath = "$PSScriptRoot\InvoiceTemplate.xsl",
	[Parameter()]
	[string]$InvoiceFilePath = "$PSScriptRoot\Invoice.pdf"
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	try {
		
		if (!$Force.IsPresent) {
			if (Test-Path -Path $InvoiceFilePath -PathType Leaf) {
				throw 'Existing invoice already exists at specified path.  To overwrite, use the -Force parameter'
			}
		}
		
		function New-InvoiceItem ($ItemDescription, $ItemPrice, $ItemQuantity) {
			
			$NewItem = $InvoiceXml.CreateElement("Item")
			[void]$NewItem.AppendChild($InvoiceXml.CreateElement("Description"))
			[void]$NewItem.AppendChild($InvoiceXml.CreateElement("Price"))
			[void]$NewItem.AppendChild($InvoiceXml.CreateElement("Quantity"))
			$NewItem.Description = $ItemDescription
			$NewItem.Price = $ItemPrice
			$NewItem.Quantity = $ItemQuantity
			[void]$InvoiceXml.Invoice.AppendChild($NewItem)
		}
		
		Function ConvertTo-PDF {
			[CmdletBinding()]
			param(
				[Parameter(ValueFromPipeline)]
				[string]$Html,
				[Parameter()]
				[string]$FileName
			)
			begin {
				$DllLoaded = $false
				$PdfGenerator = "$PsScriptRoot\NReco.PdfGenerator.dll"
				if (Test-Path $PdfGenerator) {
					try {
						$Assembly = [Reflection.Assembly]::LoadFrom($PdfGenerator)
						$PdfCreator = New-Object NReco.PdfGenerator.HtmlToPdfConverter
						$DllLoaded = $true
					} catch {
						Write-Error ('ConvertTo-PDF: Issue loading or using NReco.PdfGenerator.dll: {0}' -f $_.Exception.Message)
					}
				} else {
					Write-Error ('ConvertTo-PDF: NReco.PdfGenerator.dll was not found.')
				}
			}
			PROCESS {
				if ($DllLoaded) {
					$ReportOutput = $PdfCreator.GeneratePdf([string]$HTML)
					Add-Content -Value $ReportOutput -Encoding byte -Path $FileName
				} else {
					Throw 'Error Occurred'
				}
			}
			END { }
		}
	
	
} catch {
	Write-Error $_.Exception.Message
	break
}
}

process {
	try {
		Write-Verbose 'Building XML object'
		
		Write-Verbose "Getting template XML file $TemplateXmlFilePath"
		$script:InvoiceXml = [xml](Get-Content $TemplateXmlFilePath)
		
		
		$InvoiceXml.Invoice.InvoiceTitle = $InvoiceTitle
		$InvoiceXml.Invoice.Date = (Get-Date).ToShortDateString()
		$InvoiceXml.Invoice.ClientCompany = $ClientCompany
		$InvoiceXml.Invoice.ClientName = $ClientName
		$InvoiceXml.Invoice.InvoiceNumber = $InvoiceNumber
		$InvoiceXml.Invoice.TopNote = $TopNote
		$InvoiceXml.Invoice.BottomNote = $BottomNote
		
		
		foreach ($i in $Item) {
			if (!($i.ContainsKey('Description')) -or !($i.ContainsKey('Price')) -or !($i.ContainsKey('Quantity'))) {
				Write-Warning "Item found that does not have all necessary fields to add to invoice"
			} else {
				Write-Verbose "Adding invoice item '$($i.Description)' to invoice"
				New-InvoiceItem -ItemDescription $i.Description -ItemPrice $i.Price -ItemQuantity $i.Quantity
			}
		}
		
		
		Write-Verbose "Removing existing invoice '$InvoiceFilePath'"
		Remove-Item -Path $InvoiceFilePath -Force -ea 'SilentlyContinue'
		
		
		if (([System.IO.FileInfo]$InvoiceFilePath).Extension -eq '.xml') {
			$XmlOutput = $InvoiceFilePath
		} else {
			$XmlOutput = "$PsScriptRoot\TempXml.xml"
		}
		Write-Verbose "Saving XML file output as '$XmlOutput'"
		$InvoiceXml.Save($XmlOutput)
		
		Write-Verbose "Loading XSL file '$TemplateXslFilePath'"
		$xslt = New-Object System.Xml.Xsl.XslCompiledTransform
		$xslt.Load($TemplateXslFilePath)
		
		if (([System.IO.FileInfo]$InvoiceFilePath).Extension -eq '.html') {
			$HtmlOutput = $InvoiceFilePath
		} else {
			$HtmlOutput = "$PsScriptRoot\TempHtml.Html"
		}
		Write-Verbose "Transforming XML to HTML file '$HtmlOutput'"
		$xslt.Transform($XmlOutput, $HtmlOutput)

	} catch {
		Write-Error $_.Exception.Message
	}
}
end {
	try {
		switch (([System.IO.FileInfo]$InvoiceFilePath).Extension) {
			'.xml' {
				Write-Verbose "XML output chosen.  Removing temporary HTML file '$HtmlOutput'"
				Remove-Item -Path $HtmlOutput -Force -ea 'SilentlyContinue'
			}
			'.html' {
				Write-Verbose "HTML output chosen.  Removing temporary XML file '$XmlOutput'"
				Remove-Item -Path $XmlOutput -Force -ea 'SilentlyContinue'
			}
			'.pdf' {
				Write-Verbose "Converting '$HtmlOutput' content to PDF file '$InvoiceFilePath'"
				ConvertTo-PDF -Html (Get-Content $HtmlOutput -Raw) -FileName $InvoiceFilePath
				Write-Verbose "PDF output chosen.  Removing temporary HTML and XML files"
				Remove-Item -Path $HtmlOutput -Force -ea 'SilentlyContinue'
				Remove-Item -Path $XmlOutput -Force -ea 'SilentlyContinue'
			}
		}
	} catch {
		Write-Error $_.Exception.Message	
	}
}