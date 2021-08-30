
class Logger {

    
    [string]$LogDir

    hidden [string]$LogFile

    
    
    [LogLevel]$LogLevel

    
    [int]$MaxSizeMB

    
    [int]$FilesToKeep

    
    Logger([string]$LogDir, [LogLevel]$LogLevel, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $this.LogDir = $LogDir
        $this.LogLevel = $LogLevel
        $this.MaxSizeMB = $MaxLogSizeMB
        $this.FilesToKeep = $MaxLogsToKeep
        $this.LogFile = Join-Path -Path $this.LogDir -ChildPath 'PoshBot.log'
        $this.CreateLogFile()
        $this.Log([LogMessage]::new("Log level set to [$($this.LogLevel)]"))
    }

    hidden Logger() { }

    
    hidden [void]CreateLogFile() {
        if (Test-Path -Path $this.LogFile) {
            $this.RollLog($this.LogFile, $true)
        }
        Write-Debug -Message "[Logger:Logger] Creating log file [$($this.LogFile)]"
        New-Item -Path $this.LogFile -ItemType File -Force
    }

    
    [void]Log([LogMessage]$Message) {
        switch ($Message.Severity.ToString()) {
            'Normal' {
                if ($global:VerbosePreference -eq 'Continue') {
                    Write-Verbose -Message $Message.ToJson()
                } elseIf ($global:DebugPreference -eq 'Continue') {
                    Write-Debug -Message $Message.ToJson()
                }
                break
            }
            'Warning' {
                if ($global:WarningPreference -eq 'Continue') {
                    Write-Warning -Message $Message.ToJson()
                }
                break
            }
            'Error' {
                if ($global:ErrorActionPreference -eq 'Continue') {
                    Write-Error -Message $Message.ToJson()
                }
                break
            }
        }

        if ($Message.LogLevel.value__ -le $this.LogLevel.value__) {
            $this.RollLog($this.LogFile, $false)
            $json = $Message.ToJson()
            $this.WriteLine($json)
        }
    }

    [void]Log([LogMessage]$Message, [string]$LogFile, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $this.RollLog($LogFile, $false, $MaxLogSizeMB, $MaxLogSizeMB)
        $json = $Message.ToJson()
        $sw = [System.IO.StreamWriter]::new($LogFile, [System.Text.Encoding]::UTF8)
        $sw.WriteLine($json)
        $sw.Close()
    }

    
    hidden [void]WriteLine([string]$Message) {
        $sw = [System.IO.StreamWriter]::new($this.LogFile, [System.Text.Encoding]::UTF8)
        $sw.WriteLine($Message)
        $sw.Close()
    }

    hidden [void]RollLog([string]$LogFile, [bool]$Always) {
        $this.RollLog($LogFile, $Always, $this.MaxSizeMB, $this.FilesToKeep)
    }

    
    
    
    
    hidden [void]RollLog([string]$LogFile, [bool]$Always, $MaxLogSize, $MaxFilesToKeep) {

        $keep = $MaxFilesToKeep - 1

        if (Test-Path -Path $LogFile) {
            if ((($file = Get-Item -Path $logFile) -and ($file.Length/1mb) -gt $MaxLogSize) -or $Always) {
                
                if (Test-Path -Path "$logFile.$keep") {
                    Remove-Item -Path "$logFile.$keep"
                }
                foreach ($i in $keep..1) {
                    if (Test-path -Path "$logFile.$($i-1)") {
                        Move-Item -Path "$logFile.$($i-1)" -Destination "$logFile.$i"
                    }
                }
                Move-Item -Path $logFile -Destination "$logFile.$i"
                New-Item -Path $LogFile -Type File -Force > $null
            }
        }
    }
}
