


class ConnectionConfig {

    [string]$Endpoint

    [pscredential]$Credential

    ConnectionConfig() {}

    ConnectionConfig([string]$Endpoint, [pscredential]$Credential) {
        $this.Endpoint = $Endpoint
        $this.Credential = $Credential
    }
}
