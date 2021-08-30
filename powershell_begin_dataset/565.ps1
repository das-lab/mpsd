

function Add-SPODocumentLibrary
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$listTitle
	)
	
    Add-SPOList -listTitle $listTitle -templateType "DocumentLibrary"
}
