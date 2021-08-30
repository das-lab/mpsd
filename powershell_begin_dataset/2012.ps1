

. "$psscriptroot/TestRunner.ps1"
$AssemblyName = "System.Management.Automation"



$excludeList = "CoreMshSnapinResources.resx",
    "ErrorPackageRemoting.resx",
    "EventResource.resx"

Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
