
function Set-CIisWindowsAuthentication
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [Switch]
        
        $DisableKernelMode
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $useKernelMode = 'True'
    if( $DisableKernelMode )
    {
        $useKernelMode = 'False'
    }
    
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath -Windows
    $authSettings.SetAttributeValue( 'useKernelMode', $useKernelMode )

    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, "set Windows authentication" ) )
    {
        $authSettings.CommitChanges()
    }
}


