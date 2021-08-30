

function Get-SPLists{



	param(
		[Parameter(Mandatory=$false)]
		$SPWeb,
        
        [Parameter(Mandatory=$false)]
		[string]$FilterListName,
		
		[switch]$OnlyDocumentLibraries,

		[switch]$Recursive
	)
    
    
    
    
    if ((Get-PSSnapin “Microsoft.SharePoint.PowerShell” -ErrorAction SilentlyContinue) -eq $null) {
        Add-PSSnapin “Microsoft.SharePoint.PowerShell”
    }

    
    
    
        
    $(if($SPWeb){
    
        $SPWebUrl = (Get-SPUrl $SPWeb).Url
                
        if($Recursive){
               
            Get-SPWebs -Url $SPWebUrl 
                                   
        }else{
               
            Get-SPWeb -Identity $SPWebUrl
        }      
     }else{
     
        Get-SPWebs  
             
    }) | %{
    
        $_.lists | %{
            
            $(if($FilterListName){
            
                $_ | where{$_.Title -eq $FilterListName}
                
            }else{
            
                $_
            
            }) | %{
                      
                $(if($OnlyDocumentLibraries){
                
                    $_ | where {$_.BaseType -eq "DocumentLibrary"}
                    
                }else{
                
                    $_
                })
            }
        }
    }
}