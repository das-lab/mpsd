
function Set-CIisHttpHeader
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Value
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $httpProtocol = Get-CIisConfigurationSection -SiteName $SiteName `
                                                -VirtualPath $VirtualPath `
                                                -SectionPath 'system.webServer/httpProtocol'
    $headers = $httpProtocol.GetCollection('customHeaders') 
    $header = $headers | Where-Object { $_['name'] -eq $Name }
    
    if( $header )
    {
        $action = 'setting'
        $header['name'] = $Name
        $header['value'] = $Value
    }
    else
    {
        $action = 'adding'
        $addElement = $headers.CreateElement( 'add' )
        $addElement['name'] = $Name
        $addElement['value'] = $Value
        [void] $headers.Add( $addElement )
    }
    
    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, ('{0} HTTP header {1}' -f $action,$Name) ) )
    {
        $httpProtocol.CommitChanges()
    }
}

