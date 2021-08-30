

function Add-SPOPictureLibrary
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$listTitle
	)
	
	Add-SPOList -listTitle $listTitle -templateType "PictureLibrary"
}
