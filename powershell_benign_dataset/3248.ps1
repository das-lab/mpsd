
class PluginManager : BaseLogger {

    [hashtable]$Plugins = @{}
    [hashtable]$Commands = @{}
    hidden [string]$_PoshBotModuleDir
    [RoleManager]$RoleManager
    [StorageProvider]$_Storage

    PluginManager([RoleManager]$RoleManager, [StorageProvider]$Storage, [Logger]$Logger, [string]$PoshBotModuleDir) {
        $this.RoleManager = $RoleManager
        $this._Storage = $Storage
        $this.Logger = $Logger
        $this._PoshBotModuleDir = $PoshBotModuleDir
        $this.Initialize()
    }

    
    [void]Initialize() {
        $this.LogInfo('Initializing')
        $this.LoadState()
        $this.LoadBuiltinPlugins()
    }

    
    [void]LoadState() {
        $this.LogVerbose('Loading plugin state from storage')

        $pluginsToLoad = $this._Storage.GetConfig('plugins')
        if ($pluginsToLoad) {
            foreach ($pluginKey in $pluginsToLoad.Keys) {
                $pluginToLoad = $pluginsToLoad[$pluginKey]

                $pluginVersions = $pluginToLoad.Keys
                foreach ($pluginVersionKey in $pluginVersions) {
                    $pv = $pluginToLoad[$pluginVersionKey]
                    $manifestPath = $pv.ManifestPath
                    $adhocPermissions = $pv.AdhocPermissions
                    $this.CreatePluginFromModuleManifest($pluginKey, $manifestPath, $true, $false)

                    if ($newPlugin = $this.Plugins[$pluginKey]) {
                        
                        foreach ($version in $newPlugin.Keys) {
                            $npv = $newPlugin[$version]
                            foreach($permission in $adhocPermissions) {
                                if ($p = $this.RoleManager.GetPermission($permission)) {
                                    $npv.AddPermission($p)
                                }
                            }

                            
                            $commandPermissions = $pv.CommandPermissions
                            foreach ($commandName in $commandPermissions.Keys ) {
                                $permissions = $commandPermissions[$commandName]
                                foreach ($permission in $permissions) {
                                    if ($p = $this.RoleManager.GetPermission($permission)) {
                                        $npv.AddPermission($p)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    [void]SaveState() {
        $this.LogVerbose('Saving loaded plugin state to storage')

        
        $pluginsToSave = @{}
        foreach($pluginKey in $this.Plugins.Keys | Where-Object {$_ -ne 'Builtin'}) {
            $versions = @{}
            foreach ($versionKey in $this.Plugins[$pluginKey].Keys) {
                $pv = $this.Plugins[$pluginKey][$versionKey]
                $versions.Add($versionKey, $pv.ToHash())
            }
            $pluginsToSave.Add($pluginKey, $versions)
        }
        $this._Storage.SaveConfig('plugins', $pluginsToSave)
    }

    
    
    
    [void]InstallPlugin([string]$ManifestPath, [bool]$SaveAfterInstall = $false) {
        if (Test-Path -Path $ManifestPath) {
            $moduleName = (Get-Item -Path $ManifestPath).BaseName
            $this.CreatePluginFromModuleManifest($moduleName, $ManifestPath, $true, $SaveAfterInstall)
        } else {
            $msg = "Module manifest path [$manifestPath] not found"
            $this.LogInfo([LogSeverity]::Warning, $msg)
        }
    }

    
    [void]AddPlugin([Plugin]$Plugin, [bool]$SaveAfterInstall = $false) {
        if (-not $this.Plugins.ContainsKey($Plugin.Name)) {
            $this.LogInfo("Attaching plugin [$($Plugin.Name)]")

            $pluginVersion = @{
                ($Plugin.Version).ToString() = $Plugin
            }
            $this.Plugins.Add($Plugin.Name, $pluginVersion)

            
            foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                $this.LogVerbose("Adding permission [$($permission.Value.ToString())] to Role Manager")
                $this.RoleManager.AddPermission($permission.Value)
            }
        } else {
            if (-not $this.Plugins[$Plugin.Name].ContainsKey($Plugin.Version)) {
                
                $this.LogInfo("Attaching version [$($Plugin.Version)] of plugin [$($Plugin.Name)]")
                $this.Plugins[$Plugin.Name].Add($Plugin.Version.ToString(), $Plugin)

                
                foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                    $this.LogVerbose("Adding permission [$($permission.Value.ToString())] to Role Manager")
                    $this.RoleManager.AddPermission($permission.Value)
                }
            } else {
                $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is already loaded"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginException]::New($msg)
            }
        }

        
        $this.LoadCommands()

        if ($SaveAfterInstall) {
            $this.SaveState()
        }
    }

    
    [void]RemovePlugin([Plugin]$Plugin) {
        if ($this.Plugins.ContainsKey($Plugin.Name)) {
            $pluginVersions = $this.Plugins[$Plugin.Name]
            if ($pluginVersions.Keys.Count -eq 1) {
                
                
                foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                    $this.LogVerbose("Removing permission [$($Permission.Value.ToString())]. No longer in use")
                    $this.RoleManager.RemovePermission($Permission.Value)
                }
                $this.LogInfo("Removing plugin [$($Plugin.Name)]")
                $this.Plugins.Remove($Plugin.Name)

                
                $moduleSpec = @{
                    ModuleName = $Plugin.Name
                    ModuleVersion = $pluginVersions
                }
                Remove-Module -FullyQualifiedName $moduleSpec -Verbose:$false -Force
            } else {
                if ($pluginVersions.ContainsKey($Plugin.Version)) {
                    $this.LogInfo("Removing plugin [$($Plugin.Name)] version [$($Plugin.Version)]")
                    $pluginVersions.Remove($Plugin.Version)

                    
                    $moduleSpec = @{
                        ModuleName = $Plugin.Name
                        ModuleVersion = $Plugin.Version
                    }
                    Remove-Module -FullyQualifiedName $moduleSpec -Verbose:$false -Force
                } else {
                    $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw [PluginNotFoundException]::New($msg)
                }
            }
        }

        
        $this.LoadCommands()

        $this.SaveState()
    }

    
    
    [void]RemovePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                if ($p.Keys.Count -eq 1) {
                    
                    
                    foreach ($permission in $pv.Permissions.GetEnumerator()) {
                        $this.LogVerbose("Removing permission [$($Permission.Value.ToString())]. No longer in use")
                        $this.RoleManager.RemovePermission($Permission.Value)
                    }
                    $this.LogInfo("Removing plugin [$($pv.Name)]")
                    $this.Plugins.Remove($pv.Name)
                } else {
                    $this.LogInfo("Removing plugin [$($pv.Name)] version [$Version]")
                    $p.Remove($pv.Version.ToString())
                }

                
                $unloadModuleParams = @{
                    FullyQualifiedName = @{
                        ModuleName    = $PluginName
                        ModuleVersion = $Version
                    }
                    Verbose = $false
                    Force   = $true
                }
                $this.LogDebug("Unloading module [$PluginName] version [$Version]")
                Remove-Module @unloadModuleParams
            } else {
                $msg = "Plugin [$PluginName] version [$Version] is not loaded in bot"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginNotFoundException]::New($msg)
            }
        } else {
            $msg = "Plugin [$PluginName] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New()
        }

        
        $this.LoadCommands()

        $this.SaveState()
    }

    
    [void]ActivatePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                $this.LogInfo("Activating plugin [$PluginName] version [$Version]")
                $pv.Activate()

                
                $this.LoadCommands()
                $this.SaveState()
            } else {
                $msg = "Plugin [$PluginName] version [$Version] is not loaded in bot"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginNotFoundException]::New($msg)
            }
        } else {
            $msg = "Plugin [$PluginName] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New()
        }
    }

    
    [void]ActivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            if ($pv = $p[$Plugin.Version.ToString()]) {
                $this.LogInfo("Activating plugin [$($Plugin.Name)] version [$($Plugin.Version)]")
                $pv.Activate()
            }
        } else {
            $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New($msg)
        }

        
        $this.LoadCommands()

        $this.SaveState()
    }

    
    [void]DeactivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            if ($pv = $p[$Plugin.Version.ToString()]) {
                $this.LogInfo("Deactivating plugin [$($Plugin.Name)] version [$($Plugin.Version)]")
                $pv.Deactivate()
            }
        } else {
            $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New($msg)
        }

        
        $this.LoadCommands()

        $this.SaveState()
    }

    
    [void]DeactivatePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                $this.LogInfo("Deactivating plugin [$PluginName)] version [$Version]")
                $pv.Deactivate()

                
                $this.LoadCommands()
                $this.SaveState()
            } else {
                $msg = "Plugin [$PluginName] version [$Version] is not loaded in bot"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginNotFoundException]::New($msg)
            }
        } else {
            $msg = "Plugin [$PluginName] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New($msg)
        }
    }

    
    [PluginCommand]MatchCommand([ParsedCommand]$ParsedCommand, [bool]$CommandSearch = $true) {

        
        $builtinKey = $this.Plugins['Builtin'].Keys | Select-Object -First 1
        $builtinPlugin = $this.Plugins['Builtin'][$builtinKey]
        foreach ($commandKey in $builtinPlugin.Commands.Keys) {
            $command = $builtinPlugin.Commands[$commandKey]
            if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to builtin command [Builtin:$commandKey]")
                return [PluginCommand]::new($builtinPlugin, $command)
            }
        }

        
        if (($ParsedCommand.Plugin -ne [string]::Empty) -and ($ParsedCommand.Command -ne [string]::Empty)) {
            $plugin = $this.Plugins[$ParsedCommand.Plugin]
            if ($plugin) {
                if ($ParsedCommand.Version) {
                    
                    $pluginVersion = $plugin[$ParsedCommand.Version]
                } else {
                    
                    $latestVersionKey = $plugin.Keys | Sort-Object -Descending | Select-Object -First 1
                    $pluginVersion = $plugin[$latestVersionKey]
                }

                if ($pluginVersion) {
                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command = $pluginVersion.Commands[$commandKey]
                        if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                            $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$($plugin.Name)`:$commandKey]")
                            return [PluginCommand]::new($pluginVersion, $command)
                        }
                    }
                }

                $this.LogInfo([LogSeverity]::Warning, "Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a command in plugin [$($plugin.Name)]")
            } else {
                $this.LogInfo([LogSeverity]::Warning, "Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command")
                return $null
            }
        } else {
            
            foreach ($pluginKey in $this.Plugins.Keys) {
                $plugin = $this.Plugins[$pluginKey]
                $pluginVersion = $null
                if ($ParsedCommand.Version) {
                    
                    $pluginVersion = $plugin[$ParsedCommand.Version]
                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command = $pluginVersion.Commands[$commandKey]
                        if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                            $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]")
                            return [PluginCommand]::new($pluginVersion, $command)
                        }
                    }
                } else {
                    
                    foreach ($pluginVersionKey in $plugin.Keys | Sort-Object -Descending | Select-Object -First 1) {
                        $pluginVersion = $plugin[$pluginVersionKey]
                        foreach ($commandKey in $pluginVersion.Commands.Keys) {
                            $command = $pluginVersion.Commands[$commandKey]
                            if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                                $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]")
                                return [PluginCommand]::new($pluginVersion, $command)
                            }
                        }
                    }
                }
            }
        }

        $this.LogInfo([LogSeverity]::Warning, "Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command")
        return $null
    }

    
    [void]LoadCommands() {
        $allCommands = New-Object System.Collections.ArrayList
        foreach ($pluginKey in $this.Plugins.Keys) {
            $plugin = $this.Plugins[$pluginKey]

            foreach ($pluginVersionKey in $plugin.Keys | Sort-Object -Descending | Select-Object -First 1) {
                $pluginVersion = $plugin[$pluginVersionKey]
                if ($pluginVersion.Enabled) {
                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command =  $pluginVersion.Commands[$commandKey]
                        $fullyQualifiedCommandName = "$pluginKey`:$CommandKey`:$pluginVersionKey"
                        $allCommands.Add($fullyQualifiedCommandName)
                        if (-not $this.Commands.ContainsKey($fullyQualifiedCommandName)) {
                            $this.LogVerbose("Loading command [$fullyQualifiedCommandName]")
                            $this.Commands.Add($fullyQualifiedCommandName, $command)
                        }
                    }
                }
            }
        }

        
        $remove = New-Object System.Collections.ArrayList
        foreach($c in $this.Commands.Keys) {
            if (-not $allCommands.Contains($c)) {
                $remove.Add($c)
            }
        }
        $remove | ForEach-Object {
            $this.LogVerbose("Removing command [$_]. Plugin has either been removed or is deactivated.")
            $this.Commands.Remove($_)
        }
    }

    
    [void]CreatePluginFromModuleManifest([string]$ModuleName, [string]$ManifestPath, [bool]$AsJob = $true, [bool]$SaveAfterCreation = $false) {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction SilentlyContinue
        if ($manifest) {
            $this.LogInfo("Creating new plugin [$ModuleName]")
            $plugin = [Plugin]::new($this.Logger)
            $plugin.Name = $ModuleName
            $plugin._ManifestPath = $ManifestPath
            if ($manifest.ModuleVersion) {
                $plugin.Version = $manifest.ModuleVersion
            } else {
                $plugin.Version = '0.0.0'
            }

            
            $pluginConfig = $this.GetPluginConfig($plugin.Name, $plugin.Version)

            
            $this.GetPermissionsFromModuleManifest($manifest) | ForEach-Object {
                $_.Plugin = $plugin.Name
                $plugin.AddPermission($_)
            }

            
            if ($pluginConfig -and $pluginConfig.AdhocPermissions.Count -gt 0) {
                foreach ($permissionName in $pluginConfig.AdhocPermissions) {
                    if ($p = $this.RoleManager.GetPermission($permissionName)) {
                        $this.LogDebug("Adding adhoc permission [$permissionName] to plugin [$($plugin.Name)]")
                        $plugin.AddPermission($p)
                    } else {
                        $this.LogInfo([LogSeverity]::Warning, "Adhoc permission [$permissionName] not found in Role Manager. Can't attach permission to plugin [$($plugin.Name)]")
                    }
                }
            }

            
            $this.AddPlugin($plugin, $SaveAfterCreation)

            
            
            Import-Module -Name $ManifestPath -Scope Local -Verbose:$false -WarningAction SilentlyContinue -Force
            $moduleCommands = Microsoft.PowerShell.Core\Get-Command -Module $ModuleName -CommandType @('Cmdlet', 'Function') -Verbose:$false
            foreach ($command in $moduleCommands) {

                
                
                
                if ($command.CommandType -eq 'Function') {
                    $metadata = $this.GetCommandMetadata($command)
                } else {
                    $metadata = $null
                }

                $this.LogVerbose("Creating command [$($command.Name)] for new plugin [$($plugin.Name)]")
                $cmd                        = [Command]::new()
                $cmd.Name                   = $command.Name
                $cmd.ModuleQualifiedCommand = "$ModuleName\$($command.Name)"
                $cmd.ManifestPath           = $ManifestPath
                $cmd.Logger                 = $this.Logger
                $cmd.AsJob                  = $AsJob

                if ($command.CommandType -eq 'Function') {
                    $cmd.FunctionInfo = $command
                } elseIf ($command.CommandType -eq 'Cmdlet') {
                    $cmd.CmdletInfo = $command
                }

                
                $triggers = @()

                
                if ($metadata) {

                    
                    if ($metadata.CommandName) {
                        $cmd.Name = $metadata.CommandName
                    }

                    
                    if ($metadata.Aliases) {
                        $metadata.Aliases | Foreach-Object {
                            $cmd.Aliases += $_
                            $triggers += [Trigger]::new([TriggerType]::Command, $_)
                        }
                    }

                    
                    if ($metadata.Permissions) {
                        foreach ($item in $metadata.Permissions) {
                            $fqPermission = "$($plugin.Name):$($item)"
                            if ($p = $plugin.GetPermission($fqPermission)) {
                                $cmd.AddPermission($p)
                            } else {
                                $this.LogInfo([LogSeverity]::Warning, "Permission [$fqPermission] is not defined in the plugin module manifest. Command will not be added to plugin.")
                                continue
                            }
                        }
                    }

                    
                    
                    if ($pluginConfig) {
                        foreach ($permissionName in $pluginConfig.AdhocPermissions) {
                            if ($p = $this.RoleManager.GetPermission($permissionName)) {
                                $this.LogDebug("Adding adhoc permission [$permissionName] to command [$($plugin.Name):$($cmd.name)]")
                                $cmd.AddPermission($p)
                            } else {
                                $this.LogInfo([LogSeverity]::Warning, "Adhoc permission [$permissionName] not found in Role Manager. Can't attach permission to command [$($plugin.Name):$($cmd.name)]")
                            }
                        }
                    }

                    $cmd.KeepHistory = $metadata.KeepHistory    
                    $cmd.HideFromHelp = $metadata.HideFromHelp  

                    
                    if ($metadata.TriggerType) {
                        switch ($metadata.TriggerType) {
                            'Command' {
                                $cmd.TriggerType = [TriggerType]::Command
                                $cmd.Triggers += [Trigger]::new([TriggerType]::Command, $cmd.Name)

                                
                                if ($metadata.Aliases) {
                                    $metadata.Aliases | Foreach-Object {
                                        $cmd.Aliases += $_
                                        $triggers += [Trigger]::new([TriggerType]::Command, $_)
                                    }
                                }
                            }
                            'Event' {
                                $cmd.TriggerType = [TriggerType]::Event
                                $t = [Trigger]::new([TriggerType]::Event, $command.Name)

                                
                                if ($metadata.MessageType) {
                                    $t.MessageType = $metadata.MessageType
                                }
                                if ($metadata.MessageSubtype) {
                                    $t.MessageSubtype = $metadata.MessageSubtype
                                }
                                $triggers += $t
                            }
                            'Regex' {
                                $cmd.TriggerType = [TriggerType]::Regex
                                $t = [Trigger]::new([TriggerType]::Regex, $command.Name)
                                $t.Trigger = $metadata.Regex
                                $triggers += $t
                            }
                        }
                    } else {
                        $triggers += [Trigger]::new([TriggerType]::Command, $cmd.Name)
                    }
                } else {
                    
                    $cmd.Name = $command.Name
                    $triggers += [Trigger]::new([TriggerType]::Command, $cmd.Name)
                }

                
                
                $cmdHelp = Get-Help -Name $cmd.ModuleQualifiedCommand -ErrorAction SilentlyContinue
                if ($cmdHelp) {
                    $cmd.Description = $cmdHelp.Synopsis.Trim()
                }

                
                if ($cmd.TriggerType -eq [TriggerType]::Command) {
                    
                    if ($cmdHelp) {
                        $helpSyntax = ($cmdHelp.syntax | Out-String).Trim() -split "`n" | Where-Object {$_ -ne "`r"}
                        $helpSyntax = $helpSyntax -replace '\[\<CommonParameters\>\]', ''
                        $helpSyntax = $helpSyntax -replace '-Bot \<Object\> ', ''
                        $helpSyntax = $helpSyntax -replace '\[-Bot\] \<Object\> ', '['

                        
                        
                        $helpSyntax = foreach ($item in $helpSyntax) {
                            $item -replace $command.Name, $cmd.Name
                        }
                        $cmd.Usage = $helpSyntax.ToLower().Trim()
                    } else {
                        $this.LogInfo([LogSeverity]::Warning, "Unable to parse help for command [$($command.Name)]")
                        $cmd.Usage = 'ERROR: Unable to parse command help'
                    }
                } elseIf ($cmd.TriggerType -eq [TriggerType]::Regex) {
                    $cmd.Usage = @($triggers | Select-Object -Expand Trigger) -join "`n"
                }

                
                $cmd.Triggers += $triggers

                $plugin.AddCommand($cmd)
            }

            
            if ($pluginConfig -and (-not $pluginConfig.Enabled)) {
                $plugin.Deactivate()
            }

            $this.LoadCommands()

            if ($SaveAfterCreation) {
                $this.SaveState()
            }
        } else {
            $msg = "Unable to load module manifest [$ManifestPath]"
            $this.LogInfo([LogSeverity]::Error, $msg)
            Write-Error -Message $msg
        }
    }

    
    [PoshBot.BotCommand]GetCommandMetadata([System.Management.Automation.FunctionInfo]$Command) {
        $attrs = $Command.ScriptBlock.Attributes
        $botCmdAttr = $attrs | ForEach-Object {
            if ($_.GetType().ToString() -eq 'PoshBot.BotCommand') {
                $_
            }
        }

        if ($botCmdAttr) {
            $this.LogDebug("Command [$($Command.Name)] has metadata defined")
        } else {
            $this.LogDebug("No metadata defined for command [$($Command.Name)]")
        }

        return $botCmdAttr
    }

    
    [Permission[]]GetPermissionsFromModuleManifest($Manifest) {
        $permissions = New-Object System.Collections.ArrayList
        foreach ($permission in $Manifest.PrivateData.Permissions) {
            if ($permission -is [string]) {
                $p = [Permission]::new($Permission)
                $permissions.Add($p)
            } elseIf ($permission -is [hashtable]) {
                $p = [Permission]::new($permission.Name)
                if ($permission.Description) {
                    $p.Description = $permission.Description
                }
                $permissions.Add($p)
            }
        }

        if ($permissions.Count -gt 0) {
            $this.LogDebug("Permissions defined in module manifest", $permissions)
        } else {
            $this.LogDebug('No permissions defined in module manifest')
        }

        return $permissions
    }

    
    
    
    [void]LoadBuiltinPlugins() {
        $this.LogInfo('Loading builtin plugins')
        $builtinPlugin = Get-Item -Path "$($this._PoshBotModuleDir)/Plugins/Builtin"
        $moduleName = $builtinPlugin.BaseName
        $manifestPath = Join-Path -Path $builtinPlugin.FullName -ChildPath "$moduleName.psd1"
        $this.CreatePluginFromModuleManifest($moduleName, $manifestPath, $false, $false)
    }

    [hashtable]GetPluginConfig([string]$PluginName, [string]$Version) {
        if ($pluginConfig = $this._Storage.GetConfig('plugins')) {
            if ($thisPluginConfig = $pluginConfig[$PluginName]) {
                if (-not [string]::IsNullOrEmpty($Version)) {
                    if ($thisPluginConfig.ContainsKey($Version)) {
                        $pluginVersion = $Version
                    } else {
                        $this.LogDebug([LogSeverity]::Warning, "Plugin [$PluginName`:$Version] not defined in plugins.psd1")
                        return $null
                    }
                } else {
                    $pluginVersion = @($thisPluginConfig.Keys | Sort-Object -Descending)[0]
                }

                $pv = $thisPluginConfig[$pluginVersion]
                return $pv
            } else {
                $this.LogDebug([LogSeverity]::Warning, "Plugin [$PluginName] not defined in plugins.psd1")
                return $null
            }
        } else {
            $this.LogDebug([LogSeverity]::Warning, "No plugin configuration defined in storage")
            return $null
        }
    }
}
