
function Deny-PendingCommand {
    
    [PoshBot.BotCommand(
        Aliases = ('deny', 'denycommand')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Id
    )

    $context = $Bot.DeferredCommandExecutionContexts[$Id]
    if ($context) {

        $callingUserId = $global:PoshBotContext.From
        if (-not $global:PoshBotContext.FromName) {
            $callingUserName = $Bot.RoleManager.ResolveUserIdToUserName($callingUserId)
        } else {
            $callingUserName = $global:PoshBotContext.FromName
        }

        
        $approvalGroups = $Bot.Executor.GetApprovalGroups($context)
        $callingUserGroups = $Bot.RoleManager.GetUserGroups($callingUserId).Name
        if ($null -eq $callingUserGroups) { $callingUserGroups = @() }

        $compareParams = @{
            ReferenceObject = $approvalGroups
            DifferenceObject = $callingUserGroups
            PassThru = $true
            IncludeEqual = $true
            ExcludeDifferent = $true
        }
        $inApprovalGroup = (Compare-Object @compareParams).Count -gt 0

        if ($inApprovalGroup) {
            $context.ApprovalState = 3 
            $context.Approver.Id = $callingUserId
            $context.Approver.Name = $callingUserName
            $Bot.ProcessedDeferredContextQueue.Enqueue($context)
            New-PoshBotCardResponse -Type Normal -Text "Command [$Id] - [$($context.ParsedCommand.CommandString)] denied by [$callingUserName]"
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Sorry. Only someone in approval group(s) [$($approvalGroups -join ', ')] can deny this command."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Unknown approval ID [$Id]"
    }
}
