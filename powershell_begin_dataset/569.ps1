

function Add-SPOSolution
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$path
	)
	
	Write-Host "Uploading solution $path" -foregroundcolor black -backgroundcolor yellow
	
	$file = Get-Item -Path $path
	
	$targetPath = Join-SPOParts -Separator '/' -Parts $clientContext.Site.ServerRelativeUrl, "/_catalogs/solutions/", $file.Name
	
    $fs = $file.OpenRead()
    try {
		[Microsoft.SharePoint.Client.File]::SaveBinaryDirect($clientContext, $targetPath, $fs, $true)
		Write-Host "Solution succesfully uploaded" -foregroundcolor black -backgroundcolor green
	}
	catch
	{
		Write-Host "Solution $($file.Name) already exists" -foregroundcolor black -backgroundcolor yellow
	}
    $fs.Close()
	
	
}
