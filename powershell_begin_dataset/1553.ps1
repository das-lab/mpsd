
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