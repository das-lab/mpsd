

function Convert-SPOFileVariablesToValues
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[System.IO.FileSystemInfo]$file
	)

	$filePath = $file.FullName
	$tempFilePath = "$filePath.temp"
	
	Write-Host "Replacing variables at $filePath" -foregroundcolor black -backgroundcolor yellow
    	
	$serverRelativeUrl = $clientContext.Site.ServerRelativeUrl
	if ($serverRelativeUrl -eq "/") {
		$serverRelativeUrl = ""
	}
	
	(get-content $filePath) | foreach-object {$_ -replace "~SiteCollection", $serverRelativeUrl } | set-content $tempFilePath
    
	return Get-Item -Path $tempFilePath
}
