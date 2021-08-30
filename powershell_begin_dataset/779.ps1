
$peekBuf = $null
$currentLineNum = 0
$logEntryIndex = 0

function Parse-PsesLog {
    param(
        
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        
        [Parameter()]
        [switch]
        $OldLogFormat,

        
        [Parameter()]
        [switch]
        $HideProgress,

        
        [Parameter()]
        [switch]
        $SkipRpcMessageBody,

        
        [Parameter()]
        [switch]
        $DebugTimingInfo,

        
        [Parameter()]
        [int]
        $DebugTimingThresholdMs = 100
    )

    begin {
        $script:peekBuf = $null
        $script:currentLineNum = 1
        $script:logEntryIndex = 0

        if ($OldLogFormat) {
            
            
            $logEntryRegex =
                [regex]::new(
                    '^(?<ts>[^\[]+)\[(?<lev>([^\]]+))\]\s+(?<file>..[^:]+):\s+In method\s+''(?<meth>\w+)'',\s+line\s+(?<line>\d+)',
                    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
        else {
            
            
            $logEntryRegex =
                [regex]::new(
                    '^(?<ts>[^\[]+)\[(?<lev>([^\]]+))\]\s+tid:(?<tid>\d+)\s+in\s+''(?<meth>\w+)''\s+(?<file>..[^:]+):\s+line\s+(?<line>\d+)',
                    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }

        $filestream =
            [System.IO.FileStream]::new(
                $Path,
                [System.IO.FileMode]:: Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite,
                4096,
                [System.IO.FileOptions]::SequentialScan)
        $streamReader = [System.IO.StreamReader]::new($filestream, [System.Text.Encoding]::UTF8)

        
        $numLines = 0
        while ($null -ne $streamReader.ReadLine()) {
            $numLines++
        }

        
        
        $streamReader.Dispose()
        $filestream =
            [System.IO.FileStream]::new(
                $Path,
                [System.IO.FileMode]:: Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite,
                4096,
                [System.IO.FileOptions]::SequentialScan)
        $streamReader = [System.IO.StreamReader]::new($filestream, [System.Text.Encoding]::UTF8)

        function nextLine() {
            if ($null -ne $peekBuf) {
                $line = $peekBuf
                $script:peekBuf = $null
            }
            else {
                $line = $streamReader.ReadLine()
            }

            $script:currentLineNum++
            $line
        }

        function peekLine() {
            if ($null -ne $peekBuf) {
                $line = $peekBuf;
            }
            else {
                $line = $script:peekBuf = $streamReader.ReadLine()
            }

            $line
        }

        function parseLogEntryStart([string]$line) {
            if ($DebugTimingInfo) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
            }

            while ($line -notmatch $logEntryRegex) {
                Write-Warning "Ignoring line:${currentLineNum} '$line'"
                $line = nextLine
            }

            if (!$HideProgress -and ($script:logEntryIndex % 100 -eq 0)) {
                Write-Progress "Processing log entry ${script:logEntryIndex} on line: ${script:currentLineNum}" `
                    -PercentComplete (100 * $script:currentLineNum / $numLines)
            }

            [string]$timestampStr = $matches["ts"]
            [DateTime]$timestamp = $timestampStr
            [PsesLogLevel]$logLevel = $matches["lev"]
            [int]$threadId = $matches["tid"]
            [string]$method = $matches["meth"]
            [string]$file = $matches["file"]
            [int]$lineNumber = $matches["line"]

            $message = parseLogMessage $method

            [PsesLogEntry]::new($script:logEntryIndex, $timestamp, $timestampStr, $logLevel, $threadId, $method,
                $file, $lineNumber, $message.LogMessageType, $message.LogMessage)

            if ($DebugTimingInfo) {
                $sw.Stop()
                if ($sw.ElapsedMilliseconds -gt $DebugTimingThresholdMs) {
                    Write-Warning "Time to parse log entry ${script:logEntryIndex} - $($sw.ElapsedMilliseconds) ms"
                }
            }

            $script:logEntryIndex++
        }

        function parseLogMessage([string]$Method) {
            $result = [PSCustomObject]@{
                LogMessageType = [PsesLogMessageType]::Log
                LogMessage = $null
            }

            $line = nextLine
            if ($null -eq $line) {
                Write-Warning "$($MyInvocation.MyCommand.Name) encountered end of file early."
                return $result
            }

            if (($Method -eq 'ReadMessageAsync' -or $Method -eq 'ReadMessage') -and
                ($line -match '^\s+Received Request ''(?<msg>[^'']+)'' with id (?<id>\d+)')) {
                $result.LogMessageType = [PsesLogMessageType]::Request
                $msg = $matches["msg"]
                $id = $matches["id"]
                $json = parseLogMessageBodyAsJson
                $result.LogMessage = [PsesJsonRpcMessage]::new($msg, $id, $json.Data, $json.DataSize)
            }
            elseif (($Method -eq 'ReadMessageAsync' -or $Method -eq 'ReadMessage') -and
                    ($line -match '^\s+Received event ''(?<msg>[^'']+)''')) {
                $result.LogMessageType = [PsesLogMessageType]::Notification
                $msg = $matches["msg"]
                $json = parseLogMessageBodyAsJson
                $result.LogMessage = [PsesNotificationMessage]::new($msg, [PsesNotificationSource]::Client, $json.Data, $json.DataSize)
            }
            elseif (($Method -eq 'WriteMessageAsync' -or $Method -eq 'WriteMessage') -and
                    ($line -match '^\s+Writing Response ''(?<msg>[^'']+)'' with id (?<id>\d+)')) {
                $result.LogMessageType = [PsesLogMessageType]::Response
                $msg = $matches["msg"]
                $id = $matches["id"]
                $json = parseLogMessageBodyAsJson
                $result.LogMessage = [PsesJsonRpcMessage]::new($msg, $id, $json.Data, $json.DataSize)
            }
            elseif (($Method -eq 'WriteMessageAsync' -or $Method -eq 'WriteMessage') -and
                    ($line -match '^\s+Writing event ''(?<msg>[^'']+)''')) {
                $result.LogMessageType = [PsesLogMessageType]::Notification
                $msg = $matches["msg"]
                $json = parseLogMessageBodyAsJson
                $result.LogMessage = [PsesNotificationMessage]::new($msg, [PsesNotificationSource]::Server, $json.Data, $json.DataSize)
            }
            else {
                if  ($line -match '^\s+Exception: ') {
                    $result.LogMessageType = [PsesLogMessageType]::Exception
                }
                elseif  ($line -match '^\s+Handled exception: ') {
                    $result.LogMessageType = [PsesLogMessageType]::HandledException
                }
                else {
                    $result.LogMessageType = [PsesLogMessageType]::Log
                }

                $body = parseLogMessageBody $line
                $result.LogMessage = [PsesLogMessage]::new($body)
            }

            $result
        }

        function parseLogMessageBody([string]$startLine = '', [switch]$Discard) {
            if (!$Discard) {
                $strBld = [System.Text.StringBuilder]::new($startLine, 4096)
                $newLine = "`r`n"
            }

            try {
                while ($true) {
                    $peekLine = peekLine
                    if ($null -eq $peekLine) {
                        break
                    }

                    if (($peekLine.Length -gt 0) -and ($peekLine[0] -ne ' ') -and ($peekLine -match $logEntryRegex)) {
                        break
                    }

                    $nextLine = nextLine
                    if (!$Discard) {
                        [void]$strBld.Append($nextLine).Append($newLine)
                    }
                }
            }
            catch {
                Write-Error "Failed parsing message body with error: $_"
            }

            if (!$Discard) {
                $msgBody = $strBld.ToString().Trim()
                $msgBody
            }
            else {
                $startLine
            }
        }

        function parseLogMessageBodyAsJson() {
            $result = [PSCustomObject]@{
                Data = $null
                DataSize = 0
            }

            $obj = $null

            if ($SkipRpcMessageBody) {
                parseLogMessageBody -Discard
                return $result
            }

            $result.Data = parseLogMessageBody
            $result.DataSize = $result.Data.Length

            try {
                $result.Data = $result.Data.Trim() | ConvertFrom-Json
            }
            catch {
                Write-Error "Failed parsing JSON message body with error: $_"
            }

            $result
        }
    }

    process {
        while ($null -ne ($line = nextLine)) {
            parseLogEntryStart $line
        }
    }

    end {
        if ($streamReader) { $streamReader.Dispose() }
    }
}
