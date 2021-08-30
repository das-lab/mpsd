
function userguide
{
    $EqlDocPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "\Doc";
    if (test-path "$EqlDocPath\PowerShellModule_UserGuide.pdf")
    {
        invoke-item $EqlDocPath\PowerShellModule_UserGuide.pdf;
    }
}
Function Get-EqlBanner
{
    write-host "          Welcome to Equallogic Powershell Tools";
    write-host "";
    write-host -no "Full list of cmdlets:";
    write-host -no " ";
    write-host -fore Yellow "            Get-Command";
    write-host -no "Full list of Equallogic cmdlets:";
    write-host -no " ";
    write-host -fore Yellow " Get-EqlCommand";
    write-host -no "Get general help:";
    write-host -no " ";
    write-host -fore Yellow "                Help";
    write-host -no "Cmdlet specific help:";
    write-host -no " ";
    write-host -fore Yellow "            Get-help <cmdlet>";
    write-host -no "Equallogic Powershell User Guide:";
    write-host -no " ";
    write-host -fore Yellow "UserGuide";
    write-host "";
}
Function Get-EqlCommand
{
    get-command -module EqlPsTools;
}
$EqlPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlPSTools.dll";
import-module $EqlPSToolsPath;
$EqlShell = (Get-Host).UI.RawUI;
$EqlShell.BackgroundColor = "DarkBlue";
$EqlShell.ForegroundColor = "white";
Clear-Host;
Get-EqlBanner;

