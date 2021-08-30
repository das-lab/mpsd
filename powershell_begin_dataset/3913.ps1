














function Test-GetUsageAggregatesWithDefaultParameters()
{
	$result = Get-UsageAggregates -ReportedStartTime "5/1/2015" -ReportedEndTime "5/2/2015"
	Write-Debug $result
}