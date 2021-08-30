

function ConvertDataRow-ToXml
{
		
	
	[CmdletBinding()]
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter(Mandatory,ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[System.Data.DataRow[]]$Row,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ObjectType,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('\.xml$')]
		[ValidateScript({ -not (Test-Path -Path $_ -PathType Leaf) })]
		[string]$Path
	)
	begin {
		$ErrorActionPreference = 'Stop'
		
		$xmlWriter = New-Object System.XMl.XmlTextWriter($Path, $Null)
		$xmlWriter.Formatting = 'Indented'
		$xmlWriter.Indentation = 1
		$XmlWriter.IndentChar = "`t"
		$xmlWriter.WriteStartDocument()
		$xmlWriter.WriteStartElement('{0}s' -f $ObjectType)
	}
	process {
		try
		{
			foreach ($r in $row)
			{
				$properties = $r.psobject.Properties.where{ $_.Value -is [string] -and $_.Name -ne 'RowError' }
				$xmlWriter.WriteStartElement($ObjectType)
				foreach ($prop in $properties)
				{
					Write-Verbose -Message "Adding attribute name [$($prop.Name)] with value [$($prop.Value)]"
					$xmlWriter.WriteElementString($prop.Name, $prop.Value)
				}
				$xmlWriter.WriteEndElement()
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
	end
	{
		$xmlWriter.WriteEndDocument()
		$xmlWriter.Flush()
		$xmlWriter.Close()
		Get-Item -Path $Path
	}
}