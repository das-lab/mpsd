

function Get-SPWebs{



	param(
		[Parameter(Mandatory=$false)]
		$SPWeb
	)
    
    
    
    
    if ((Get-PSSnapin “Microsoft.SharePoint.PowerShell” -ErrorAction SilentlyContinue) -eq $null) {
        Add-PSSnapin “Microsoft.SharePoint.PowerShell”
    }

    
    
    
    
    if($SPWeb){
        
        Get-SPWeb (Get-SPUrl $SPWeb).Url | %{
            $_ ; if($_.webs.Count -ne 0){
                $_.webs | %{
                    Get-SPWebs $_.Url
                }
            }    
        }
    }else{
    
        Get-SPWebApplication | Get-SPSite -Limit All | Get-SPWeb -Limit All
    }
}
