














function Test-GetMetrics
{
    
	$rscname = 'subscriptions/56bb45c9-5c14-4914-885e-c6fd6f130f7c/resourceGroups/reactdemo/providers/Microsoft.Web/sites/reactdemowebapi'

    try
    {
        
        $actual = Get-AzMetric -ResourceId $rscname -starttime 2018-03-23T22:00:00Z -endtime 2018-03-23T22:30:00Z
 
        
        Assert-AreEqual 1 $actual.Count

        $actual = Get-AzMetric -ResourceId $rscname -MetricNames CpuTime,Requests -timeGrain 00:01:00 -starttime 2018-03-23T22:00:00Z -endtime 2018-03-23T22:30:00Z -AggregationType Count

        
        Assert-AreEqual 2 $actual.Count

        $metricFilter = New-AzMetricFilter -Dimension City -Operator eq -Value "Seattle","New York"

        Assert-AreEqual 1 $metricFilter.Count
    }
    finally
    {
        
        
    }
}


function Test-GetMetricDefinitions
{
    
    $rscname = 'subscriptions/56bb45c9-5c14-4914-885e-c6fd6f130f7c/resourceGroups/reactdemo/providers/Microsoft.Web/sites/reactdemowebapi'

    try
    {
        $actual = Get-AzMetricDefinition -ResourceId $rscname

        
        Assert-AreEqual 33 $actual.Count

        $actual = Get-AzMetricDefinition -ResourceId $rscname -MetricName CpuTime,Requests -MetricNamespace "Microsoft.Web/sites"

        Assert-AreEqual 2 $actual.Count
    }
    finally
    {
        
        
    }
}