
function Clear-CTrustedHost
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $pscmdlet.ShouldProcess( 'trusted hosts', 'clear' ) )
    {
        Set-Item $TrustedHostsPath -Value '' -Force
    }

}

Set-Alias -Name 'Clear-TrustedHosts' -Value 'Clear-CTrustedHost'
