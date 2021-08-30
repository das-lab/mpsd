
function Assert-CFirewallConfigurable
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Get-Service 'Windows Firewall' -ErrorAction Ignore | Select-Object -ExpandProperty 'Status' -ErrorAction Ignore) -eq 'Running' )
    {
        return $true
    }
    elseif( (Get-Service -Name 'MpsSvc').Status -eq 'Running' )
    {
        return $true
    }

    Write-Error "Unable to configure firewall: Windows Firewall service isn't running."
    return $false
}
