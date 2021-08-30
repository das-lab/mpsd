

function Import-SPList{


	
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$WebUrl,
				
		[Parameter(Mandatory=$true)]
		[String]
		$Path,
        
        [Switch]
        $NoFileCompression
	)
	
	
	
	
    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    $SPUrl = $(Get-SPUrl $WebUrl).Url       

    Write-Host "Import SharePoint list $Path to $SPUrl"    
	Import-SPWeb -Identity $SPUrl -path $Path -IncludeUserSecurity -nologfile -Force -NoFileCompression:$NoFileCompression
}