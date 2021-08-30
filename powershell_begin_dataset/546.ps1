

function Set-SPOCustomMasterPage
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$masterFile
	)

    $masterUrl = Join-SPOParts -Separator '/' -Parts $clientContext.Site.ServerRelativeUrl, "/_catalogs/masterpage/$masterFile"

    $web = $clientContext.Web

    
    Write-Host "Master page wordt ingesteld op $masterFile" -foregroundcolor black -backgroundcolor yellow
	$web.CustomMasterUrl = $masterUrl

    $web.Update()
    $clientContext.ExecuteQuery()

}
