
function Get-CCertificateStore
{
    
    [CmdletBinding(DefaultParameterSetName='ByStoreName')]
    param(
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        
        $StoreLocation,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByStoreName')]
        [Security.Cryptography.X509Certificates.StoreName]
        
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='ByCustomStoreName')]
        [string]
        
        $CustomStoreName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -eq 'ByStoreName' )
    {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store $StoreName,$StoreLocation
    }
    else
    {
        $store = New-Object Security.Cryptography.X509Certificates.X509Store $CustomStoreName,$StoreLocation
    }

    $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )
    return $store
}

