
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
    if (test-path "$EqlPSToolsPath")
    {
        write-host -no "Full list of Equallogic cmdlets:";
        write-host -no " ";
        write-host -fore Yellow " Get-EqlCommand";
    }
    if (test-path "$EqlASMPSToolsPath")
    {
        write-host -no "Full list of ASM cmdlets:";
        write-host -no " ";
        write-host -fore Yellow "        Get-ASMCommand";
    }
    if (test-path "$EqlPSArrayPSToolsPath")
    {
        write-host -no "Full list of PS Array cmdlets:";
        write-host -no " ";
        write-host -fore Yellow "   Get-PSArrayCommand";
    }
    if (test-path "$EqlMpioPSToolsPath")
    {
        write-host -no "Full list of MPIO cmdlets:";
        write-host -no " ";
        write-host -fore Yellow "       Get-MPIOCommand";
    }
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
Function Get-ASMCommand
{
    get-command -module EqlASMPsTools;
}
Function Get-PSArrayCommand
{
    get-command -module EqlPSArrayPSTools;
}
Function Get-MPIOCommand
{
    get-command -module EqlMPIOPSTools;
}
$EqlPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlPSTools.dll";
if (test-path "$EqlPSToolsPath")
{
    import-module $EqlPSToolsPath;
}
$EqlASMPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlASMPSTools.dll";
if (test-path "$EqlASMPSToolsPath")
{
    import-module $EqlASMPSToolsPath;
}
$EqlPSArrayPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlPSArrayPSTools.dll";
if (test-path "$EqlPSArrayPSToolsPath")
{
    import-module $EqlPSArrayPSToolsPath;
}
$EqlMpioPSToolsPath = (Get-ItemProperty -path "HKLM:\SOFTWARE\EqualLogic").installpath + "bin\EqlMpioPSTools.dll";
if (test-path "$EqlMpioPSToolsPath")
{
    import-module $EqlMpioPSToolsPath;
}
$EqlShell = (Get-Host).UI.RawUI;
$EqlShell.BackgroundColor = "DarkBlue";
$EqlShell.ForegroundColor = "white";
Clear-Host;
Get-EqlBanner;

