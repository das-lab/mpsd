

function Get-SPOSolutionId
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$solutionName
	)
	
	$fileUrl = Join-SPOParts -Separator '/' -Parts $clientContext.Site.ServerRelativeUrl, "/_catalogs/solutions/", $solutionName
	
    $solution = $clientContext.Site.RootWeb.GetFileByServerRelativeUrl($fileUrl)
    $clientContext.Load($solution.ListitemAllFields)
	$clientContext.ExecuteQuery()

    return $solution.ListItemAllFields.Id
}
