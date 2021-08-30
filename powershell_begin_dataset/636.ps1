param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://switch.dl.sourceforge.net/project/sevenzip/7-Zip/9.20/7z920-x64.msi","http://downloads.sourceforge.net/sevenzip/7za920.zip"
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

                
                
                

                $_.Downloads | where{$_.Filename -eq "7z920-x64.msi"} | ForEach-Object{
                    Start-Process -FilePath "msiexec" -ArgumentList "/i $(Join-Path $_.Path $_.Filename) /quiet /norestart" -Wait
                }
                		
                
                
                

                
                $WorkingPath = (Get-Location).Path
                Set-Location "C:\Program Files\7-Zip\"
                $_.Downloads | where{$_.Filename -eq "7za920.zip"} | ForEach-Object{
                    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "e $(Join-Path $_.Path $_.Filename) -y" -Wait
                }
                Set-EnvironmentVariableValue -Name "Path" -Value ";C:\Program Files\7-Zip\" -Target "Machine" -Add                
                Set-Location $WorkingPath
                      
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{
            
            Get-MSI | where{$_.ProductName -eq "7-Zip 9.20 (x64 edition)"} | ForEach-Object{
				 Start-Process -FilePath "msiexec" -ArgumentList "/uninstall $($_.LocalPackage) /qn" -Wait 
			}
            
            $Folder = "C:\Program Files\7-Zip\"; if(Test-Path $Folder){Remove-Item -Path $Folder -Force -Recurse}
            
            Remove-EnvironmentVariableValue -Name Path -Value ";C:\Program Files\7-Zip\" -Target Machine
            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}