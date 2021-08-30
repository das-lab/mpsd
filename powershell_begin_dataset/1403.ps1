
function Test-CPerformanceCounterCategory
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $CategoryName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return [Diagnostics.PerformanceCounterCategory]::Exists( $CategoryName )
}

