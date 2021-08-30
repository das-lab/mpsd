


function New-RsScheduleXml
{
    

    [cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact='Low', DefaultParameterSetName='Once')]
    [OutputType(‘System.String’)]
    param
    (
        [Parameter(ParameterSetName='Minute')]
        [Switch]      
        $Minute,
        
        [Parameter(ParameterSetName='Daily')]
        [Switch]      
        $Daily,

        [Parameter(ParameterSetName='Weekly')]
        [Switch]      
        $Weekly,

        [Parameter(ParameterSetName='Monthly')]
        [Switch]      
        $Monthly,

        [Parameter(ParameterSetName='MonthlyDOW')]
        [Switch]      
        $MonthlyDayOfWeek,
        
        [Parameter(ParameterSetName='Once')]
        [Switch]      
        $Once,

        [Parameter(ParameterSetName='Minute',Position=0)]
        [Parameter(ParameterSetName='Daily',Position=0)]
        [Parameter(ParameterSetName='Weekly',Position=0)]
        [Int]
        $Interval = 1,

        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='MonthlyDOW')]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String[]]
        $DaysOfWeek,

        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='MonthlyDOW')]
        [ValidateSet('January','February','March','April','May','June','July','August','September','October','November','December')]
        [String[]]
        $Months,

        [Parameter(ParameterSetName='Monthly',Mandatory=$True)]
        [String]
        $DaysOfMonth,

        [Parameter(ParameterSetName='MonthlyDOW',Mandatory=$True)]
        [ValidateSet('FirstWeek','SecondWeek','ThirdWeek','FourthWeek','LastWeek')]
        [String]
        $WeekOfMonth,

        [ValidateNotNullOrEmpty()]
        [DateTime]
        $Start = (Get-Date),

        [DateTime]
        $End
    )

    Process {
        $StartDateTime = (Get-Date $Start -Format s)

        if ($End) 
        { 
            $EndDateTime = (Get-Date $End -Format s)
        }

        $Schedule = $PSCmdlet.ParameterSetName

        switch ($Schedule) {
            'Minute'     { $ScheduleXML = "<MinutesInterval>$Interval</MinutesInterval>`n" }
            'Daily'      { $ScheduleXML = "<DaysInterval>$Interval</DaysInterval>`n" }
            'Weekly'     { $ScheduleXML = "<WeeksInterval>$Interval</WeeksInterval>`n" }
            'Monthly'    { $ScheduleXML = "<Days>$DaysOfMonth</Days>`n" }
            'MonthlyDOW' { $ScheduleXML = "<WhichWeek>$WeekOfMonth</WhichWeek>`n" }
            default      { $ScheduleXML = $null }
        }
        
        if ($DaysOfWeek) 
        {
            $DaysOfWeekXML = "<DaysOfWeek>`n"
            $DaysOfWeek | ForEach-Object { $DaysOfWeekXML = $DaysOfWeekXML + "<$_>$True</$_>`n" }
            $DaysOfWeekXML = $DaysOfWeekXML + "</DaysOfWeek>`n"
        }
        
        if ($Months) 
        {
            $MonthsOfYearXML = "<MonthsOfYear>`n"
            $Months | ForEach-Object { $MonthsOfYearXML = $MonthsOfYearXML + "<$_>$True</$_>`n" } 
            $MonthsOfYearXML = $MonthsOfYearXML + "</MonthsOfYear>`n"
        }

        $XML =  '<ScheduleDefinition>'
        $XML = $XML + "<StartDateTime>$StartDateTime</StartDateTime>"
        
        if ($EndDateTime)     { $XML = $XML + "<EndDate>$EndDateTime</EndDate>" }
        if ($ScheduleXML)     { $XML = $XML + "<$Schedule`Recurrence>" }
        if ($ScheduleXML)     { $XML = $XML + $ScheduleXML }
        if ($DaysOfWeekXML)   { $XML = $XML + $DaysOfWeekXML }
        if ($MonthsOfYearXML) { $XML = $XML + $MonthsOfYearXML }
        if ($ScheduleXML)     { $XML = $XML + "</$Schedule`Recurrence>" }
        
        $XML = $XML + '</ScheduleDefinition>'

        if ($PSCmdlet.ShouldProcess('Outputting Subscription Schedule XML')) 
        {
            $XML
        }
    }
}