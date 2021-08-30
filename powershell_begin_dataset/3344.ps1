
function Set-ScheduledCommand {
    
    [PoshBot.BotCommand(
        Aliases = ('setschedule', 'set-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Id,

        [parameter(Mandatory, Position = 1)]
        [ValidateNotNull()]
        [int]$Value,

        [parameter(Mandatory, Position = 2)]
        [ValidateSet('days', 'hours', 'minutes', 'seconds')]
        [ValidateNotNullOrEmpty()]
        [string]$Interval,

        [ValidateScript({
            if ($_ -as [datetime]) {
                return $true
            } else {
                throw '''StartAfter'' must be a datetime.'
            }
        })]
        [string]$StartAfter
    )

    if ($scheduledMessage = $Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage.TimeInterval = $Interval
        $scheduledMessage.TimeValue = $Value
        if ($PSBoundParameters.ContainsKey('StartAfter')) {
            $scheduledMessage.StartAfter = [datetime]$StartAfter
        }
        $scheduledMessage = $bot.Scheduler.SetSchedule($scheduledMessage)
        New-PoshBotCardResponse -Type Normal -Text "Schedule for command [$($scheduledMessage.Message.Text)] changed to every [$Value $($Interval.ToLower())]." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
