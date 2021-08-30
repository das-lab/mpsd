
function Test-CFirewallStatefulFtp
{
    
    [CmdletBinding()]
    param()
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Assert-CFirewallConfigurable) )
    {
        return
    }
    
    $output = netsh advfirewall show global StatefulFtp
    $line = $output[3]
    return $line -match 'Enable'
}

