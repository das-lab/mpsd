param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "https://github.com/msysgit/msysgit/releases/download/Git-1.9.4-preview20140815/Git-1.9.4-preview20140815.exe"
	Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
	ConditionExclusion = "Get-Command `"git`" -ErrorAction SilentlyContinue"
}

$Configs | ForEach-Object{

    try{

        $_.Result = $null
        if(-not $_.Path){$_.Path = $Path}
        $Config = $_

        
        
        

        if(-not $Uninstall){

            
            
            

            if($_.ConditionExclusion){            
                $_.ConditionExclusionResult = $(Invoke-Expression $Config.ConditionExclusion -ErrorAction SilentlyContinue)        
            }    
            if(($_.ConditionExclusionResult -eq $null) -or $Force){
                    	
                
                
                

                $_.Downloads = $_.Url | ForEach-Object{
                    Get-File -Url $_ -Path $Config.Path
                }       			

                
                
                

                $_.Downloads | ForEach-Object{
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/Silent" -Wait
                }
                		
                
                
                

                Set-EnvironmentVariableValue -Name "Path" -Value ";C:\Program Files (x86)\Git\bin" -Target "Machine" -Add
                
                
                
                
                		
                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
				
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{
		
			Remove-EnvironmentVariableValue -Name Path -Value ";C:\Program Files (x86)\Git\bin" -Target Machine
			
			$Executable = "C:\Program Files (x86)\Git\unins000.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/VERYSILENT /NORESTART" -Wait}
            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}