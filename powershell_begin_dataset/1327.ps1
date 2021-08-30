
function Test-CPerformanceCounter
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CPerformanceCounterCategory -CategoryName $CategoryName) )
    {
        return [Diagnostics.PerformanceCounterCategory]::CounterExists( $Name, $CategoryName )
    }
    
    return $false
}

