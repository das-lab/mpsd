

if (Test-Path "$env:SystemRoot\clrver.exe") {
    $counter = 0
    & $env:SystemRoot\clrver.exe -all 2> $null | `
        ConvertFrom-Csv -Delimiter `t -Header "PID","ProcessName","CLR Version" | `
        ForEach-Object {
            if ($counter -gt 1) { 
                $_
            }
            $counter += 1
        }
} else {
    Write-Error "Clrver.exe not found in $env:SystemRoot."
}