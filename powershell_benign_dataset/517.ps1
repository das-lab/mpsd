

function Get-SPList{



	param(
		[Parameter(Mandatory=$true)]
		[String[]]$Url
	)
    
    
    
    
    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}

    
    
    
    $Url | %{
    
        Get-SPUrl $_ | %{
        
            $ListName = ([Uri]$_.Url).LocalPath -replace ".*/",""
     
            Get-SPWeb $_.WebUrl | %{
            
                $_.Lists | where{$_.Title -eq $ListName}            
            }        
        }    
    }
}