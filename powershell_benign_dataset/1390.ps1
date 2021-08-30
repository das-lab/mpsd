
function Enable-CIisSsl
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='IgnoreClientCertificates')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [Parameter(ParameterSetName='IgnoreClientCertificates')]
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Parameter(Mandatory=$true,ParameterSetName='RequireClientCertificates')]
        [Switch]
        
        $RequireSsl,
        
        [Switch]
        
        $Require128BitSsl,
        
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Switch]
        
        $AcceptClientCertificates,
        
        [Parameter(Mandatory=$true,ParameterSetName='RequireClientCertificates')]
        [Switch]
        
        $RequireClientCertificates
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $SslFlags_Ssl = 8
    $SslFlags_SslNegotiateCert = 32
    $SslFlags_SslRequireCert = 64
    $SslFlags_SslMapCert = 128
    $SslFlags_Ssl128 = 256

    $intFlag = 0
    $flags = @()
    if( $RequireSSL -or $RequireClientCertificates )
    {
        $flags += 'Ssl'
        $intFlag = $intFlag -bor $SslFlags_Ssl
    }
    
    if( $AcceptClientCertificates -or $RequireClientCertificates )
    {
        $flags += 'SslNegotiateCert'
        $intFlag = $intFlag -bor $SslFlags_SslNegotiateCert
    }
    
    if( $RequireClientCertificates )
    {
        $flags += 'SslRequireCert'
        $intFlag = $intFlag -bor $SslFlags_SslRequireCert
    }
    
    if( $Require128BitSsl )
    {
        $flags += 'Ssl128'
        $intFlag = $intFlag -bor $SslFlags_Ssl128
    }

    $section = Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath 'system.webServer/security/access'
    if( -not $section )
    {
        return
    }

    $flags = $flags -join ','
    $currentIntFlag = $section['sslFlags']
    $currentFlags = @( )
    if( $currentIntFlag -band $SslFlags_Ssl )
    {
        $currentFlags += 'Ssl'
    }
    if( $currentIntFlag -band $SslFlags_SslNegotiateCert )
    {
        $currentFlags += 'SslNegotiateCert'
    }
    if( $currentIntFlag -band $SslFlags_SslRequireCert )
    {
        $currentFlags += 'SslRequireCert'
    }
    if( $currentIntFlag -band $SslFlags_SslMapCert )
    {
        $currentFlags += 'SslMapCert'
    }
    if( $currentIntFlag -band $SslFlags_Ssl128 )
    {
        $currentFlags += 'Ssl128'
    }

    if( -not $currentFlags )
    {
        $currentFlags += 'None'
    }

    $currentFlags = $currentFlags -join ','


    if( $section['sslFlags'] -ne $intFlag )
    {
        Write-IisVerbose $SiteName 'SslFlags' ('{0} ({1})' -f $currentIntFlag,$currentFlags) ('{0} ({1})' -f $intFlag,$flags) -VirtualPath $VirtualPath
        $section['sslFlags'] = $flags
        if( $pscmdlet.ShouldProcess( (Join-CIisVirtualPath $SiteName $VirtualPath), "enable SSL" ) )
        {
            $section.CommitChanges()
        }
    }
}

