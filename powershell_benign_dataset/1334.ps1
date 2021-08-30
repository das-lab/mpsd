
function Get-CIisHttpRedirect
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = ''
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-CIisConfigurationSection -SiteName $SiteName `
                                -VirtualPath $VirtualPath `
                                -SectionPath 'system.webServer/httpRedirect' `
                                -Type ([Carbon.Iis.HttpRedirectConfigurationSection])
}

