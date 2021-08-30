param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/27.0.1/win32/de/Firefox%20Setup%20Stub%2027.0.1.exe"
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
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -Wait
                }
                		
                
                
                

                $Executable = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe";if(Test-Path $Executable){Set-Content -Path (Join-Path $PSbin.Path "firefox.bat") -Value "@echo off`nstart `"`" `"$Executable`" %*"}
                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            if(Test-Path (Join-Path $PSbin.Path "firefox.bat")){Remove-Item (Join-Path $PSbin.Path "firefox.bat")}
            
            $Executable = "C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/Uninstall /s" -Wait}
            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}