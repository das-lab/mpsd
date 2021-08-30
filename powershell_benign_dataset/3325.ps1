
function Disable-ScheduledCommand {
    
    [PoshBot.BotCommand(
        Aliases = 'disableschedule',
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    if ($Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage = $Bot.Scheduler.DisableSchedule($Id)
        $fields = @(
            'Id'
            @{l='Command'; e = {$_.Message.Text}}
            @{l='Interval'; e = {$_.TimeInterval}}
            @{l='Value'; e = {$_.TimeValue}}
            'TimesExecuted'
            @{l='StartAfter';e={_.StartAfter.ToString('s')}}
            'Enabled'
        )
        $msg =  "Schedule for command [$($scheduledMessage.Message.Text)] disabled`n"
        $msg += ($scheduledMessage | Select-Object -Property $fields | Format-List | Out-String).Trim()
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
