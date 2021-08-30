
class Bot : BaseLogger {

    
    [string]$Name

    
    [Backend]$Backend

    hidden [string]$_PoshBotDir

    [StorageProvider]$Storage

    [PluginManager]$PluginManager

    [RoleManager]$RoleManager

    [CommandExecutor]$Executor

    [Scheduler]$Scheduler

    
    [System.Collections.Queue]$MessageQueue = (New-Object System.Collections.Queue)

    [hashtable]$DeferredCommandExecutionContexts = @{}

    [System.Collections.Queue]$ProcessedDeferredContextQueue = (New-Object System.Collections.Queue)

    [BotConfiguration]$Configuration

    hidden [System.Diagnostics.Stopwatch]$_Stopwatch

    hidden [System.Collections.Arraylist] $_PossibleCommandPrefixes = (New-Object System.Collections.ArrayList)

    hidden [MiddlewareConfiguration] $_Middleware

    hidden [bool]$LazyLoadComplete = $false

    Bot([Backend]$Backend, [string]$PoshBotDir, [BotConfiguration]$Config)
        : base($Config.LogDirectory, $Config.LogLevel, $Config.MaxLogSizeMB, $Config.MaxLogsToKeep) {

        $this.Name = $config.Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new($Config.ConfigurationDirectory, $this.Logger)
        $this.Initialize($Config)
    }

    Bot([string]$Name, [Backend]$Backend, [string]$PoshBotDir, [string]$ConfigPath)
        : base($Config.LogDirectory, $Config.LogLevel, $Config.MaxLogSizeMB, $Config.MaxLogsToKeep) {

        $this.Name = $Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new((Split-Path -Path $ConfigPath -Parent), $this.Logger)
        $config = Get-PoshBotConfiguration -Path $ConfigPath
        $this.Initialize($config)
    }

    [void]Initialize([BotConfiguration]$Config) {
        $this.LogInfo('Initializing bot')

        
        $this.Backend.Logger = $this.Logger
        $this.Backend.Connection.Logger = $this.Logger

        if ($null -eq $Config) {
            $this.LoadConfiguration()
        } else {
            $this.Configuration = $Config
        }
        $this.RoleManager = [RoleManager]::new($this.Backend, $this.Storage, $this.Logger)
        $this.PluginManager = [PluginManager]::new($this.RoleManager, $this.Storage, $this.Logger, $this._PoshBotDir)
        $this.Executor = [CommandExecutor]::new($this.RoleManager, $this.Logger, $this)
        $this.Scheduler = [Scheduler]::new($this.Storage, $this.Logger)
        $this.GenerateCommandPrefixList()

        
        $this._Middleware = $Config.MiddlewareConfiguration

        
        
        
        $script:ConfigurationDirectory = $this.Configuration.ConfigurationDirectory

        
        if (-not [string]::IsNullOrEmpty($this.Configuration.PluginDirectory)) {
            $internalPluginDir = Join-Path -Path $this._PoshBotDir -ChildPath 'Plugins'
            $modulePaths = $env:PSModulePath.Split($script:pathSeperator)
            if ($modulePaths -notcontains $internalPluginDir) {
                $env:PSModulePath = $internalPluginDir + $script:pathSeperator + $env:PSModulePath
            }
            if ($modulePaths -notcontains $this.Configuration.PluginDirectory) {
                $env:PSModulePath = $this.Configuration.PluginDirectory + $script:pathSeperator + $env:PSModulePath
            }
        }

        
        foreach ($repo in $this.Configuration.PluginRepository) {
            if ($r = Get-PSRepository -Name $repo -Verbose:$false -ErrorAction SilentlyContinue) {
                if ($r.InstallationPolicy -ne 'Trusted') {
                    $this.LogVerbose("Setting PowerShell repository [$repo] to [Trusted]")
                    Set-PSRepository -Name $repo -Verbose:$false -InstallationPolicy Trusted
                }
            } else {
                $this.LogVerbose([LogSeverity]::Warning, "PowerShell repository [$repo)] is not defined on the system")
            }
        }

        
        if ($this.Configuration.ModuleManifestsToLoad.Count -gt 0) {
            $this.LogInfo('Loading in plugins from configuration')
            foreach ($manifestPath in $this.Configuration.ModuleManifestsToLoad) {
                if (Test-Path -Path $manifestPath) {
                    $this.PluginManager.InstallPlugin($manifestPath, $false)
                } else {
                    $this.LogInfo([LogSeverity]::Warning, "Could not find manifest at [$manifestPath]")
                }
            }
        }
    }

    [void]LoadConfiguration() {
        $botConfig = $this.Storage.GetConfig($this.Name)
        if ($botConfig) {
            $this.Configuration = $botConfig
        } else {
            $this.Configuration = [BotConfiguration]::new()
            $hash = @{}
            $this.Configuration | Get-Member -MemberType Property | ForEach-Object {
                $hash.Add($_.Name, $this.Configuration.($_.Name))
            }
            $this.Storage.SaveConfig('Bot', $hash)
        }
    }

    
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='*')]
    [void]Start() {
        $this._Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $this.LogInfo('Start your engines')
        $OldFormatEnumerationLimit = $global:FormatEnumerationLimit
        if($this.Configuration.FormatEnumerationLimitOverride -is [int]) {
            $global:FormatEnumerationLimit = $this.Configuration.FormatEnumerationLimitOverride
            $this.LogInfo("Setting global FormatEnumerationLimit to [$($this.Configuration.FormatEnumerationLimitOverride)]")
        }
        try {
            $this.Connect()

            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $this.LogInfo('Beginning message processing loop')
            while ($this.Backend.Connection.Connected) {

                
                $this.ReceiveMessage()

                
                
                $this.ProcessScheduledMessages()

                
                $this.ProcessDeferredContexts()

                
                $this.ProcessMessageQueue()

                
                $this.ProcessCompletedJobs()

                Start-Sleep -Milliseconds 100

                
                if ($sw.Elapsed.TotalSeconds -gt 5) {
                    $this.Backend.Ping()
                    $sw.Reset()
                }
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
        } finally {
            $global:FormatEnumerationLimit = $OldFormatEnumerationLimit
            $this.Disconnect()
        }
    }

    
    [void]Connect() {
        $this.LogVerbose('Connecting to backend chat network')
        $this.Backend.Connect()

        
        
        if (-not $this.Backend.LazyLoadUsers) {
            $this._LoadAdmins()
        }
    }

    
    [void]Disconnect() {
        $this.LogVerbose('Disconnecting from backend chat network')
        $this.Backend.Disconnect()
    }

    
    [void]ReceiveMessage() {
        foreach ($msg in $this.Backend.ReceiveMessage()) {

            
            if (($this.Backend.LazyLoadUsers) -and (-not $this.LazyLoadComplete)) {
                $this._LoadAdmins()
                $this.LazyLoadComplete = $true
            }

            
            if ($msg.IsDM -and $this.Configuration.DisallowDMs) {
                $this.LogInfo('Ignoring message. DMs are disabled.', $msg)
                $this.AddReaction($msg, [ReactionType]::Denied)
                $response = [Response]::new($msg)
                $response.Severity = [Severity]::Warning
                $response.Data = New-PoshBotCardResponse -Type Warning -Text 'Sorry :( PoshBot has been configured to ignore DMs (direct messages). Please contact your bot administrator.'
                $this.SendMessage($response)
                return
            }

            
            
            
            
            if (-not [string]::IsNullOrEmpty($msg.Text)) {
                $msg.Text = [System.Net.WebUtility]::HtmlDecode($msg.Text)
            }

            
            $cmdExecContext = [CommandExecutionContext]::new()
            $cmdExecContext.Started = (Get-Date).ToUniversalTime()
            $cmdExecContext.Message = $msg
            $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PreReceive)

            if ($cmdExecContext) {
                $this.LogDebug('Received bot message from chat network. Adding to message queue.', $cmdExecContext.Message)
                $this.MessageQueue.Enqueue($cmdExecContext.Message)
            }
        }
    }

    
    [void]ProcessScheduledMessages() {
        foreach ($msg in $this.Scheduler.GetTriggeredMessages()) {
            $this.LogDebug('Received scheduled message from scheduler. Adding to message queue.', $msg)

            
            
            $msg.FromName = $this.backend.ResolveFromName($msg)
            $msg.ToName   = $this.backend.ResolveToName($msg)

            $this.MessageQueue.Enqueue($msg)
        }
    }

    [void]ProcessDeferredContexts() {
        $now = (Get-Date).ToUniversalTime()
        $expireMinutes = $this.Configuration.ApprovalConfiguration.ExpireMinutes

        $toRemove = New-Object System.Collections.ArrayList
        foreach ($context in $this.DeferredCommandExecutionContexts.Values) {
            $expireTime = $context.Started.AddMinutes($expireMinutes)
            if ($now -gt $expireTime) {
                $msg = "[$($context.Id)] - [$($context.ParsedCommand.CommandString)] has been pending approval for more than [$expireMinutes] minutes. The command will be cancelled."

                
                $this.RemoveReaction($context.Message, [ReactionType]::ApprovalNeeded)
                $this.AddReaction($context.Message, [ReactionType]::Cancelled)

                
                $this.LogInfo($msg)
                $response = [Response]::new($context.Message)
                $response.Data = New-PoshBotCardResponse -Type Warning -Text $msg
                $this.SendMessage($response)

                $toRemove.Add($context.Id)
            }
        }
        foreach ($id in $toRemove) {
            $this.DeferredCommandExecutionContexts.Remove($id)
        }

        while ($this.ProcessedDeferredContextQueue.Count -ne 0) {
            $cmdExecContext = $this.ProcessedDeferredContextQueue.Dequeue()
            $this.DeferredCommandExecutionContexts.Remove($cmdExecContext.Id)

            if ($cmdExecContext.ApprovalState -eq [ApprovalState]::Approved) {
                $this.LogDebug("Starting execution of context [$($cmdExecContext.Id)]")
                $this.RemoveReaction($cmdExecContext.Message, [ReactionType]::ApprovalNeeded)
                $this.Executor.ExecuteCommand($cmdExecContext)
            } elseif ($cmdExecContext.ApprovalState -eq [ApprovalState]::Denied) {
                $this.LogDebug("Context [$($cmdExecContext.Id)] was denied")
                $this.RemoveReaction($cmdExecContext.Message, [ReactionType]::ApprovalNeeded)
                $this.AddReaction($cmdExecContext.Message, [ReactionType]::Denied)
            }
        }
    }

    
    
     [bool]IsBotCommand([Message]$Message) {
        $firstWord = ($Message.Text -split ' ')[0].Trim()
        foreach ($prefix in $this._PossibleCommandPrefixes ) {
            
            
            if ([char]$null -eq $prefix) {
                $prefix = ''
            } else {
                $prefix = [regex]::Escape($prefix)
            }

            if ($firstWord -match "^$prefix") {
                $this.LogDebug('Message is a bot command')
                return $true
            }
        }
        return $false
    }

    
    [void]ProcessMessageQueue() {
        while ($this.MessageQueue.Count -ne 0) {
            $msg = $this.MessageQueue.Dequeue()
            $this.LogDebug('Dequeued message', $msg)
            $this.HandleMessage($msg)
        }
    }

    
    
    [void]HandleMessage([Message]$Message) {
        
        
        
        
        
        $isBotCommand = $this.IsBotCommand($Message)

        $cmdSearch = $true
        if (-not $isBotCommand) {
            $cmdSearch = $false
            $this.LogDebug('Message is not a bot command. Command triggers WILL NOT be searched.')
        } else {
            
            $Message = $this.TrimPrefix($Message)
        }

        $parsedCommand = [CommandParser]::Parse($Message)
        $this.LogDebug('Parsed bot command', $parsedCommand)

        
        $parsedCommand.CallingUserInfo = $this.Backend.GetUserInfo($parsedCommand.From)

        
        $pluginCmd = $this.PluginManager.MatchCommand($parsedCommand, $cmdSearch)
        if ($pluginCmd) {

            
            $cmdExecContext = [CommandExecutionContext]::new()
            $cmdExecContext.Started = (Get-Date).ToUniversalTime()
            $cmdExecContext.Result = [CommandResult]::New()
            $cmdExecContext.Command = $pluginCmd.Command
            $cmdExecContext.FullyQualifiedCommandName = $pluginCmd.ToString()
            $cmdExecContext.ParsedCommand = $parsedCommand
            $cmdExecContext.Message = $Message

            
            $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PostReceive)

            if ($cmdExecContext) {
                
                if (-not $this.CommandInAllowedChannel($parsedCommand, $pluginCmd)) {
                    $this.LogDebug('Igoring message. Command not approved in channel', $pluginCmd.ToString())
                    $this.AddReaction($Message, [ReactionType]::Denied)
                    $response = [Response]::new($Message)
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text 'Sorry :( PoshBot has been configured to not allow that command in this channel. Please contact your bot administrator.'
                    $this.SendMessage($response)
                    return
                }

                
                
                if ([string]::IsNullOrEmpty($parsedCommand.Plugin)) {
                    $parsedCommand.Plugin = $pluginCmd.Plugin.Name
                }

                
                
                
                if ([TriggerType]::Regex -in $pluginCmd.Command.Triggers.Type) {
                    $parsedCommand.NamedParameters = @{}
                    $parsedCommand.PositionalParameters = @()
                    $regex = [regex]$pluginCmd.Command.Triggers[0].Trigger
                    $parsedCommand.NamedParameters['Arguments'] = $regex.Match($parsedCommand.CommandString).Groups | Select-Object -ExpandProperty Value
                }

                
                
                if ($pluginCmd.Plugin.Name -eq 'Builtin') {
                    $parsedCommand.NamedParameters.Add('Bot', $this)
                }

                
                
                
                $configProvidedParams = $this.GetConfigProvidedParameters($pluginCmd)
                foreach ($cp in $configProvidedParams.GetEnumerator()) {
                    if (-not $parsedCommand.NamedParameters.ContainsKey($cp.Name)) {
                        $this.LogDebug("Inserting configuration provided named parameter", $cp)
                        $parsedCommand.NamedParameters.Add($cp.Name, $cp.Value)
                    }
                }

                
                $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PreExecute)

                if ($cmdExecContext) {
                    $this.Executor.ExecuteCommand($cmdExecContext)
                }
            }
        } else {
            if ($isBotCommand) {
                $msg = "No command found matching [$($Message.Text)]"
                $this.LogInfo([LogSeverity]::Warning, $msg, $parsedCommand)
                
                if (-not $this.Configuration.MuteUnknownCommand) {
                    $response = [Response]::new($Message)
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text $msg
                    $this.SendMessage($response)
                }
            }
        }
    }

    
    [void]ProcessCompletedJobs() {
        $completedJobs = $this.Executor.ReceiveJob()

        $count = $completedJobs.Count
        if ($count -ge 1) {
            $this.LogInfo("Processing [$count] completed jobs")
        }

        foreach ($cmdExecContext in $completedJobs) {
            $this.LogInfo("Processing job execution [$($cmdExecContext.Id)]")

            
            $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PostExecute)

            if ($cmdExecContext) {
                $cmdExecContext.Response = [Response]::new($cmdExecContext.Message)

                if (-not $cmdExecContext.Result.Success) {
                    
                    if (-not $cmdExecContext.Result.Authorized) {
                        $cmdExecContext.Response.Severity = [Severity]::Warning
                        $cmdExecContext.Response.Data = New-PoshBotCardResponse -Type Warning -Text "You do not have authorization to run command [$($cmdExecContext.Command.Name)] :(" -Title 'Command Unauthorized'
                        $this.LogInfo([LogSeverity]::Warning, 'Command unauthorized')
                    } else {
                        $cmdExecContext.Response.Severity = [Severity]::Error
                        if ($cmdExecContext.Result.Errors.Count -gt 0) {
                            $cmdExecContext.Response.Data = $cmdExecContext.Result.Errors | ForEach-Object {
                                if ($_.Exception) {
                                    New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Command Exception'
                                } else {
                                    New-PoshBotCardResponse -Type Error -Text $_ -Title 'Command Exception'
                                }
                            }
                        } else {
                            $cmdExecContext.Response.Data += New-PoshBotCardResponse -Type Error -Text 'Something bad happened :(' -Title 'Command Error'
                            $cmdExecContext.Response.Data += $cmdExecContext.Result.Errors
                        }
                        $this.LogInfo([LogSeverity]::Error, "Errors encountered running command [$($cmdExecContext.FullyQualifiedCommandName)]", $cmdExecContext.Result.Errors)
                    }
                } else {
                    $this.LogVerbose('Command execution result', $cmdExecContext.Result)
                    foreach ($resultOutput in $cmdExecContext.Result.Output) {
                        if ($null -ne $resultOutput) {
                            if ($this._IsCustomResponse($resultOutput)) {
                                $cmdExecContext.Response.Data += $resultOutput
                            } else {
                                
                                
                                
                                if ($this._IsPrimitiveType($resultOutput)) {
                                    $cmdExecContext.Response.Text += $resultOutput.ToString().Trim()
                                } else {
                                    $deserializedProps = 'PSComputerName', 'PSShowComputerName', 'PSSourceJobInstanceId', 'RunspaceId'
                                    $resultText = $resultOutput | Select-Object -Property * -ExcludeProperty $deserializedProps
                                    $cmdExecContext.Response.Text += ($resultText | Format-List -Property * | Out-String).Trim()
                                }
                            }
                        }
                    }
                }

                
                if ($this.Configuration.LogCommandHistory) {
                    $logMsg = [LogMessage]::new("[$($cmdExecContext.FullyQualifiedCommandName)] was executed by [$($cmdExecContext.Message.From)]", $cmdExecContext.Summarize())
                    $cmdHistoryLogPath = Join-Path $this.Configuration.LogDirectory -ChildPath 'CommandHistory.log'
                    $this.Log($logMsg, $cmdHistoryLogPath, $this.Configuration.CommandHistoryMaxLogSizeMB, $this.Configuration.CommandHistoryMaxLogsToKeep)
                }

                
                
                foreach ($rule in $this.Configuration.SendCommandResponseToPrivate) {
                    if ($cmdExecContext.FullyQualifiedCommandName -like $rule) {
                        $this.LogInfo("Deverting response from command [$($cmdExecContext.FullyQualifiedCommandName)] to private channel")
                        $cmdExecContext.Response.To = "@$($this.RoleManager.ResolveUserIdToUserName($cmdExecContext.Message.From))"
                        break
                    }
                }

                
                $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PreResponse)

                
                if ($cmdExecContext) {
                    $this.SendMessage($cmdExecContext.Response)
                }

                
                $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PostResponse)
            }

            $this.LogInfo("Done processing command [$($cmdExecContext.FullyQualifiedCommandName)]")
        }
    }

    
    
    [Message]TrimPrefix([Message]$Message) {
        if (-not [string]::IsNullOrEmpty($Message.Text)) {
            $firstWord = ($Message.Text -split ' ')[0].Trim()
            foreach ($prefix in $this._PossibleCommandPrefixes) {
                $prefixEscaped = [regex]::Escape($prefix)
                if ($firstWord -match "^$prefixEscaped") {
                    $Message.Text = $Message.Text.TrimStart($prefix).Trim()
                }
            }
        }
        return $Message
    }

    
    
    
    [void]GenerateCommandPrefixList() {
        $this._PossibleCommandPrefixes.Add($this.Configuration.CommandPrefix)
        foreach ($alternatePrefix in $this.Configuration.AlternateCommandPrefixes) {
            $this._PossibleCommandPrefixes.Add($alternatePrefix) > $null
            foreach ($seperator in ($this.Configuration.AlternateCommandPrefixSeperators)) {
                $prefixPlusSeperator = "$alternatePrefix$seperator"
                $this._PossibleCommandPrefixes.Add($prefixPlusSeperator) > $null
            }
        }
        $this.LogDebug('Configured command prefixes', $this._PossibleCommandPrefixes)
    }

    
    [void]SendMessage([Response]$Response) {
        $this.LogInfo('Sending response to backend')
        $this.Backend.SendMessage($Response)
    }

    
    [void]AddReaction([Message]$Message, [ReactionType]$ReactionType) {
        if ($this.Configuration.AddCommandReactions) {
            $this.Backend.AddReaction($Message, $ReactionType)
        }
    }

    
    [void]RemoveReaction([Message]$Message, [ReactionType]$ReactionType) {
        if ($this.Configuration.AddCommandReactions) {
            $this.Backend.RemoveReaction($Message, $ReactionType)
        }
    }

    
    [hashtable]GetConfigProvidedParameters([PluginCommand]$PluginCmd) {
        if ($PluginCmd.Command.FunctionInfo) {
            $command = $PluginCmd.Command.FunctionInfo
        } else {
            $command = $PluginCmd.Command.CmdletInfo
        }
        $this.LogDebug("Inspecting command [$($PluginCmd.ToString())] for configuration-provided parameters")
        $configParams = foreach($param in $Command.Parameters.GetEnumerator() | Select-Object -ExpandProperty Value) {
            foreach ($attr in $param.Attributes) {
                if ($attr.GetType().ToString() -eq 'PoshBot.FromConfig') {
                    [ConfigProvidedParameter]::new($attr, $param)
                }
            }
        }

        $configProvidedParams = @{}
        if ($configParams) {
            $configParamNames = $configParams.Parameter | Select-Object -ExpandProperty Name
            $this.LogInfo("Command [$($PluginCmd.ToString())] has configuration provided parameters", $configParamNames)
            $pluginConfig = $this.Configuration.PluginConfiguration[$PluginCmd.Plugin.Name]
            if ($pluginConfig) {
                $this.LogDebug("Inspecting bot configuration for parameter values matching command [$($PluginCmd.ToString())]")
                foreach ($cp in $configParams) {
                    if (-not [string]::IsNullOrEmpty($cp.Metadata.Name)) {
                        $configParamName = $cp.Metadata.Name
                    } else {
                        $configParamName = $cp.Parameter.Name
                    }

                    if ($pluginConfig.ContainsKey($configParamName)) {
                        $configProvidedParams.Add($cp.Parameter.Name, $pluginConfig[$configParamName])
                    }
                }
                if ($configProvidedParams.Count -ge 0) {
                    $this.LogDebug('Configuration supplied parameter values', $configProvidedParams)
                }
            } else {
                
                
                $this.LogDebug([LogSeverity]::Warning, "Command [$($PluginCmd.ToString())] has requested configuration supplied parameters but none where found")
            }
        } else {
            $this.LogDebug("Command [$($PluginCmd.ToString())] has 0 configuration provided parameters")
        }

        return $configProvidedParams
    }

    
    [bool]CommandInAllowedChannel([ParsedCommand]$ParsedCommand, [PluginCommand]$PluginCommand) {

        
        if ($ParsedCommand.OriginalMessage.IsDM) {
            return $true
        }

        $channel = $ParsedCommand.ToName
        $fullyQualifiedCommand = $PluginCommand.ToString()

        
        
        
        foreach ($ChannelRule in $this.Configuration.ChannelRules) {
            if ($channel -like $ChannelRule.Channel) {
                foreach ($includedCommand in $ChannelRule.IncludeCommands) {
                    if ($fullyQualifiedCommand -like $includedCommand) {
                        $this.LogDebug("Matched [$fullyQualifiedCommand] to included command [$includedCommand]")
                        foreach ($excludedCommand in $ChannelRule.ExcludeCommands) {
                            if ($fullyQualifiedCommand -like $excludedCommand) {
                                $this.LogDebug("Matched [$fullyQualifiedCommand] to excluded command [$excludedCommand]")
                                return $false
                            }
                        }

                        return $true
                    }
                }
                return $false
            }
        }

        return $false
    }

    
    hidden [bool]_IsCustomResponse([object]$Response) {
        $isCustom = (($Response.PSObject.TypeNames[0] -eq 'PoshBot.Text.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'PoshBot.Card.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'PoshBot.File.Upload') -or
                     ($Response.PSObject.TypeNames[0] -eq 'Deserialized.PoshBot.Text.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'Deserialized.PoshBot.Card.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'Deserialized.PoshBot.File.Upload'))

        if ($isCustom) {
            $this.LogDebug("Detected custom response [$($Response.PSObject.TypeNames[0])] from command")
        }

        return $isCustom
    }

    
    hidden [bool] _IsPrimitiveType([object]$Item) {
        $primitives = @('Byte', 'SByte', 'Int16', 'Int32', 'Int64', 'UInt16', 'UInt32', 'UInt64',
                        'Decimal', 'Single', 'Double', 'TimeSpan', 'DateTime', 'ProgressRecord',
                        'Char', 'String', 'XmlDocument', 'SecureString', 'Boolean', 'Guid', 'Uri', 'Version'
        )
        return ($Item.GetType().Name -in $primitives)
    }

    hidden [CommandExecutionContext] _ExecuteMiddleware([CommandExecutionContext]$Context, [MiddlewareType]$Type) {

        $hooks = $this._Middleware."$($Type.ToString())Hooks"

        
        foreach ($hook in $hooks.Values) {
            try {
                $this.LogDebug("Executing [$($Type.ToString())] hook [$($hook.Name)]")
                if ($null -ne $Context) {
                    $Context = $hook.Execute($Context, $this)
                    if ($null -eq $Context) {
                        $this.LogInfo([LogSeverity]::Warning, "[$($Type.ToString())] middleware [$($hook.Name)] dropped message.")
                        break
                    }
                }
            } catch {
                $this.LogInfo([LogSeverity]::Error, "[$($Type.ToString())] middleware [$($hook.Name)] raised an exception. Command context dropped.", [ExceptionFormatter]::Summarize($_))
                return $null
            }
        }

        return $Context
    }

    
    
    hidden [void] _LoadAdmins() {
        foreach ($admin in $this.Configuration.BotAdmins) {
            if ($adminId = $this.RoleManager.ResolveUsernameToId($admin)) {
                try {
                    $this.RoleManager.AddUserToGroup($adminId, 'Admin')
                } catch {
                    $this.LogInfo([LogSeverity]::Warning, "Unable to add [$admin] to [Admin] group", [ExceptionFormatter]::Summarize($_))
                }
            } else {
                $this.LogInfo([LogSeverity]::Warning, "Unable to resolve ID for admin [$admin]")
            }
        }
    }
}
