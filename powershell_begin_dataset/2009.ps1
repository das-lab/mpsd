

. "$psscriptroot/TestRunner.ps1"

$assemblyName = "Microsoft.PowerShell.CoreCLR.Eventing"



$excludeList = @()



Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
