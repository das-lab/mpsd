

. "$psscriptroot/TestRunner.ps1"
$AssemblyName = "Microsoft.PowerShell.Commands.Management"



$excludeList = "EventlogResources.resx",
    "TransactionResources.resx",
    "WebServiceResources.resx",
    "HotFixResources.resx",
    "ControlPanelResources.resx",
    "WmiResources.resx",
    "ManagementMshSnapInResources.resx",
    "ClearRecycleBinResources.resx",
    "ClipboardResources.resx"


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
