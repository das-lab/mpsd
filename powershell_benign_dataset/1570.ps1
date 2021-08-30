
function Get-MrDayLightSavingTime {


    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateRange(2007,9999)]
        [Int[]]$Year = (Get-Date).Year
    )

    PROCESS {
        foreach ($y in $Year) {

            [datetime]$beginDate = "March 1, $y"
    
            while ($beginDate.DayOfWeek -ne 'Sunday') {
                $beginDate = $beginDate.AddDays(1)
            }

            [datetime]$endDate = "November 1, $y"
    
            while ($endDate.DayOfWeek -ne 'Sunday') {
                $endDate = $endDate.AddDays(1)
            }            
            
            [PSCustomObject]@{
                'Year' = $y
                'BeginDate' = $($beginDate.AddDays(7).AddHours(2))
                'EndDate' = $($endDate.AddHours(2))
            }

        }
    }
}