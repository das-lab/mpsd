

function Move-SPWeb{


	
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$SourceUrl,
				
		[Parameter(Mandatory=$true)]
		[String]
		$DestUrl,
        
        [Switch]
        $NoFileCompression
	)
	
	
	
	
    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    $Export = (Export-PPSPWeb -Url $SourceUrl -NoFileCompression:$NoFileCompression)
    $Export
    Import-PPSPWeb -Url $DestUrl -Path $Export.BackupFile -NoFileCompression:$NoFileCompression -Template $Export.Template
    
    Write-Host "Remove item $Path"
    Remove-Item -Path $Export.BackupFile -Force -confirm:$false -Recurse
}