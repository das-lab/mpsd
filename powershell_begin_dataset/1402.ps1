
function Set-CTrustedHost
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        
		[Alias("Entries")]
        $Entry
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $value = $Entry -join ','
    if( $pscmdlet.ShouldProcess( 'trusted hosts', 'set' ) )
    {
        Set-Item $TrustedHostsPath -Value $Value -Force
    }
}

Set-Alias -Name 'Set-TrustedHosts' -Value 'Set-CTrustedHost'

