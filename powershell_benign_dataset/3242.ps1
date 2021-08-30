



class PluginException : Exception {
    PluginException() {}
    PluginException([string]$Message) : base($Message) {}
}

class PluginNotFoundException : PluginException {
    PluginNotFoundException() {}
    PluginNotFoundException([string]$Message) : base($Message) {}
}

class PluginDisabled : PluginException {
    PluginDisabled() {}
    PluginDisabled([string]$Message) : base($Message) {}
}

class Plugin : BaseLogger {

    
    [string]$Name

    
    [hashtable]$Commands = @{}

    [version]$Version

    [bool]$Enabled

    [hashtable]$Permissions = @{}

    hidden [string]$_ManifestPath

    Plugin([Logger]$Logger) {
        $this.Name = $this.GetType().Name
        $this.Logger = $Logger
        $this.Enabled = $true
    }

    Plugin([string]$Name, [Logger]$Logger) {
        $this.Name = $Name
        $this.Logger = $Logger
        $this.Enabled = $true
    }

    
    [Command]FindCommand([Command]$Command) {
        return $this.Commands.($Command.Name)
    }

    
    [void]AddCommand([Command]$Command) {
        if (-not $this.FindCommand($Command)) {
            $this.LogDebug("Adding command [$($Command.Name)]")
            $this.Commands.Add($Command.Name, $Command)
        }
    }

    
    [void]RemoveCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $this.LogDebug("Removing command [$($Command.Name)]")
            $this.Commands.Remove($Command.Name)
        }
    }

    
    [void]ActivateCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $this.LogDebug("Activating command [$($Command.Name)]")
            $existingCommand.Activate()
        }
    }

    
    [void]DeactivateCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $this.LogDebug("Deactivating command [$($Command.Name)]")
            $existingCommand.Deactivate()
        }
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this.LogDebug("Adding permission [$Permission.ToString()] to plugin [$($this.Name)`:$($this.Version.ToString())]")
            $this.Permissions.Add($Permission.ToString(), $Permission)
        }
    }

    [Permission]GetPermission([string]$Name) {
        return $this.Permissions[$Name]
    }

    [void]RemovePermission([Permission]$Permission) {
        if ($this.Permissions.ContainsKey($Permission.ToString())) {
            $this.LogDebug("Removing permission [$Permission.ToString()] from plugin [$($this.Name)`:$($this.Version.ToString())]")
            $this.Permissions.Remove($Permission.ToString())
        }
    }

    
    [void]Activate() {
        $this.LogDebug("Activating plugin [$($this.Name)`:$($this.Version.ToString())]")
        $this.Enabled = $true
        $this.Commands.GetEnumerator() | ForEach-Object {
            $_.Value.Activate()
        }
    }

    
    [void]Deactivate() {
        $this.LogDebug("Deactivating plugin [$($this.Name)`:$($this.Version.ToString())]")
        $this.Enabled = $false
        $this.Commands.GetEnumerator() | ForEach-Object {
            $_.Value.Deactivate()
        }
    }

    [hashtable]ToHash() {
        $cmdPerms = @{}
        $this.Commands.GetEnumerator() | Foreach-Object {
            $cmdPerms.Add($_.Name, $_.Value.AccessFilter.Permissions.Keys)
        }

        $adhocPerms = New-Object System.Collections.ArrayList
        $this.Permissions.GetEnumerator() | Where-Object {$_.Value.Adhoc -eq $true} | Foreach-Object {
            $adhocPerms.Add($_.Name) > $null
        }
        return @{
            Name = $this.Name
            Version = $this.Version.ToString()
            Enabled = $this.Enabled
            ManifestPath = $this._ManifestPath
            CommandPermissions = $cmdPerms
            AdhocPermissions = $adhocPerms
        }
    }
}
