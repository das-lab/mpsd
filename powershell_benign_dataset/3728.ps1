














function Test-AlertChangeState
{
	
	$alerts = Get-AzAlert -State "New" -TimeRange 1h
	$alert = $alerts[0]

	$oldState = $alert.State
	$newState = "Closed"
	$updatedAlert = Update-AzAlertState -AlertId $alert.Id -State $newState
	Assert-AreEqual $newState $updatedAlert.State

	
	$alert = Update-AzAlertState -AlertId $alert.Id -State $oldState
}

function Test-AlertsSummary
{
	$summary = Measure-AzAlertStatistic -GroupBy "severity,alertstate"

	Assert-AreEqual "severity" $summary.GroupBy
	Assert-NotNull $summary.TotalAlerts

	ForEach ($item in $summary.AggregatedCounts.Content){
		Assert-AreEqual "alertState" $item.GroupedBy
		Assert-NotNull $item.Count
	}
} 

function Test-GetAlertsFilteredByParameters
{
	$severityFilter = "Sev3"
	$monitorServiceFilter = "Platform"
	$alerts = Get-AzAlert -Severity $severityFilter -MonitorService $monitorServiceFilter
	ForEach ($alert in $alerts){
		Assert-AreEqual $severityFilter $alert.Severity
		Assert-AreEqual $monitorServiceFilter $alert.MonitorService
	}
}