
function Remove-CSslCertificateBinding
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [IPAddress]
        
        $IPAddress = '0.0.0.0',
        
        [UInt16]
        
        $Port = 443
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( -not (Test-CSslCertificateBinding -IPAddress $IPAddress -Port $Port) )
    {
        return
    }
    
    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    Invoke-ConsoleCommand -Target $ipPort `
                          -Action "removing SSL certificate binding" `
                          -ScriptBlock { netsh http delete sslcert ipPort=$ipPort }
}

