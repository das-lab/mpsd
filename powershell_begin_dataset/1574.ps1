function Get-MrLeapYear {


    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateRange(1582,9999)]
        [int[]]$Year = (Get-Date).Year
    )

    PROCESS {
        foreach ($y in $Year) {
            if ($y / 400 -is [int]) {
                Write-Output "$y is a leap year"
            }
            elseif ($y / 100 -is [int]) {
                Write-Output "$y is not a leap year"
            }
            elseif ($y / 4 -is [int]) {
                Write-Output "$y is a leap year"
            }
            else {
                Write-Output "$y is not a leap year"
            }
        }
    }
}