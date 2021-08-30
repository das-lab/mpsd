
function Uninstall-CPerformanceCounterCategory
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $CategoryName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CPerformanceCounterCategory -CategoryName $CategoryName) )
    {
        if( $pscmdlet.ShouldProcess( $CategoryName, 'uninstall performance counter category' ) )
        {
            [Diagnostics.PerformanceCounterCategory]::Delete( $CategoryName )
        }
    }
}

