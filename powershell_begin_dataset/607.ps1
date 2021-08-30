param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://www.truecrypt.org/download/transient/130a82428b303859fcb6/TrueCrypt%20Setup%207.1a.exe"
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
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/q /s" -Wait
                }
                		
                
                
                

                $Executable = "C:\Program Files\TrueCrypt\TrueCrypt.exe";if(Test-Path $Executable){Set-Content -Path (Join-Path $PSbin.Path "TrueCrypt.bat") -Value "@echo off`nstart `"`" `"$Executable`" %*"}
                                
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item $(Join-Path $_.Path $_.Filename)
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{

            if(Test-Path (Join-Path $PSbin.Path "TrueCrypt.bat")){Remove-Item (Join-Path $PSbin.Path "TrueCrypt.bat")}
            
            $Executable = "C:\Program Files\TrueCrypt\TrueCrypt Setup.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/uninstall /s" -Wait}
            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}