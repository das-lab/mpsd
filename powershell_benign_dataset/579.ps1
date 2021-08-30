

function Submit-SPOCheckOut
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
    
    if ($remotefile.CheckOutType -eq [Microsoft.SharePoint.Client.CheckOutType]::None)
    {
        $remotefile.CheckOut()
    }
    $clientContext.ExecuteQuery()
}
