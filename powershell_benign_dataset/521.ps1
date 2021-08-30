

function Move-SPList{


	
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$ListUrl,
				
		[Parameter(Mandatory=$true)]
		[String]
		$WebUrl,
        
        [Switch]
        $NoFileCompression
	)
	
	
	
	
    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    $Path = (Export-SPList -ListUrl $ListUrl -NoFileCompression:$NoFileCompression)
    Import-SPList -WebUrl $WebUrl -Path $Path -NoFileCompression:$NoFileCompression
    
    Write-Host "Remove item $Path"
    Remove-Item -Path $Path -Force -confirm:$false -Recurse
}