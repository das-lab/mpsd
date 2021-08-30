
function Lock-CIisConfigurationSection
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
            $section.OverrideMode = 'Deny'
            if( $pscmdlet.ShouldProcess( $_, 'locking IIS configuration section' ) )
            {
                $section.CommitChanges()
            }
        }
}

