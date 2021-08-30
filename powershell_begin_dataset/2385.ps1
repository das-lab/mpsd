function New-XmlSchema
{
		
	
	[CmdletBinding()]
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[ValidatePattern('\.xml$')]
		[string]$XmlFilePath,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path ($_ | Split-Path -Parent) -PathType Container })]
		[ValidatePattern('\.xsd$')]
		[string]$SchemaFilePath = "$($XmlFilePath | Split-Path -Parent)\$([System.IO.Path]::GetFileNameWithoutExtension($XmlFilePath)).xsd",
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Force
		
	)
	process {
		try
		{
			$ErrorActionPreference = 'Stop'
			
			if (-not (Get-Module -Name Pscx) -and (-not (Get-Module -Name Pscx -ListAvailable)))
			{
				throw "The PowerShell Community Extensions module is not installed. This module can be downloaded at https://pscx.codeplex.com/releases."
			}
			
			if (Test-Path -Path $SchemaFilePath -PathType Leaf)
			{
				if ($Force.IsPresent)
				{
					Remove-Item -Path $SchemaFilePath
				}
				else
				{
					throw "The schema file path [$($SchemaFilePath)] already exists. Remove the existing schema or use -Force to overwrite."
				}
			}
			
			if (-not (Test-Xml -Path $XmlFilePath))
			{
				throw "The XML file [$($XmlFilePath)] is malformed. Please run Test-Xml against the XML file to see what is wrong."
			}
			
			$reader = [System.Xml.XmlReader]::Create($XmlFilePath)
			
			
			$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
			$schema = New-Object System.Xml.Schema.XmlSchemaInference
			
			
			$schemaSet = $schema.InferSchema($reader)
			
			
			$xsdFilePath = New-Object System.IO.FileStream($SchemaFilePath, [IO.FileMode]::CreateNew)
			
			
			$xwriter = New-Object System.Xml.XmlTextWriter($xsdFilePath, [Text.Encoding]::UTF8)
			
			
			$xwriter.Formatting = [System.Xml.Formatting]::Indented
			
			
			$schemaSet.Schemas() | ForEach-Object {
				[System.Xml.Schema.XmlSchema]$_.Write($xwriter)
			}
			
			$xwriter.Close()
			$reader.Close()
			
			if (-not (Test-Xml -Path $XmlFilePath -SchemaPath $SchemaFilePath))
			{
				throw "Schema generation has failed for XML file [$($XmlFilePath)]."
			}
			Get-Item -Path $SchemaFilePath
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
}