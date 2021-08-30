

class CommandResult {
    [bool]$Success
    [object[]]$Errors = @()
    [object[]]$Output = @()
    [Stream]$Streams = [Stream]::new()
    [bool]$Authorized = $true
    [timespan]$Duration

    [pscustomobject]Summarize() {
        return [pscustomobject]@{
            Success = $this.Success
            Output = $this.Output
            Errors = foreach ($item in $this.Errors) {
                
                if ($item -is [System.Management.Automation.ErrorRecord]) {
                    [ExceptionFormatter]::Summarize($item)
                } else {
                    $item
                }
            }
            Authorized = $this.Authorized
            Duration = $this.Duration.TotalSeconds
        }
    }

    [string]ToJson() {
        return $this.Summarize() | ConvertTo-Json -Depth 10 -Compress
    }
}
