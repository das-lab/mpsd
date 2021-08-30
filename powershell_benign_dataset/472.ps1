

function Get-PPScript{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$false)]
		[String]
		$Name,       
        
        [Switch]
		$Shortcut
	)
  
    
    
    
	    
    
    $ScriptShortcuts = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.ScriptShortcut.DataFile -Recurse | %{[xml](Get-Content $_.Fullname)} | %{$_.Content.ScriptShortcut}
    
    if(-not $Name -and $Shortcut){
    
        $ScriptShortcuts
    
    }elseif($Name -and $Shortcut){
    
        $ScriptShortcuts | where{
            $_.Key -eq $Name -or
            $_.Name -eq $Name -or
            $_.Filename -eq $Name          
        }
    
    }else{
    
        Get-Childitem -Path $PSscripts.Path -Filter * -Recurse | where{(-not $_.PSIsContainer) -and ($PSscripts.Extensions -contains $_.Extension)} | Group-Object Name | where{$_.count -eq 1} | %{
        
            if(-not $Name){
            
                $_.Group
            
            }elseif($Name){
            
                $_ | where{$_.Name -like $Name} | %{$_.Group}
            }    
        }
    }
}