
function Get-CommandHistory {
    
    [PoshBot.BotCommand(
        Aliases = ('history'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding(DefaultParameterSetName = 'all')]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0, ParameterSetName = 'name')]
        [string]$Name,

        [parameter(Position = 0, ParameterSetName = 'id')]
        [string]$Id,

        [parameter(Position = 0, ParameterSetName = 'all')]
        [parameter(Position = 1, ParameterSetName = 'name')]
        [parameter(Position = 1, ParameterSetName = 'id')]
        [int]$Count = 20
    )

    $shortProps = @(
        @{
            Label = 'Id'
            Expression = { $_.Id }
        }
        @{
            Label = 'Command'
            Expression = { $_.Command.Name }
        }
        @{
            Label = 'Caller'
            Expression = { $Bot.Backend.UserIdToUsername($_.Message.From) }
        }
        @{
            Label = 'Success'
            Expression = { $_.Result.Success }
        }
        @{
            Label = 'Started'
            Expression = { $_.Ended.ToString('u')}
        }
    )

    $longProps = $shortProps + @(
        @{
            Label = 'Duration'
            Expression = { $_.Result.Duration.TotalSeconds }
        }
        @{
            Label = 'CommandString'
            Expression = { $_.ParsedCommand.CommandString }
        }
        @{
            Label = 'Approver'
            Expression = { $_.Approver.Name }
        }
    )

    $allHistory = $Bot.Executor.History | Sort-Object -Property Started -Descending

    
    $Count = $Count - 1

    switch ($PSCmdlet.ParameterSetName) {
        'all' {
            $search = '*'
            $history = $allHistory
        }
        'name' {
            $search = $Name
            $history = @($allHistory | Where-Object {$_.Command.Name -eq $Name})[0..$Count]
        }
        'id' {
            $search = $Id
            $history = @($allHistory | Where-Object {$_.Id -eq $Id})[0..$Count]
        }
    }

    if ($history) {
        if ($history.Count -gt 1) {
            New-PoshBotCardResponse -Type Normal -Text ($history | Select-Object -Property $shortProps | Format-List | Out-String)
        } else {
            New-PoshBotCardResponse -Type Normal -Text ($history | Select-Object -Property $longProps | Format-List | Out-String)
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "History for [$search] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
