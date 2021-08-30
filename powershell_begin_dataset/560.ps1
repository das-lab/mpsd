

function Convert-SPOStringVariablesToValues
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[String]$string
	)
	
	Write-Host "Replacing variables string variables" -foregroundcolor black -backgroundcolor yellow
	
	$serverRelativeUrl = $clientContext.Site.ServerRelativeUrl
	if ($serverRelativeUrl -eq "/") {
		$serverRelativeUrl = ""
	}
	
	$returnString = $string -replace "~SiteCollection", $serverRelativeUrl
    
	return $returnString
}
