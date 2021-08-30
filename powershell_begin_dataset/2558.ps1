


$Script:Version      = '1.0.9.1126' 
$Script:LogSeparator = '*******************************************************************************' 
$Script:LogFile      = "" 
 



function Get-ScriptName(){ 








    $tmp = $MyInvocation.ScriptName.Substring($MyInvocation.ScriptName.LastIndexOf('\') + 1) 
    $tmp.Substring(0,$tmp.Length - 4) 
} 
 
function Write-Log($Msg, [System.Boolean]$LogTime=$true){ 











    if($LogTime){ 
        $date = Get-Date -format dd.MM.yyyy 
        $time = Get-Date -format HH:mm:ss 
       Add-Content -Path $LogFile -Value ($date + " " + $time + "   " + $Msg) 
    } 
    else{ 
        Add-Content -Path $LogFile -Value $Msg 
    }
} 
 
function Initialize-LogFile($File, [System.Boolean]$reset=$false){ 












try{ 
        
        if(Test-Path -Path $File){ 
            
            if($reset){ 
                Clear-Content $File -ErrorAction SilentlyContinue 
            } 
        } 
        else{ 
            
            if($File.Substring(1,1) -eq ':'){ 
                
                $driveInfo = [System.IO.DriveInfo]($File) 
                if($driveInfo.IsReady -eq $false){ 
                    Write-Log -Msg ($driveInfo.Name + " not ready.") 
                } 
                 
                
                $Dir = [System.IO.Path]::GetDirectoryName($File) 
                if(([System.IO.Directory]::Exists($Dir)) -eq $false){ 
                    $objDir = [System.IO.Directory]::CreateDirectory($Dir) 
                    Write-Log -Msg ($Dir + " created.") 
                } 
            } 
        } 
        
        Write-Log -LogTime $false -Msg $LogSeparator 
        Write-Log -LogTime $false -Msg (((Get-ScriptName).PadRight($LogSeparator.Length - ("   Version " + $Version).Length," ")) + "   Version " + $Version) 
        Write-Log -LogTime $false -Msg $LogSeparator 
    } 
    catch{ 
        Write-Log -Msg $_ 
    } 
} 
 
function Read-Arguments($Values = $args) { 








    foreach($value in $Values){ 
         
        
        $arrTmp = $value.Split("=") 
         
        switch ($arrTmp[0].ToLower()) { 
            -log { 
                $Script:LogFile = $arrTmp[1] 
            } 
        } 
    } 
} 




if($args.Count -ne 0){ 
    
    Read-Arguments 
    if($LogFile.StartsWith("\\")){ 
        Write-Host "UNC" 
    } 
    elseif($LogFile.Substring(1,1) -eq ":"){ 
        Write-Host "Local" 
    } 
    else{ 
        $LogFile = [System.IO.Path]::Combine((Get-Location), $LogFile) 
    } 
     
    if($LogFile.EndsWith(".log") -eq $false){ 
        $LogFile += ".log" 
    } 
} 
 
if($LogFile -eq ""){ 
    
    $LogFile = [System.IO.Path]::Combine((Get-Location), (Get-ScriptName) + ".log") 
} 
 

Initialize-LogFile -File $LogFile -reset $false 
 
 
 



 
 

Write-Log -LogTime $false -Msg $LogSeparator 
Write-Log -LogTime $false -Msg ''