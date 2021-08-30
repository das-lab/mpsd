

function Open-SPOSubsite
{
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$relativeUrl
	)

    Open-SPOSite -relativeUrl $relativeUrl
}
