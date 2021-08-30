

. "$psscriptroot/TestRunner.ps1"
$AssemblyName = "Microsoft.PowerShell.Commands.Utility"



$excludeList = "CoreMshSnapinResources.resx",
    "ErrorPackageRemoting.resx",
    "FormatAndOut_out_gridview.resx",
    "UtilityMshSnapinResources.resx",
    "OutPrinterDisplayStrings.resx",
    "UpdateListStrings.resx",
    "ConvertFromStringResources.resx",
    "ConvertStringResources.resx",
    "FlashExtractStrings.resx",
    "ImmutableStrings.resx"
import-module Microsoft.Powershell.Utility

Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
