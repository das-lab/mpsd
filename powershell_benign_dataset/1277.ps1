
function Unlock-CIisConfigurationSection
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        
        
        
        $SectionPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $SectionPath |
        ForEach-Object {
            $section = Get-CIisConfigurationSection -SectionPath $_
            $section.OverrideMode = 'Allow'
            if( $pscmdlet.ShouldProcess( $_, 'unlocking IIS configuration section' ) )
            {
                $section.CommitChanges()
            }
        }
}


