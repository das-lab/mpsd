
function Get-MrLeapYear2 {


    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateRange(1582,9999)]
        [int[]]$Year = (Get-Date).Year
    )

    PROCESS {
        foreach ($y in $Year) {
            try {
                if (Get-Date -Date 2/29/$y) {
                    Write-Output "$y is a leap year"
                }
            }
            catch {
                Write-Output "$y is not a leap year"
            }
        }
    }
}