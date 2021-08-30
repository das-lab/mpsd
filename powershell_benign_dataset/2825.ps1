function Send-BulkGraphiteMetrics
{

    param
    (
        [CmdletBinding(DefaultParametersetName = 'Date Object')]
        [parameter(Mandatory = $true)]
        [string]$CarbonServer,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$CarbonServerPort = 2003,

        [parameter(Mandatory = $true)]
        [hashtable]$Metrics,

        [Parameter(Mandatory = $true,
                   ParameterSetName = 'Epoch / Unix Time')]
        [ValidateRange(1, 99999999999999)]
        [string]$UnixTime,

        [Parameter(Mandatory = $true,
                   ParameterSetName = 'Date Object')]
        [datetime]$DateTime,

        
        [Parameter(Mandatory = $false)]
        [switch]$TestMode,

        
        [Parameter(Mandatory = $false)]
        [switch]$UDP
    )

    
    if ($DateTime)
    {
        $utcDate = $DateTime.ToUniversalTime()
        
        
        [uint64]$UnixTime = [double]::Parse((Get-Date -Date $utcDate -UFormat %s))
    }

    
    [string[]]$metricStrings = @()
    foreach ($key in $Metrics.Keys)
    {
        $metricStrings += $key + " " + $Metrics[$key] + " " + $UnixTime

        Write-Verbose ("Metric Received: " + $metricStrings[-1])
    }

    $sendMetricsParams = @{
        "CarbonServer" = $CarbonServer
        "CarbonServerPort" = $CarbonServerPort
        "Metrics" = $metricStrings
        "IsUdp" = $UDP
        "TestMode" = $TestMode
    }

    SendMetrics @sendMetricsParams
}