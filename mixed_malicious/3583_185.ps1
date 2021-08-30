
$childWI_ReviewerActivityHasReviewers_Class_id = '6e05d202-38a4-812e-34b8-b11642001a80'
$childWI_ReviewerActivityHasReviewers_Class_obj = Get-SCSMRelationshipClass -id $childWI_ReviewerActivityHasReviewers_Class_id



$childWI_ReviewerisUser_Class_id = '90da7d7c-948b-e16e-f39a-f6e3d1ffc921'
$childWI_ReviewerisUser_Class_obj = Get-SCSMRelationshipClass -id $childWI_ReviewerisUser_Class_id

$childWI_reviewers = Get-SCSMRelatedObject -SMObject $childWI_obj -Relationship $childWI_ReviewerActivityHasReviewers_Class_obj
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

