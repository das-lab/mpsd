
function Get-CTrustedHost
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $trustedHosts = (Get-Item $TrustedHostsPath -Force).Value 
    if( $trustedHosts )
    {
        return $trustedHosts -split ','
    }
}

Set-Alias -Name 'Get-TrustedHosts' -Value 'Get-CTrustedHost'
