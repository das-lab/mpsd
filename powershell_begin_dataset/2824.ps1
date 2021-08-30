function Send-GraphiteMetric
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
        [string]$MetricPath,

        [parameter(Mandatory = $true)]
        [string]$MetricValue,

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
        
        $UnixTime = [uint64]$DateTime.ToUniversalTime()
    }

    
    $metric = $MetricPath + " " + $MetricValue + " " + $UnixTime

    Write-Verbose "Metric Received: $metric"

    $sendMetricsParams = @{
        "CarbonServer" = $CarbonServer
        "CarbonServerPort" = $CarbonServerPort
        "Metrics" = $metric
        "IsUdp" = $UDP
        "TestMode" = $TestMode
    }

    SendMetrics @sendMetricsParams
}