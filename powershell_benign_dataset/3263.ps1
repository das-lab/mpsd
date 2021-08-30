


class Connection : BaseLogger {
    [ConnectionConfig]$Config
    [ConnectionStatus]$Status = [ConnectionStatus]::Disconnected

    [void]Connect() {}

    [void]Disconnect() {}
}
