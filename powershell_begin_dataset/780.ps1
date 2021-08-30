
function Get-PsesRpcNotificationMessage {
    [CmdletBinding(DefaultParameterSetName = "PsesLogEntry")]
    param(
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "PsesLogEntry", ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject[]]
        $LogEntry,

        
        [Parameter(Position=1)]
        [ValidateSet(
            "$/cancelRequest",
            "initialized",
            "powerShell/executionStatusChanged",
            "textDocument/didChange",
            "textDocument/didClose",
            "textDocument/didOpen",
            "textDocument/didSave",
            "textDocument/publishDiagnostics",
            "workspace/didChangeConfiguration")]
        [string]
        $MessageName,

        
        
        [Parameter()]
        [string]
        $Pattern,

        
        [Parameter()]
        [ValidateSet('Client', 'Server')]
        [string]
        $Source
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $logEntries = Parse-PsesLog $Path
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "PsesLogEntry") {
            $logEntries = $LogEntry
        }

        foreach ($entry in $logEntries) {
            if ($entry.LogMessageType -ne 'Notification') { continue }

            if ((!$MessageName -or ($entry.Message.Name -eq $MessageName)) -and
                (!$Pattern -or ($entry.Message.Name -match $Pattern)) -and
                (!$Source -or ($entry.Message.Source -eq $Source))) {

                $entry
            }
        }
    }
}


function Get-PsesRpcMessageResponseTime {
    [CmdletBinding(DefaultParameterSetName = "PsesLogEntry")]
    param(
        
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="Path")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="PsesLogEntry", ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [psobject[]]
        $LogEntry,

        
        [Parameter(Position=1)]
        [ValidateSet(
            "textDocument/codeAction",
            "textDocument/codeLens",
            "textDocument/completion",
            "textDocument/documentSymbol",
            "textDocument/foldingRange",
            "textDocument/formatting",
            "textDocument/hover",
            "textDocument/rangeFormatting")]
        [string]
        $MessageName,

        
        
        [Parameter()]
        [string]
        $Pattern
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $logEntries = Parse-PsesLog $Path
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "PsesLogEntry") {
            $logEntries += $LogEntry
        }
    }

    end {
        
        $requests = @{}

        foreach ($entry in $logEntries) {
            if (($entry.LogMessageType -ne 'Request') -and ($entry.LogMessageType -ne 'Response')) { continue }

            if ((!$MessageName -or ($entry.Message.Name -eq $MessageName)) -and
                (!$Pattern -or ($entry.Message.Name -match $Pattern))) {

                $key = "$($entry.Message.Name)-$($entry.Message.Id)"
                if ($entry.LogMessageType -eq 'Request') {
                    $requests[$key] = $entry
                }
                else {
                    $request = $requests[$key]
                    if (!$request) {
                        Write-Warning "No corresponding request for response: $($entry.Message)"
                        continue
                    }

                    $elapsedMilliseconds = [int]($entry.Timestamp - $request.Timestamp).TotalMilliseconds
                    [PsesLogEntryElapsed]::new($entry, $elapsedMilliseconds)
                }
            }
        }
    }
}

function Get-PsesScriptAnalysisCompletionTime {
    [CmdletBinding(DefaultParameterSetName = "PsesLogEntry")]
    param(
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "PsesLogEntry", ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject[]]
        $LogEntry
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $logEntries = Parse-PsesLog $Path
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "PsesLogEntry") {
            $logEntries = $LogEntry
        }

        foreach ($entry in $logEntries) {
            if (($entry.LogMessageType -eq 'Log') -and ($entry.Message.Data -match '^\s*Script analysis of.*\[(?<ms>\d+)ms\]\s*$')) {
                $elapsedMilliseconds = [int]$matches["ms"]
                [PsesLogEntryElapsed]::new($entry, $elapsedMilliseconds)
            }
        }
    }
}

function Get-PsesIntelliSenseCompletionTime {
    [CmdletBinding(DefaultParameterSetName = "PsesLogEntry")]
    param(
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "PsesLogEntry", ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject[]]
        $LogEntry
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $logEntries = Parse-PsesLog $Path
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "PsesLogEntry") {
            $logEntries = $LogEntry
        }

        foreach ($entry in $logEntries) {
            
            if (($entry.LogMessageType -eq 'Log') -and ($entry.Message.Data -match '^\s*IntelliSense completed in\s+(?<ms>\d+)ms.\s*$')) {
                $elapsedMilliseconds = [int]$matches["ms"]
                [PsesLogEntryElapsed]::new($entry, $elapsedMilliseconds)
            }
        }
    }
}

function Get-PsesMessage {
    [CmdletBinding(DefaultParameterSetName = "PsesLogEntry")]
    param(
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "PsesLogEntry", ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [psobject[]]
        $LogEntry,

        
        
        [Parameter()]
        [PsesLogLevel]
        $LogLevel = $([PsesLogLevel]::Normal),

        
        [Parameter()]
        [switch]
        $StrictMatch
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $logEntries = Parse-PsesLog $Path
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "PsesLogEntry") {
            $logEntries = $LogEntry
        }

        foreach ($entry in $logEntries) {
            if (($StrictMatch -and ($entry.LogLevel -eq $LogLevel)) -or
                (!$StrictMatch -and ($entry.LogLevel -ge $LogLevel))) {
                $entry
            }
        }
    }
}
