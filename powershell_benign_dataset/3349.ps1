[cmdletbinding()]
param()

$VerbosePreference = 'Continue'

function Get-FromEnv {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Name,

        [parameter(Mandatory)]
        $Default
    )

    $envValue = Get-ChildItem -Path Env: |
        Where-Object { $_.Name.ToUpper() -eq $Name.ToUpper() } |
        Select-Object -First 1 |
        ForEach-Object {
            $_.Value
        }
    if ($null -eq $envValue) {
        Write-Verbose "$Name = $($Default)"
        $Default
    } else {
        Write-Verbose "$Name = $envValue"
        $envValue
    }
}

if ($IsLinux -or $IsMacOs) {
    $rootDrive = ''
} else {
    $rootDrive = 'c:'
}




$configurationSettings = @{
    Name = @{
        EnvVariable  = 'POSHBOT_NAME'
        DefaultValue = 'PoshBot_Docker'
    }
    ConfigurationDirectory = @{
        EnvVariable  = 'POSHBOT_CONFIG_DIRECTORY'
        DefaultValue = "$rootDrive/poshbot_data"
    }
    LogDirectory = @{
        EnvVariable  = 'POSHBOT_LOG_DIRECTORY'
        DefaultValue = "$rootDrive/poshbot_data/logs"
    }
    PluginDirectory = @{
        EnvVariable  = 'POSHBOT_PLUGIN_DIRECTORY'
        DefaultValue = "$rootDrive/poshbot_data/plugins"
    }
    PluginRepository = @{
        EnvVariable  = 'POSHBOT_PLUGIN_REPOSITORIES'
        DefaultValue = @('PSGallery')
    }
    
    
    
    
    LogLevel = @{
        EnvVariable  = 'POSHBOT_LOG_LEVEL'
        DefaultValue = 'Verbose'
    }
    MaxLogSizeMB = @{
        EnvVariable  = 'POSHBOT_MAX_LOG_SIZE_MB'
        DefaultValue = 10
    }
    MaxLogsToKeep = @{
        EnvVariable  = 'POSHBOT_MAX_LOGS_TO_KEEP'
        DefaultValue = 5
    }
    LogCommandHistory = @{
        EnvVariable  = 'POSHBOT_LOG_CMD_HISTORY'
        DefaultValue = $true
    }
    CommandHistoryMaxLogSizeMB = @{
        EnvVariable  = 'POSHBOT_CMD_HISTORY_MAX_LOG_SIZE_MB'
        DefaultValue = 10
    }
    CommandHistoryMaxLogsToKeep = @{
        EnvVariable  = 'POSHBOT_CMD_HISTORY_MAX_LOGS_TO_KEEP'
        DefaultValue = 5
    }
    BackendConfiguration = @{
        EnvVariable  = 'POSHBOT_BACKEND_CONFIGURATION'
        DefaultValue = @{}
    }
    PluginConfiguration = @{
        EnvVariable  = 'POSHBOT_PLUGIN_CONFIGURATION'
        DefaultValue = @{}
    }
    BotAdmins = @{
        EnvVariable  = 'POSHBOT_ADMINS'
        DefaultValue = @()
    }
    CommandPrefix = @{
        EnvVariable  = 'POSHBOT_CMD_PREFIX'
        DefaultValue = '!'
    }
    AlternateCommandPrefixes = @{
        EnvVariable  = 'POSHBOT_ALT_CMD_PREFIXES'
        DefaultValue = @('poshbot')
    }
    AlternateCommandPrefixSeperators = @{
        EnvVariable  = 'POSHBOT_ALT_CMD_PREFIX_SEP'
        DefaultValue = @(':', ',', ';')
    }
    SendCommandResponseToPrivate = @{
        EnvVariable  = 'POSHBOT_SEND_CMD_RESP_TO_PRIV'
        DefaultValue = @()
    }
    MuteUnknownCommand = @{
        EnvVariable  = 'POSHBOT_MUTE_UNKNOWN_CMD'
        DefaultValue = $false
    }
    AddCommandReactions = @{
        EnvVariable  = 'POSHBOT_ADD_CMD_REACTIONS'
        DefaultValue = $true
    }
    DisallowDMs = @{
        EnvVariable  = 'POSHBOT_DISALLOW_DMS'
        DefaultValue = $false
    }
    FormatEnumerationLimitOverride = @{
        EnvVariable  = 'POSHBOT_FORMAT_ENUMERATION_LIMIT'
        DefaultValue = -1
    }
    BackendType = @{
        EnvVariable  = 'POSHBOT_BACKEND'
        DefaultValue = 'SlackBackend'
    }
}

Import-Module -Name PoshBot -ErrorAction Stop -Verbose:$false




Write-Verbose 'Runtime settings:'
$runTimeSettings = @{}
$configurationSettings.GetEnumerator().ForEach({
    $runTimeSettings.($_.Name) = Get-FromEnv -Name $_.Value.EnvVariable -Default $_.Value.DefaultValue
})



if ($env:POSHBOT_ALT_CMD_PREFIXES)          { $runTimeSettings.AlternateCommandPrefixes         = $runTimeSettings.AlternateCommandPrefixes -split ';' }
if ($env:POSHBOT_PLUGIN_REPOSITORIES)       { $runTimeSettings.PluginRepository                 = $runTimeSettings.PluginRepository         -split ';' }

if ($env:POSHBOT_ALT_CMD_PREFIX_SEP)        { $runTimeSettings.AlternateCommandPrefixSeperators = ($runTimeSettings.AlternateCommandPrefixSeperators -split ';').ToCharArray }

$configPSD1 = Join-Path -Path $runTimeSettings.ConfigurationDirectory -ChildPath 'PoshBot.psd1'
if (-not (Test-Path -Path $configPSD1)) {

    
    $configParams = @{
        Name                             = $runtimeSettings.Name
        ConfigurationDirectory           = $runtimeSettings.ConfigurationDirectory
        LogDirectory                     = $runtimeSettings.LogDirectory
        PluginDirectory                  = $runtimeSettings.PluginDirectory
        PluginRepository                 = $runtimeSettings.PluginRepository
        
        LogLevel                         = $runtimeSettings.LogLevel
        MaxLogSizeMB                     = $runtimeSettings.MaxLogSizeMB
        MaxLogsToKeep                    = $runtimeSettings.MaxLogsToKeep
        LogCommandHistory                = $runtimeSettings.LogCommandHistory
        CommandHistoryMaxLogSizeMB       = $runtimeSettings.CommandHistoryMaxLogSizeMB
        CommandHistoryMaxLogsToKeep      = $runtimeSettings.CommandHistoryMaxLogsToKeep
        BotAdmins                        = $runtimeSettings.BotAdmins
        CommandPrefix                    = $runtimeSettings.CommandPrefix
        AlternateCommandPrefixes         = $runtimeSettings.AlternateCommandPrefixes
        AlternateCommandPrefixSeperators = $runtimeSettings.AlternateCommandPrefixSeperators
        MuteUnknownCommand               = $runTimeSettings.MuteUnknownCommand
    }

    
    switch ($runTimeSettings.BackendType) {
        {$_ -in 'Slack', 'SlackBackend'} {
            
            
            $slackToken = Get-FromEnv -Name 'POSHBOT_SLACK_TOKEN' -Default ''
            if ([string]::IsNullOrEmpty($slackToken) -or $runtimeSettings.BotAdmins.Count -eq 0) {
                throw 'POSHBOT_SLACK_TOKEN and POSHBOT_ADMINS environment variables are required if there is not a preexisting bot configuration to load. Please specify your Slack token and initial list of bot administrators.'
                exit 1
            }
            $configParams.BackendConfiguration = @{
                Token = $slackToken
                Name  = 'SlackBackend'
            }
        }
        {$_ -in 'Teams', 'TeamsBackend'} {
            
            $botName                 = Get-FromEnv -Name 'POSHBOT_TEAMS_BOT_NAME'                   -Default ''
            $teamsId                 = Get-FromEnv -Name 'POSHBOT_TEAMS_ID'                         -Default ''
            $serviceBusNamespace     = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_NAMESPACE'       -Default ''
            $serviceBusQueueName     = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_QUEUE_NAME'      -Default ''
            $serviceBusAccessKeyName = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_ACCESS_KEY_NAME' -Default ''
            $serviceBusAccessKey     = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_ACCESS_KEY'      -Default ''
            $botFrameworkId          = Get-FromEnv -Name 'POSHBOT_BOT_FRAMEWORK_ID'                 -Default ''
            $botFrameworkPassword    = Get-FromEnv -Name 'POSHBOT_BOT_FRAMEWORK_PASSWORD'           -Default ''

            if ($runtimeSettings.BotAdmins.Count -eq 0 -or
                [string]::IsNullOrEmpty($botName) -or
                [string]::IsNullOrEmpty($teamsId) -or
                [string]::IsNullOrEmpty($serviceBusNamespace) -or
                [string]::IsNullOrEmpty($serviceBusQueueName) -or
                [string]::IsNullOrEmpty($serviceBusAccessKeyName) -or
                [string]::IsNullOrEmpty($serviceBusAccessKey) -or
                [string]::IsNullOrEmpty($botFrameworkId) -or
                [string]::IsNullOrEmpty($botFrameworkPassword)) {

                throw 'POSHBOT_SLACK_TOKEN and POSHBOT_ADMINS environment variables are required if there is not a preexisting bot configuration to load. Please specify your Slack token and initial list of bot administrators.'
                exit 1
            }
            $configParams.BackendConfiguration = @{
                Name                = 'TeamsBackend'
                BotName             = $botName
                TeamId              = $teamsId
                ServiceBusNamespace = $serviceBusNamespace
                QueueName           = $serviceBusQueueName
                AccessKeyName       = $serviceBusAccessKeyName
                AccessKey           = $serviceBusAccessKey | ConvertTo-SecureString -AsPlainText -Force
                Credential          = [pscredential]::new(
                    $botFrameworkId,
                    ($botFrameworkPassword | ConvertTo-SecureString -AsPlainText -Force)
                )
            }
        }
        {$_ -in 'Discord', 'DiscordBackend'} {
            
            $token    = Get-FromEnv -Name 'POSHBOT_DISCORD_TOKEN'     -Default ''
            $clientId = Get-FromEnv -Name 'POSHBOT_DISCORD_CLIENT_ID' -Default ''
            $guildId  = Get-FromEnv -Name 'POSHBOT_DISCORD_GUILD_ID'  -Default ''
            if ($runtimeSettings.BotAdmins.Count -eq 0 -or
                [string]::IsNullOrEmpty($token) -or
                [string]::IsNullOrEmpty($clientId) -or
                [string]::IsNullOrEmpty($guildId)) {

                throw 'POSHBOT_DISCORD_TOKEN, POSHBOT_DISCORD_CLIENT_ID, POSHBOT_DISCORD_GUILD_ID, and POSHBOT_ADMINS environment variables are required if there is not a preexisting bot configuration to load. Please specify the required backend configuration and initial list of bot administrators.'
                exit 1
            }
            $configParams.BackendConfiguration = @{
                Name     = 'DiscordBackend'
                Token    = $token
                ClientId = $clientId
                GuildId  = $guildId
            }
        }
    }

    $pbc = New-PoshBotConfiguration @configParams
} else {
    
    
    $pbc = Get-PoshBotConfiguration -Path $configPSD1
    $pbc.Name                             = Get-FromEnv -Name 'POSHBOT_NAME'                     -Default $pbc.Name
    $pbc.ConfigurationDirectory           = Get-FromEnv -Name 'POSHBOT_CONFIG_DIRECTORY'         -Default $pbc.ConfigurationDirectory
    $pbc.CommandPrefix                    = Get-FromEnv -Name 'POSHBOT_CMD_PREFIX'               -Default $pbc.CommandPrefix
    $pbc.PluginRepository                 = Get-FromEnv -Name 'POSHBOT_PLUGIN_REPOSITORIES'      -Default $pbc.PluginRepository
    $pbc.LogDirectory                     = Get-FromEnv -Name 'POSHBOT_LOG_DIR'                  -Default $pbc.LogDirectory
    $pbc.BotAdmins                        = Get-FromEnv -Name 'POSHBOT_ADMINS'                   -Default $pbc.BotAdmins
    $pbc.LogLevel                         = Get-FromEnv -Name 'POSHBOT_LOG_LEVEL'                -Default $pbc.LogLevel
    $pbc.AlternateCommandPrefixes         = Get-FromEnv -Name 'POSHBOT_ALT_CMD_PREFIXES'         -Default $pbc.AlternateCommandPrefixes
    $pbc.PluginDirectory                  = Get-FromEnv -Name 'POSHBOT_PLUGIN_DIR'               -Default $pbc.PluginDirectory
    $pbc.MuteUnknownCommand               = Get-FromEnv -Name 'POSHBOT_MUTE_UNKNOWN_CMD'         -Default $pbc.MuteUnknownCommand
    
    $pbc.AlternateCommandPrefixSeperators = Get-FromEnv -Name 'POSHBOT_ALT_CMD_PREFIX_SEP'       -Default $pbc.AlternateCommandPrefixSeperators
    $pbc.SendCommandResponseToPrivate     = Get-FromEnv -Name 'POSHBOT_SEND_CMD_RESP_TO_PRIV'    -Default $pbc.SendCommandResponseToPrivate

    $slackToken = Get-FromEnv -Name 'POSHBOT_SLACK_TOKEN' -Default ''
    if (-not [string]::IsNullOrEmpty($slackToken)) {
        $pbc.BackendConfiguration = @{
            Token = $slackToken
            Name  = 'SlackBackend'
        }
    }
}


switch ($runTimeSettings.BackendType) {
    {$_ -in @('Slack', 'SlackBackend')} {
        $backEndCommand = Get-Command New-PoshBotSlackBackend
    }
    {$_ -in @('Teams', 'TeamsBackend')} {
        $backendCommand = Get-Command New-PoshBotTeamsBackend
    }
    {$_ -in @('Discord', 'DiscordBackend')} {
        $backEndCommand = Get-Command New-PoshBotDiscordBackend
    }
    default {
        throw "Unable to determine backend type. Name property in BackendConfiguration should be one of the following: 'Slack', 'SlackBackend', 'Teams', 'TeamsBackend', 'Discord', 'DiscordBackend'"
        exit 1
    }
}
$backend = & $backendCommand -Configuration $pbc.BackendConfiguration


$bot = New-PoshBotInstance -Configuration $pbc -Backend $backend
$bot.Start()
