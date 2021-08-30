
function Install-CScheduledTask
{
    
    [CmdletBinding()]
    [OutputType([Carbon.TaskScheduler.TaskInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,238)]
        [Alias('TaskName')]
        [string]
        
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='Minute')]
        [Parameter(Mandatory=$true,ParameterSetName='Hourly')]
        [Parameter(Mandatory=$true,ParameterSetName='Daily')]
        [Parameter(Mandatory=$true,ParameterSetName='Weekly')]
        [Parameter(Mandatory=$true,ParameterSetName='Monthly')]
        [Parameter(Mandatory=$true,ParameterSetName='Month')]
        [Parameter(Mandatory=$true,ParameterSetName='LastDayOfMonth')]
        [Parameter(Mandatory=$true,ParameterSetName='WeekOfMonth')]
        [Parameter(Mandatory=$true,ParameterSetName='Once')]
        [Parameter(Mandatory=$true,ParameterSetName='OnStart')]
        [Parameter(Mandatory=$true,ParameterSetName='OnLogon')]
        [Parameter(Mandatory=$true,ParameterSetName='OnIdle')]
        [Parameter(Mandatory=$true,ParameterSetName='OnEvent')]
        [ValidateLength(1,262)]
        [string]
        
        $TaskToRun,

        [Parameter(ParameterSetName='Minute',Mandatory=$true)]
        [ValidateRange(1,1439)]
        [int]
        
        $Minute,

        [Parameter(ParameterSetName='Hourly',Mandatory=$true)]
        [ValidateRange(1,23)]
        [int]
        
        $Hourly,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Switch]
        
        $StopAtEnd,

        [Parameter(ParameterSetName='Daily',Mandatory=$true)]
        [ValidateRange(1,365)]
        [int]
        
        $Daily,

        [Parameter(ParameterSetName='Weekly',Mandatory=$true)]
        [ValidateRange(1,52)]
        [int]
        
        $Weekly,

        [Parameter(ParameterSetName='Monthly',Mandatory=$true)]
        [Switch]
        
        $Monthly,

        [Parameter(ParameterSetName='LastDayOfMonth',Mandatory=$true)]
        [Switch]
        
        $LastDayOfMonth,

        [Parameter(ParameterSetName='Month',Mandatory=$true)]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Carbon.TaskScheduler.Month[]]
        
        $Month,

        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month',Mandatory=$true)]
        [ValidateRange(1,31)]
        [int]
        
        $DayOfMonth,

        [Parameter(ParameterSetName='WeekOfMonth',Mandatory=$true)]
        [Carbon.TaskScheduler.WeekOfMonth]
        
        $WeekOfMonth,

        [Parameter(ParameterSetName='WeekOfMonth',Mandatory=$true)]
        [Parameter(ParameterSetName='Weekly')]
        [DayOfWeek[]]
        
        $DayOfWeek,

        [Parameter(ParameterSetName='Once',Mandatory=$true)]
        [Switch]
        
        $Once,

        [Parameter(ParameterSetName='OnStart',Mandatory=$true)]
        [Switch]
        
        $OnStart,

        [Parameter(ParameterSetName='OnLogon',Mandatory=$true)]
        [Switch]
        
        $OnLogon,

        [Parameter(ParameterSetName='OnIdle',Mandatory=$true)]
        [ValidateRange(1,999)]
        [int]
        
        $OnIdle,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [Switch]
        
        $OnEvent,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        
        $EventChannelName,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        
        $EventXPathQuery,

        [Parameter(Mandatory=$true,ParameterSetName='XmlFile')]
        [string]
        
        $TaskXmlFilePath,

        [Parameter(Mandatory=$true,ParameterSetName='Xml')]
        [xml]
        
        $TaskXml,

        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [ValidateRange(1,599940)]
        [int]
        
        $Interval,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [DateTime]
        
        $StartDate,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once',Mandatory=$true)]
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        
        $StartTime,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [TimeSpan]
        
        $Duration,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [DateTime]
        
        $EndDate,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        
        $EndTime,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        
        $Interactive,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        
        $NoPassword,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        
        
        
        $HighestAvailableRunLevel,

        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateScript({ $_ -lt '6.22:40:00'})]
        [timespan]
        
        $Delay,

        [Management.Automation.PSCredential]
        
        $TaskCredential,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateSet('System','LocalService','NetworkService')]
        [string]
        
        $Principal = 'System',

        [Switch]
        
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CScheduledTask -Name $Name) )
    {
        if( $Force )
        {
            Uninstall-CScheduledTask -Name $Name
        }
        else
        {
            Write-Verbose ('Scheduled task ''{0}'' already exists. Use -Force switch to re-create it.' -f $Name)
            return
        }
    }

    $parameters = New-Object 'Collections.ArrayList'

    if( $TaskCredential )
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( $TaskCredential.UserName )
        [void]$parameters.Add( '/RP' )
        [void]$parameters.Add( $TaskCredential.GetNetworkCredential().Password )
        Grant-CPrivilege -Identity $TaskCredential.UserName -Privilege 'SeBatchLogonRight'
    }
    elseif( $PSCmdlet.ParameterSetName -notlike 'Xml*' )
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( (Resolve-CIdentityName -Name $Principal) )
    }

    function ConvertTo-SchtasksCalendarNameList
    {
        param(
            [Parameter(Mandatory=$true)]
            [object[]]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $list = $InputObject | ForEach-Object { $_.ToString().Substring(0,3).ToUpperInvariant() }
        return $list -join ','
    }

    $scheduleType = $PSCmdlet.ParameterSetName.ToUpperInvariant()
    $modifier = $null
    switch -Wildcard ( $PSCmdlet.ParameterSetName )
    {
        'Minute'
        {
            $modifier = $Minute
        }
        'Hourly'
        {
            $modifier = $Hourly
        }
        'Daily'
        {
            $modifier = $Daily
        }
        'Weekly'
        {
            $modifier = $Weekly
            if( $PSBoundParameters.ContainsKey('DayOfWeek') )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $DayOfWeek) )
            }
        }
        'Monthly'
        {
            $modifier = 1
            if( $DayOfMonth )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( ($DayOfMonth -join ',') )
            }
        }
        'Month'
        {
            $scheduleType = 'MONTHLY'
            [void]$parameters.Add( '/M' )
            [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $Month) )
            if( ($Month | Select-Object -Unique | Measure-Object).Count -eq 12 )
            {
                Write-Error ('It looks like you''re trying to schedule a monthly task, since you passed all 12 months as the `Month` parameter. Please use the `-Monthly` switch to schedule a monthly task.')
                return
            }

            if( $DayOfMonth )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( ($DayOfMonth -join ',') )
            }
        }
        'LastDayOfMonth'
        {
            $modifier = 'LASTDAY'
            $scheduleType = 'MONTHLY'
            [void]$parameters.Add( '/M' )
            if( $Month )
            {
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $Month) )
            }
            else
            {
                [void]$parameters.Add( '*' )
            }
        }
        'WeekOfMonth'
        {
            $scheduleType = 'MONTHLY'
            $modifier = $WeekOfMonth
            [void]$parameters.Add( '/D' )
            if( $DayOfWeek.Count -eq 1 -and [Enum]::IsDefined([DayOfWeek],$DayOfWeek[0]) )
            {
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $DayOfWeek[0]) )
            }
            else
            {
                Write-Error ('Tasks that run during a specific week of the month can only occur on a single weekday (received {0} days: {1}). Please pass one weekday with the `-DayOfWeek` parameter.' -f $DayOfWeek.Length,($DayOfWeek -join ','))
                return
            }
        }
        'OnIdle'
        {
            $scheduleType = 'ONIDLE'
            [void]$parameters.Add( '/I' )
            [void]$parameters.Add( $OnIdle )
        }
        'OnEvent'
        {
            $modifier = $EventXPathQuery
        }
        'Xml*'
        {
            if( $PSCmdlet.ParameterSetName -eq 'Xml' )
            {
                $TaskXmlFilePath = 'Carbon+Install-CScheduledTask+{0}.xml' -f [IO.Path]::GetRandomFileName()
                $TaskXmlFilePath = Join-Path -Path $env:TEMP -ChildPath $TaskXmlFilePath
                $TaskXml.Save($TaskXmlFilePath)
            }

            $scheduleType = $null
            $TaskXmlFilePath = Resolve-Path -Path $TaskXmlFilePath
            if( -not $TaskXmlFilePath )
            {
                return
            }

            [void]$parameters.Add( '/XML' )
            [void]$parameters.Add( $TaskXmlFilePath )
        }
    }

    try
    {
        if( $modifier )
        {
            [void]$parameters.Add( '/MO' )
            [void]$parameters.Add( $modifier )
        }

        if( $PSBoundParameters.ContainsKey('TaskToRun') )
        {
            [void]$parameters.Add( '/TR' )
            [void]$parameters.Add( $TaskToRun )
        }

        if( $scheduleType )
        {
            [void]$parameters.Add( '/SC' )
            [void]$parameters.Add( $scheduleType )
        }


        $parameterNameToSchtasksMap = @{
                                            'StartTime' = '/ST';
                                            'Interval' = '/RI';
                                            'EndTime' = '/ET';
                                            'Duration' = '/DU';
                                            'StopAtEnd' = '/K';
                                            'StartDate' = '/SD';
                                            'EndDate' = '/ED';
                                            'EventChannelName' = '/EC';
                                            'Interactive' = '/IT';
                                            'NoPassword' = '/NP';
                                            'Force' = '/F';
                                            'Delay' = '/DELAY';
                                      }

        foreach( $parameterName in $parameterNameToSchtasksMap.Keys )
        {
            if( -not $PSBoundParameters.ContainsKey( $parameterName ) )
            {
                continue
            }

            $schtasksParamName = $parameterNameToSchtasksMap[$parameterName]
            $value = $PSBoundParameters[$parameterName]
            if( $value -is [timespan] )
            {
                if( $parameterName -eq 'Duration' )
                {
                    $totalHours = ($value.Days * 24) + $value.Hours
                    $value = '{0:0000}:{1:00}' -f $totalHours,$value.Minutes
                }
                elseif( $parameterName -eq 'Delay' )
                {
                    $totalMinutes = ($value.Days * 24 * 60) + ($value.Hours * 60) + $value.Minutes
                    $value = '{0:0000}:{1:00}' -f $totalMinutes,$value.Seconds
                }
                else
                {
                    $value = '{0:00}:{1:00}' -f $value.Hours,$value.Minutes
                }
            }
            elseif( $value -is [datetime] )
            {
                $value = $value.ToString('MM/dd/yyyy')
            }

            [void]$parameters.Add( $schtasksParamName )

            if( $value -isnot [switch] )
            {
                [void]$parameters.Add( $value )
            }
        }

        if( $PSBoundParameters.ContainsKey('HighestAvailableRunLevel') -and $HighestAvailableRunLevel )
        {
            [void]$parameters.Add( '/RL' )
            [void]$parameters.Add( 'HIGHEST' )
        }

        $originalEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $paramLogString = $parameters -join ' '
        if( $TaskCredential )
        {
            $paramLogString = $paramLogString -replace ([Text.RegularExpressions.Regex]::Escape($TaskCredential.GetNetworkCredential().Password)),'********'
        }
        Write-Verbose ('/TN {0} {1}' -f $Name,$paramLogString)
        
        
        
        $preErrorCount = $Global:Error.Count
        $output = schtasks /create /TN $Name $parameters 2>&1
        $postErrorCount = $Global:Error.Count
        if( $postErrorCount -gt $preErrorCount )
        {
            $numToDelete = $postErrorCount - $preErrorCount
            for( $idx = 0; $idx -lt $numToDelete; ++$idx )
            {
                $Global:Error.RemoveAt(0)
            }
        }
        $ErrorActionPreference = $originalEap

        $createFailed = $false
        if( $LASTEXITCODE )
        {
            $createFailed = $true
        }

        $output | ForEach-Object { 
            if( $_ -match '\bERROR\b' )
            {
                Write-Error $_
            }
            elseif( $_ -match '\bWARNING\b' )
            {
                Write-Warning ($_ -replace '^WARNING: ','')
            }
            else
            {
                Write-Verbose $_
            }
        }

        if( -not $createFailed )
        {
            Get-CScheduledTask -Name $Name
        }
    }
    finally
    {
        if( $PSCmdlet.ParameterSetName -eq 'Xml' -and (Test-Path -Path $TaskXmlFilePath -PathType Leaf) )
        {
            Remove-Item -Path $TaskXmlFilePath -ErrorAction SilentlyContinue
        }
    }
}
