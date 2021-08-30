

function Open-SPOSite
{
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$relativeUrl
	)

	Write-Host "Go to site $relativeUrl" -foregroundcolor black -backgroundcolor yellow
	
    [string]$newSiteUrl = Join-SPOParts -Separator '/' -Parts $rootSiteUrl, $relativeUrl
    
    $newContext = New-Object Microsoft.SharePoint.Client.ClientContext($newSiteUrl)

    $newContext.RequestTimeout = $clientContext.RequestTimeout	
    $newContext.AuthenticationMode = $clientContext.AuthenticationMode
    $newContext.Credentials = $clientContext.Credentials

	Write-Host "Check connection" -foregroundcolor black -backgroundcolor yellow
	$web = $newContext.Web
	$site = $newContext.Site
	$newContext.Load($web)
	$newContext.Load($site)
	$newContext.ExecuteQuery()
	
	Set-Variable -Name "clientContext" -Value $newContext -Scope Global

    Write-Host "Succesfully connected" -foregroundcolor black -backgroundcolor green
}
