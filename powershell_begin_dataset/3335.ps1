
function Get-CommandStatus {
    
    [PoshBot.BotCommand(
        Aliases = ('getcommandstatus', 'commandstatus')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $activeJobs = @($Bot.Executor._jobTracker.GetEnumerator() | Foreach-Object {
        $userId = $_.Value.ParsedCommand.From
        $userName = $Bot.RoleManager.ResolveUserIdToUserName($_.Value.ParsedCommand.From)
        $cmdDuration = [system.math]::Round(((Get-Date).ToUniversalTime() - $_.Value.Started.ToUniversalTime()).TotalSeconds, 0)
        [pscustomobject]@{
            Id = $_.Value.Id
            From = "$userName [$userId]"
            CommandString = $_.Value.ParsedCommand.CommandString
            Complete = $_.Value.Complete
            Started = $_.Value.Started.ToUniversalTime().ToString('u')
            RunningTime = "$cmdDuration seconds"
        }
    })

    if ($activeJobs.Count -eq 0) {
        New-PoshbotTextResponse -Text 'There are no active jobs'
    } else {
        $msg = ($activeJobs | Format-List -Property * | Out-String)
        New-PoshBotTextResponse -Text $msg -AsCode
    }
}
