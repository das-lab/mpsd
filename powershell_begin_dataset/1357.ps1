
function Enable-CIisDirectoryBrowsing
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/directoryBrowse'

    if( $section['enabled'] -ne 'true' )
    {
        Write-IisVerbose $SiteName 'Directory Browsing' 'disabled' 'enabled'
        $section['enabled'] = $true
        $section.CommitChanges()
    }

}

