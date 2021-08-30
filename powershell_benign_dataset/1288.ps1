
function Set-CIisWebsiteSslCertificate
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Thumbprint,

        [Parameter(Mandatory=$true)]        
        [Guid]
        
        $ApplicationID
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if( -not $site ) 
    {
        Write-Error "Unable to find website '$SiteName'."
        return
    }
    
    $site.Bindings | Where-Object { $_.Protocol -eq 'https' } | ForEach-Object {
        $installArgs = @{ }
        if( $_.Endpoint.Address -ne '0.0.0.0' )
        {
            $installArgs.IPAddress = $_.Endpoint.Address.ToString()
        }
        if( $_.Endpoint.Port -ne '*' )
        {
            $installArgs.Port = $_.Endpoint.Port
        }
        Set-CSslCertificateBinding @installArgs -ApplicationID $ApplicationID -Thumbprint $Thumbprint
    }
}

