
function Get-PendingCommand {
    
    [PoshBot.BotCommand(
        Aliases = ('pending', 'pendingcommands')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $contexts = $Bot.DeferredCommandExecutionContexts.Values

    if ($contexts.Count -gt 0) {
        $expireMinutes = $Bot.Configuration.ApprovalConfiguration.ExpireMinutes

        $props = @(
            @{
                l = 'Approval ID'
                e = {$_.Id}
            }
            @{
                l = 'Command'
                e = {$_.ParsedCommand.CommandString}
            }
            @{
                l = 'Calling User'
                e = {$Bot.RoleManager.ResolveUserIdToUserName($_.Message.From)}
            }
            @{
                l = 'Approval Group(s)'
                e = {$Bot.Executor.GetApprovalGroups($_) -join ', '}
            }
            @{
                l = 'Submitted'
                e = {$_.Started.ToString('u')}
            }
            @{
                l = 'Expires'
                e = {$_.Started.AddMinutes($expireMinutes).ToString('u')}
            }
        )

        $msg = $contexts | Select-Object -Property $props | Format-List | Out-String
        New-PoshBotCardResponse -Type Normal -Text $msg
    } else {
        Write-Output 'There are no pending approvals'
    }
}
