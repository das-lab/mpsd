

function Get-SPListItems{



	param(
		[Parameter(Mandatory=$false)]
		$SPweb,

		[Parameter(Mandatory=$false)]
		[string]$FilterListName,
		
		[switch]$OnlyDocumentLibraries,
        
        [switch]$OnlyCheckedOutFiles,
        
		[switch]$Recursive
	)
    
    
    
    
    if ((Get-PSSnapin “Microsoft.SharePoint.PowerShell” -ErrorAction SilentlyContinue) -eq $null) {
        Add-PSSnapin “Microsoft.SharePoint.PowerShell”
    }

    
    
    
    $(if($SPweb){    

        $SPWebUrl = (Get-SPUrl $SPweb).Url
                
        if($Recursive){
                  
            Get-SPLists $SPWebUrl -Recursive -OnlyDocumentLibraries:$OnlyDocumentLibraries -FilterListName $FilterListName
                        
        }else{
        
            Get-SPLists $SPWebUrl -OnlyDocumentLibraries:$OnlyDocumentLibraries -FilterListName $FilterListName
        }
     }else{
    
       Get-SPLists -OnlyDocumentLibraries:$OnlyDocumentLibraries -FilterListName $FilterListName
            
    }) | %{
        
        if($OnlyCheckedOutFiles){
        
            $_.CheckedOutFiles
            
        }else{
        
            $_.Items
        }
    } 
}