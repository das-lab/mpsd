
function New-PoshBotConfiguration {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [string]$Name = 'PoshBot',
        [string]$ConfigurationDirectory = $script:defaultPoshBotDir,
        [string]$LogDirectory = $script:defaultPoshBotDir,
        [string]$PluginDirectory = $script:defaultPoshBotDir,
        [string[]]$PluginRepository = @('PSGallery'),
        [string[]]$ModuleManifestsToLoad = @(),
        [LogLevel]$LogLevel = [LogLevel]::Verbose,
        [int]$MaxLogSizeMB = 10,
        [int]$MaxLogsToKeep = 5,
        [bool]$LogCommandHistory = $true,
        [int]$CommandHistoryMaxLogSizeMB = 10,
        [int]$CommandHistoryMaxLogsToKeep = 5,
        [hashtable]$BackendConfiguration = @{},
        [hashtable]$PluginConfiguration = @{},
        [string[]]$BotAdmins = @(),
        [char]$CommandPrefix = '!',
        [string[]]$AlternateCommandPrefixes = @('poshbot'),
        [char[]]$AlternateCommandPrefixSeperators = @(':', ',', ';'),
        [string[]]$SendCommandResponseToPrivate = @(),
        [bool]$MuteUnknownCommand = $false,
        [bool]$AddCommandReactions = $true,
        [int]$ApprovalExpireMinutes = 30,
        [switch]$DisallowDMs,
        [int]$FormatEnumerationLimitOverride = -1,
        [hashtable[]]$ApprovalCommandConfigurations = @(),
        [hashtable[]]$ChannelRules = @(),
        [MiddlewareHook[]]$PreReceiveMiddlewareHooks   = @(),
        [MiddlewareHook[]]$PostReceiveMiddlewareHooks  = @(),
        [MiddlewareHook[]]$PreExecuteMiddlewareHooks   = @(),
        [MiddlewareHook[]]$PostExecuteMiddlewareHooks  = @(),
        [MiddlewareHook[]]$PreResponseMiddlewareHooks  = @(),
        [MiddlewareHook[]]$PostResponseMiddlewareHooks = @()
    )

    Write-Verbose -Message 'Creating new PoshBot configuration'
    $config = [BotConfiguration]::new()
    $config.Name = $Name
    $config.ConfigurationDirectory = $ConfigurationDirectory
    $config.AlternateCommandPrefixes = $AlternateCommandPrefixes
    $config.AlternateCommandPrefixSeperators = $AlternateCommandPrefixSeperators
    $config.BotAdmins = $BotAdmins
    $config.CommandPrefix = $CommandPrefix
    $config.LogDirectory = $LogDirectory
    $config.LogLevel = $LogLevel
    $config.MaxLogSizeMB = $MaxLogSizeMB
    $config.MaxLogsToKeep = $MaxLogsToKeep
    $config.LogCommandHistory = $LogCommandHistory
    $config.CommandHistoryMaxLogSizeMB = $CommandHistoryMaxLogSizeMB
    $config.CommandHistoryMaxLogsToKeep = $CommandHistoryMaxLogsToKeep
    $config.BackendConfiguration = $BackendConfiguration
    $config.PluginConfiguration = $PluginConfiguration
    $config.ModuleManifestsToLoad = $ModuleManifestsToLoad
    $config.MuteUnknownCommand = $MuteUnknownCommand
    $config.PluginDirectory = $PluginDirectory
    $config.PluginRepository = $PluginRepository
    $config.SendCommandResponseToPrivate = $SendCommandResponseToPrivate
    $config.AddCommandReactions = $AddCommandReactions
    $config.ApprovalConfiguration.ExpireMinutes = $ApprovalExpireMinutes
    $config.DisallowDMs = ($DisallowDMs -eq $true)
    $config.FormatEnumerationLimitOverride = $FormatEnumerationLimitOverride
    if ($ChannelRules.Count -ge 1) {
        $config.ChannelRules = $null
        foreach ($item in $ChannelRules) {
            $config.ChannelRules += [ChannelRule]::new($item.Channel, $item.IncludeCommands, $item.ExcludeCommands)
        }
    }
    if ($ApprovalCommandConfigurations.Count -ge 1) {
        foreach ($item in $ApprovalCommandConfigurations) {
            $acc = [ApprovalCommandConfiguration]::new()
            $acc.Expression = $item.Expression
            $acc.ApprovalGroups = $item.Groups
            $acc.PeerApproval = $item.PeerApproval
            $config.ApprovalConfiguration.Commands.Add($acc) > $null
        }
    }

    
    foreach ($type in [enum]::GetNames([MiddlewareType])) {
        foreach ($item in $PSBoundParameters["$($type)MiddlewareHooks"]) {
            $config.MiddlewareConfiguration.Add($item, $type)
        }
    }

    $config
}

Export-ModuleMember -Function 'New-PoshBotConfiguration'
