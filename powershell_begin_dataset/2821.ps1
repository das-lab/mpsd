Function Start-SQLStatsToGraphite
{

    [CmdletBinding()]
    Param
    (
        
        [Parameter(Mandatory = $false)]
        [switch]$TestMode
    )

    $PSBoundParameters['ExcludePerfCounters'] = $true
    $PSBoundParameters['SqlMetrics'] = $true

    Start-StatsToGraphite @PSBoundParameters
}