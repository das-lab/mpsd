param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://cdn02.foxitsoftware.com/pub/foxit/reader/desktop/win/7.x/7.0/en_us/FoxitReader703.0916_prom_enu_Setup.exe"
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
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/VERYSILENT /NORESTART" -Wait
                }
                		
                
                
                

				
                
                
                
                

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
            
            $Executable = "C:\Program Files (x86)\Foxit Software\Foxit Reader\unins000.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/VERYSILENT /NORESTART" -Wait}
                            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}