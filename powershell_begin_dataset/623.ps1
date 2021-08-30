param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi"
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

                
                
                
				
                $_.Downloads | ForEach-Object{
					Start-Process -FilePath "msiexec" -ArgumentList "/i $(Join-Path $_.Path $_.Filename) /quiet /norestart" -Wait
                }
								                		
                
                
                
                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item (Join-Path $_.Path $_.Filename) -Force
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            Get-MSI | where{$_.ProductName -eq "AWS Tools for Windows"} | ForEach-Object{
                 Start-Process -FilePath "msiexec" -ArgumentList "/uninstall $($_.LocalPackage) /qn" -Wait 
            }
                
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}