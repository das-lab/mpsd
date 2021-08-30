

function Copy-SPOFolder
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$folderPath, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$doclib, 
		
		[Parameter(Mandatory=$false, Position=3)]
		[bool]$checkoutNecessary = $false
	)

    
    $files = Get-ChildItem -Path $folderPath -Recurse
    foreach ($file in $files)
    {
        $folder = $file.FullName.Replace($folderPath,'')
        $targetPath = $doclib + $folder
        $targetPath = $targetPath.Replace('\','/')
        Copy-SPOFile $file $targetPath $checkoutNecessary
    }
}
