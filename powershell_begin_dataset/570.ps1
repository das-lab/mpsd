

function Copy-SPOFile
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[System.IO.FileSystemInfo]$file, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string]$targetPath, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[bool]$checkoutNecessary
	)

    if ($file.PsIsContainer)
    {
        Add-SPOFolder $targetPath
    }
    else
    {
        $filePath = $file.FullName
        
		Write-Host "Copying file $filePath to $targetPath" -foregroundcolor black -backgroundcolor yellow
		
        
        if ($checkoutNecessary)
        {
            
            $ErrorActionPreference = "SilentlyContinue"
            Submit-SPOCheckOut $targetPath
            $ErrorActionPreference = "Stop"
        }
        
		$arrExtensions = ".html", ".js", ".master", ".txt", ".css", ".aspx"
		
		if ($arrExtensions -contains $file.Extension)
		{
			$tempFile = Convert-SPOFileVariablesToValues -file $file
	        Save-SPOFile $targetPath $tempFile
		} 
		else
		{
			Save-SPOFile $targetPath $file
		}
        
        if ($checkoutNecessary)
        {
            Submit-SPOCheckOut $targetPath
            Submit-SPOCheckIn $targetPath
        }
    }
}
