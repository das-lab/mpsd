param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://download.tuxfamily.org/notepadplus/6.5.3/npp.6.5.3.Installer.exe"
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
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/S" -Wait
                }
                		
                
                
                

                if(Test-Path "C:\Program Files (x86)\Notepad++\notepad++.exe"){    
                    Set-Content -Path (Join-Path $PSbin.Path "Notepad++.bat") -Value "@echo off`nstart `"`" `"C:\Program Files (x86)\Notepad++\notepad++.exe`" %*"
                }elseif(Test-Path "C:\Program Files\Notepad++\notepad++.exe"){ 
                    Set-Content -Path (Join-Path $PSbin.Path "Notepad++.bat") -Value "@echo off`nstart `"`" `"C:\Program Files\Notepad++\notepad++.exe`" %*"
                }
                                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            if(Test-Path (Join-Path $PSbin.Path "Notepad++.bat")){Remove-Item (Join-Path $PSbin.Path "Notepad++.bat")}
            if(Test-Path "C:\Program Files (x86)\Notepad++\uninstall.exe"){
                Start-Process -FilePath "C:\Program Files (x86)\Notepad++\uninstall.exe" -ArgumentList "/S" -Wait
            }elseif(Test-Path "C:\Program Files\Notepad++\uninstall.exe"){
                Start-Process -FilePath "C:\Program Files\Notepad++\uninstall.exe" -ArgumentList "/S" -Wait
            }
            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}