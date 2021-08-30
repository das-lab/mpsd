

. "$psscriptroot/TestRunner.ps1"

$assemblyName = "Microsoft.PowerShell.Security"



$excludeList = @("SecurityMshSnapinResources.resx")

import-module Microsoft.PowerShell.Security


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
