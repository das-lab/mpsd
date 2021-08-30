
function Test-CIisConfigurationSection
{
    
    [CmdletBinding(DefaultParameterSetName='CheckExists')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SectionPath,
        
        [Parameter()]
        [string]
        
        $SiteName,
        
        [Parameter()]
        [Alias('Path')]
        [string]
        
        $VirtualPath,
        
        [Parameter(Mandatory=$true,ParameterSetName='CheckLocked')]
        [Switch]
        
        $Locked
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getArgs = @{
                    SectionPath = $SectionPath;
                }
    if( $SiteName )
    {
        $getArgs.SiteName = $SiteName
    }
    
    if( $VirtualPath )
    {
        $getArgs.VirtualPath = $VirtualPath
    }
    
    $section = Get-CIisConfigurationSection @getArgs -ErrorAction SilentlyContinue
    
    if( $pscmdlet.ParameterSetName -eq 'CheckExists' )
    {
        if( $section )
        {
            return $true
        }
        else
        {
            return $false
        }
    }
        
    if( -not $section )
    {
        Write-Error ('IIS:{0}: section {1} not found.' -f (Join-CIisVirtualPath $SiteName $VirtualPath),$SectionPath)
        return
    }
    
    if( $pscmdlet.ParameterSetName -eq 'CheckLocked' )
    {
        return $section.OverrideMode -eq 'Deny'
    }
}

