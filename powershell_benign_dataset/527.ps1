

function Import-PPSPWeb{



	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$Url,
		
		[Parameter(Mandatory=$true)]
		[String]
		$Path,
                
		[Parameter(Mandatory=$false)]
		[String]
		$Template = "STS
        
        
        [Switch]
        $NoFileCompression
             
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
        
    
    $SPUrl = $(Get-SPUrl $Url).Url
    
    
    $SPWeb = Get-SPWeb -Identity $SPUrl -ErrorAction SilentlyContinue
    
    
    if($SPWeb){
    
        Import-SPWeb $SPWeb -Path $Path -UpdateVersions Overwrite -Force -IncludeUserSecurity -NoFileCompression:$NoFileCompression -NoLogFile -Confirm
    
    
    }else{
                    
        
        New-SPWeb -Url $SPUrl -Template (Get-SPWebTemplate $Template)
                
        
        $SPWeb = Get-SPWeb -Identity $SPUrl       
        
        
        
        $spweb.Lists | %{
            $_.AllowDeletion = $true
            $_.Update() 
            $_.delete()
        }

        Import-SPWeb $SPWeb -Path $Path -UpdateVersions Overwrite -Force -IncludeUserSecurity -NoFileCompression:$NoFileCompression -NoLogFile -Confirm
    }

    Write-Host "Finished" -ForegroundColor Green    
}