

function Add-SPOWebpart
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$pageUrl,
		
		[Parameter(Mandatory=$true, Position=2)]
	    [string]$zone,
		
		[Parameter(Mandatory=$true, Position=3)]
	    [int]$order,
		
		[Parameter(Mandatory=$true, Position=4)]
	    [string]$webPartXml
	)
    
    Submit-SPOCheckOut $pageUrl

	$targetPath = Join-SPOParts -Separator '/' -Parts $clientContext.Web.ServerRelativeUrl, $pageUrl
	$page = $clientContext.Web.GetFileByServerRelativeUrl($targetPath)
    $webPartManager = $page.GetLimitedWebPartManager([Microsoft.SharePoint.Client.WebParts.PersonalizationScope]::Shared)
    $replacedWebPartXml = Convert-SPOStringVariablesToValues -string $webPartXml
	$wpd = $webPartManager.ImportWebPart($replacedWebPartXml)
    $webPart = $webPartManager.AddWebPart($wpd.WebPart, $zone, $order);
    
    $clientContext.ExecuteQuery()

    Submit-SPOCheckIn $pageUrl

	Write-Host "Web part succesfully added to the page $pageUrl" -foregroundcolor black -backgroundcolor green
}
