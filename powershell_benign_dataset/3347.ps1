
function New-ScheduledCommand {
    
    [PoshBot.BotCommand(
        Aliases = ('newschedule', 'new-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding(DefaultParameterSetName = 'repeat')]
    param(
        [parameter(Mandatory, ParameterSetName = 'repeat')]
        [parameter(Mandatory, ParameterSetName = 'once')]
        $Bot,

        [parameter(Mandatory, Position = 0, ParameterSetName = 'repeat')]
        [parameter(Mandatory, Position = 0, ParameterSetName = 'once')]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [parameter(Mandatory, Position = 1, ParameterSetName = 'repeat')]
        [ValidateNotNull()]
        [int]$Value,

        [parameter(Mandatory, Position = 2, ParameterSetName = 'repeat')]
        [ValidateSet('days', 'hours', 'minutes', 'seconds')]
        [ValidateNotNullOrEmpty()]
        [string]$Interval,

        [parameter(ParameterSetName = 'repeat')]
        [parameter(Mandatory, ParameterSetName = 'once')]
        [ValidateScript({
            if ($_ -as [datetime]) {
                return $true
            } else {
                throw '''StartAfter'' must be a datetime.'
            }
        })]
        [string]$StartAfter,

        [parameter(Mandatory, ParameterSetName = 'once')]
        [switch]$Once
    )

    if (-not $Command.StartsWith($Bot.Configuration.CommandPrefix)) {
        $Command = $Command.Insert(0, $Bot.Configuration.CommandPrefix)
    }

    $botMsg = [Message]::new()
    $botMsg.Text = $Command
    $botMsg.From = $global:PoshBotContext.From
    $botMsg.To = $global:PoshBotContext.To

    if ($PSCmdlet.ParameterSetName -eq 'repeat') {
        
        if ($PSBoundParameters.ContainsKey('StartAfter')) {
            $schedMsg = [ScheduledMessage]::new($Interval, $value, $botMsg, [datetime]$StartAfter)
        } else {
            $schedMsg = [ScheduledMessage]::new($Interval, $value, $botMsg)
        }
    } elseIf ($PSCmdlet.ParameterSetName -eq 'once') {
        
        $schedMsg = [ScheduledMessage]::new($botMsg, [datetime]$StartAfter)
    }

    try {
        $Bot.Scheduler.ScheduleMessage($schedMsg)

        if ($PSCmdlet.ParameterSetName -eq 'repeat') {
            New-PoshBotCardResponse -Type Normal -Text "Command [$Command] with ID [$($schedMsg.Id)] scheduled at interval [$Value $($Interval.ToLower())]." -ThumbnailUrl $thumb.success
        } elseIf ($PSCmdlet.ParameterSetName -eq 'once') {
            New-PoshBotCardResponse -Type Normal -Text "Command [$Command] with ID [$($schedMsg.Id)] scheduled for one time at [$([datetime]$StartAfter)]." -ThumbnailUrl $thumb.success
        }
    } catch {
        New-PoshBotCardResponse -Type Error -Text $_.ToString() -ThumbnailUrl $thumb.error
    }
}
