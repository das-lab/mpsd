

if (Test-Path "$env:SystemRoot\Autorunsc.exe") {
    & $env:SystemRoot\Autorunsc.exe /accepteula -a * -c -h -s '*' 2> $null | ConvertFrom-Csv | ForEach-Object {
        $_
    }
} else {
    Write-Error "Autorunsc.exe not found in $env:SystemRoot."
}
