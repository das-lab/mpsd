
function Set-CIisHttpRedirect
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
        
        $Destination,
        
        [Carbon.Iis.HttpResponseStatus]
        
        [Alias('StatusCode')]
        $HttpResponseStatus = [Carbon.Iis.HttpResponseStatus]::Found,
        
        [Switch]
        
        $ExactDestination,
        
        [Switch]
        
        $ChildOnly
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $settings = Get-CIisHttpRedirect -SiteName $SiteName -Path $VirtualPath
    $settings.Enabled = $true
    $settings.Destination = $destination
    $settings.HttpResponseStatus = $HttpResponseStatus
    $settings.ExactDestination = $ExactDestination
    $settings.ChildOnly = $ChildOnly
    	
    if( $pscmdlet.ShouldProcess( (Join-CIisVirtualPath $SiteName $VirtualPath), "set HTTP redirect settings" ) ) 
    {
        $settings.CommitChanges()
    }
}

