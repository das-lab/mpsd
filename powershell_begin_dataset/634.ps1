param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
    $Downdgrade,
	[switch]$Uninstall
)





$Configs = @{
	Version = "2.7.6"
	Url = "https://www.python.org/ftp/python/2.7.6/python-2.7.6.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    MSIProductName = "Python 2.7.6"
	PathVariable = "C:\Python27"

},@{
	Version = "3.4.0"
	Url = "https://www.python.org/ftp/python/3.4.0/python-3.4.0.msi"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
    MSIProductName = "Python 3.4.0"
	PathVariable = "C:\Python34"
}

$Configs | where{$_.Version -eq $Version} | ForEach-Object{

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
                		
                
                
                
				
				Set-EnvironmentVariableValue -Name "Path" -Value ";$($_.PathVariable)" -Target "Machine" -Add
				
				
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item (Join-Path $_.Path $_.Filename) -Force
                }
                		
                
                
                
                		
                if($Update){
                    $_.Result = "AppUpdated";$_
                }elseif($Downgrade){
                    $_.Result = "AppDowngraded";$_
                }else{
                    $_.Result = "AppInstalled";$_
                }
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            Get-MSI | where{$_.ProductName -eq $Config.MSIProductName} | ForEach-Object{
                 Start-Process -FilePath "msiexec" -ArgumentList "/uninstall $($_.LocalPackage) /qn /norestart" -Wait 
            }
            
			Remove-EnvironmentVariableValue -Name "Path" -Value ";$($_.PathVariable)" -Target Machine
			
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}