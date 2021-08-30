function Validate-Xml {
	param ([string]$XmlFilePath)
	try {
		
		$XmlFile = Get-Item($XmlFilePath)
		
		
		$script:ErrorCount = 0
		
		
		$ReaderSettings = New-Object -TypeName System.Xml.XmlReaderSettings
		$ReaderSettings.ValidationType = [System.Xml.ValidationType]::Schema
		$ReaderSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessInlineSchema -bor [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation
		$ReaderSettings.add_ValidationEventHandler({ $script:ErrorCount++ })
		$Reader = [System.Xml.XmlReader]::Create($XmlFile.FullName, $ReaderSettings)
		while ($Reader.Read()) { }
		$Reader.Close()
		
		
		if ($script:ErrorCount -gt 0) {
			
			$false
		} else {
			
			$true
		}
	} catch {
		Write-Warning "$($MyInvocation.MyCommand.Name) - Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}