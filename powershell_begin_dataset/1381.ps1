
function Set-CSslCertificateBinding
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Carbon.Certificates.SslCertificateBinding])]
    param(
        [IPAddress]
        
        $IPAddress = '0.0.0.0',
        
        [UInt16]
        
        $Port = 443,
        
        [Parameter(Mandatory=$true)]
        [Guid]
        
        $ApplicationID,
        
        [Parameter(Mandatory=$true)]
        [ValidatePattern("^[0-9a-f]{40}$")]
        [string]
        
        $Thumbprint,

        [Switch]
        
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    Remove-CSslCertificateBinding -IPAddress $IPAddress -Port $Port
    
    $action = 'creating SSL certificate binding'
    if( $pscmdlet.ShouldProcess( $IPPort, $action ) )
    {
        $appID = $ApplicationID.ToString('B')
        Invoke-ConsoleCommand -Target $ipPort -Action $action -ScriptBlock {
            netsh http add sslcert ipport=$ipPort certhash=$Thumbprint appid=$appID
        }

        if( $PassThru )
        {
            Get-CSslCertificateBinding -IPAddress $IPAddress -Port $Port
        }
    }
}

