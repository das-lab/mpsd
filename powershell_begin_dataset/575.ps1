

function Set-SPOMasterPage
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$masterFile
	)

    $masterUrl = Join-SPOParts -Separator '/' -Parts $clientContext.Site.ServerRelativeUrl, "/_catalogs/masterpage/$masterFile"

    $web = $clientContext.Web

    
	Write-Host "System master page wordt ingesteld op $sysMasterFile" -foregroundcolor black -backgroundcolor yellow
    $web.MasterUrl = $masterUrl

    $web.Update()
    $clientContext.ExecuteQuery()

}
