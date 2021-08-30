
function Test-CIPAddress
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        
        $IPAddress
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ip = Get-CIPAddress | Where-Object { $_ -eq $IPAddress }
    if( $ip )
    {
        return $true
    }
    else
    {
        return $false
    }
}
