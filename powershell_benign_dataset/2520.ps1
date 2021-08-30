
















 
param
(
	[string]$serverInstance = "STGSQL610",
  	[string]$tempDir = "C:\Dexma\Logs\",
	[string]$filter = "objects",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-Views-Csv $serverInstance $tempDir $filter
}

function Get-MSSQL-Views-Csv($serverInstance, $tempDir, $filter)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}

	$outputFile = $tempDir + "GetViews.csv"
	
	
	Write-Debug "Validate output path $tempDir"
	if (-not (Test-Path -path $tempDir)) 
	{
		Write-Host "Unable to validate path to temp directory: $tempDir"
		break
	}

	
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") 
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
	
	
	Write-Debug "Get SMO named instance object for server: $serverInstance"
	$namedInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') ($serverInstance)
	
	
	Write-Debug "Exporting filtered views based on filter:$filter to $outputfile"
	($namedInstance.databases["master"]).get_views() | 
		where {$_ -like "*$filter*"} | Export-Csv -path $outputFile
}

main