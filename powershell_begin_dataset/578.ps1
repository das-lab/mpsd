

function Submit-SPOCheckIn
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$targetPath
	)
	
	$targetPath = Join-SPOParts -Separator '/' -Parts $clientContext.Web.ServerRelativeUrl, $targetPath
	
    $remotefile = $clientContext.Web.GetFileByServerRelativeUrl($targetPath)
    $clientContext.Load($remotefile)
    $clientContext.ExecuteQuery()
    
    $remotefile.CheckIn("",[Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
    
    $clientContext.ExecuteQuery()
}
