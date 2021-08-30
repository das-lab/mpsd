
function Enable-CIisSecurityAuthentication
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
        [Switch]
        
        $Anonymous,

        [Parameter(Mandatory=$true,ParameterSetName='Basic')]
        [Switch]
        
        $Basic,
        
        [Parameter(Mandatory=$true,ParameterSetName='Windows')]
        [Switch]
        
        $Windows
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $authType = $pscmdlet.ParameterSetName
    $getArgs = @{ $authType = $true; }
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getArgs
    
    if( $authSettings.GetAttributeValue('enabled') )
    {
        return
    }
    
    $authSettings.SetAttributeValue('enabled', 'true')
    
    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, ("enable {0}" -f $authType) ) )
    {
        $authSettings.CommitChanges()
    }
}


