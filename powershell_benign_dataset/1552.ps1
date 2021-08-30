
function Get-MSPSUGMeetingDate {

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$Month = (1..12),

        [Parameter(ValueFromPipeline)]
        [ValidateRange(2013,9999)]
        [Int[]]$Year = (Get-Date).Year
    )
    PROCESS {
        foreach ($y in $Year) {
            foreach ($m in $Month) {
                [datetime]$meetingDate = "$m 1, $y"
                while ($meetingDate.DayOfWeek -ne 'Tuesday') {
                    $meetingDate = $meetingDate.AddDays(1)
                }
                [PSCustomObject]@{
                    'Year' = $y
                    'MeetingDate' = $($meetingDate.AddDays(7).AddHours(20).AddMinutes(30))
                }
            }
        }
    }
}