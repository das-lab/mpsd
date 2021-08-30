
function Get-CSslCertificateBinding
{
    
    [CmdletBinding()]
    [OutputType([Carbon.Certificates.SslCertificateBinding])]
    param(
        [IPAddress]
        
        $IPAddress,
        
        [UInt16]
        
        $Port
    )
   
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    [Carbon.Certificates.SslCertificateBinding]::GetSslCertificateBindings() |
        Where-Object {
            if( $IPAddress )
            {
                $_.IPAddress -eq $IPAddress
            }
            else
            {
                return $true
            }
        } |
        Where-Object {
            if( $Port )
            {
                $_.Port -eq $Port
            }
            else
            {
                return $true
            }
        }
    
}

Set-Alias -Name 'Get-SslCertificateBindings' -Value 'Get-CSslCertificateBinding'
