
function Test-CSslCertificateBinding
{
    
    [CmdletBinding()]
    param(
        [IPAddress]
        
        $IPAddress,
        
        [Uint16]
        
        $Port
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $getArgs = @{ }
    if( $IPAddress )
    {
        $getArgs.IPAddress = $IPAddress
    }
    
    if( $Port )
    {
        $getArgs.Port = $Port
    }
    
    $binding = Get-CSslCertificateBinding @getArgs
    if( $binding )
    {
        return $True
    }
    else
    {
        return $False
    }
}

