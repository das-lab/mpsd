param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-2.4.9.zip"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
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

                
                
                
			    
                $Directory = "C:\data\db"; if(-not (Test-Path -Path $Directory)){New-Item -Path $Directory -Type directory}
                 
                $WorkingPath = (Get-Location).Path
                Set-Location "C:\Program Files\"
				$_.Downloads | ForEach-Object{
                    & 7za x $(Join-Path $_.Path $_.Filename) -y | Out-Null
                }
                Set-Location $WorkingPath
                
                Rename-Item -Path "C:\Program Files\mongodb-win32-x86_64-2008plus-2.4.9" -NewName "MongoDB" -Force
              		
                
                
                
												
                Set-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\MongoDB\bin\" -Target Machine -Add
                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            Remove-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\MongoDB\bin\" -Target Machine
                     
            $Directory = "C:\data\db\"; if(Test-Path $Directory){Remove-Item -Path $Directory -Force -Recurse}
			$Directory = "C:\Program Files\MongoDB\"; if(Test-Path $Directory){Remove-Item -Path $Directory -Force -Recurse}
			
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}