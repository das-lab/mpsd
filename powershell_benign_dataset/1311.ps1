
function Get-CIPAddress
{
    
    [CmdletBinding(DefaultParameterSetName='NonFiltered')]
    param(
        [Parameter(ParameterSetName='Filtered')]
        [Switch]
        
        $V4,

        [Parameter(ParameterSetName='Filtered')]
        [Switch]
        
        $V6
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } | 
        ForEach-Object { $_.GetIPProperties() } | 
        Select-Object -ExpandProperty UnicastAddresses  | 
        Select-Object -ExpandProperty Address |
        Where-Object {
            if( $PSCmdlet.ParameterSetName -eq 'NonFiltered' )
            {
                return ($_.AddressFamily -eq 'InterNetwork' -or $_.AddressFamily -eq 'InterNetworkV6')
            }

            if( $V4 -and $_.AddressFamily -eq 'InterNetwork' )
            {
                return $true
            }

            if( $V6 -and $_.AddressFamily -eq 'InterNetworkV6' )
            {
                return $true
            }

            return $false
        }
}
