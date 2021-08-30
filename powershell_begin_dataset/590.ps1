

function Get-TrueCryptContainer{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$false)]
		[String]
		$Name,       

        [Switch]
		$Mounted
	)
  
    
    
    
    
    $MountedContainers = Get-PPConfiguration $PSconfigs.TrueCryptContainer.DataFile | %{$_.Content.MountedContainer}
    
    Get-PPConfiguration $PSconfigs.TrueCryptContainer.Filter | %{$_.Content.TrueCryptContainer} | %{
    
        $(if(-not $Name){        
            
            $_ | select Key, Name, @{L="Path";E={Get-Path $_.Path}}, FavoriteDriveLetter
            
        }elseif($Name){
        
            $_ | where{$_.Name -like $Name -or $_.Key -like $Name} | select Key, Name, @{L="Path";E={Get-Path $_.Path}}, FavoriteDriveLetter
        
        }) | %{
        
        
            if($Mounted){
            
                $TrueCryptContainer = $_
            
                $MountedContainer = $MountedContainers | where{$_.Name -eq $TrueCryptContainer.Name}
                
                if($MountedContainer){$_ | select Key, Name, Path, FavoriteDriveLetter, @{L="Drive";E={$MountedContainer.Drive}}}
                
            }else{
            
                $_
            } 
        }    
    }
}