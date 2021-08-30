
















param
(
	[string]$serverInstance = "(local)",
  	[string]$tempDir = "C:\Dexma\TEMP\",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-ServerAttrib-Html $serverInstance $tempDir
}

function Get-MSSQL-ServerAttrib-Html($serverInstance, $tempDir)
{
	$outputFile = $tempDir + "SQLServerAttributes.html"
	Write-Debug "Output directory: $outputFile"
	
	
	if (-not (Test-Path -path $tempDir)) 
	{
		Write-Host Unable to validate path to temp directory: $tempDir
		break
	}
	
	
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") 
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
	
	
	Write-Debug "Connecting to server: $ServerInstance" 
	$namedInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') ($serverInstance)

	
	
	
	Write-Debug "Saving $outputFile..."
	
	$namedInstance.EnumServerAttributes() | `
		convertto-html -property attribute_name, attribute_value `
		-title "Server Attributes" -body '<font face="Verdana">' `
		| foreach {$_ -replace "<th>", "<th align=left>"} `
		| Out-File $outputFile
	
	
	
	invoke-item $outputFile -confirm

	
	remove-variable namedInstance 
	remove-variable tempDir
	remove-variable outputFile
}

main 