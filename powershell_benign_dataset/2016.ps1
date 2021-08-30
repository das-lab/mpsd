

. "$psscriptroot/TestRunner.ps1"

$AssemblyName = "Microsoft.PowerShell.ConsoleHost"



$excludeList = @("HostMshSnapinResources.resx")


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
