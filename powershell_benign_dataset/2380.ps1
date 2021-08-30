




[CmdletBinding()]
param (
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName = $env:COMPUTERNAME
)

$filterHt = @{
	'LogName' = 'System'
	'ID'      = 6005
}
$StartEvents = Get-WinEvent -ComputerName $ComputerName -FilterHashtable $filterHt
if (-not $StartEvents) {
	throw 'Unable to determine any start times'	
}
$StartTimes = $StartEvents.TimeCreated


$filterHt.ID = 6006
$StopEvents = Get-WinEvent -ComputerName $ComputerName -FilterHashtable $filterHt -Oldest
$StopTimes = $StopEvents.TimeCreated

foreach ($startTime in $StartTimes) {
	$StopTime = $StopTimes | ? { $_ -gt $StartTime } | select -First 1
	if (-not $StopTime) {
		$StopTime = Get-Date	
	}
	$output = [ordered]@{
		'Startup'       = $StartTime
		'Shutdown'      = $StopTime
		'Uptime (Days)' = [math]::Round((New-TimeSpan -Start $StartTime -End $StopTime).TotalDays, 2)
		'Uptime (Min)'  = [math]::Round((New-TimeSpan -Start $StartTime -End $StopTime).TotalMinutes, 2)
	}
	[pscustomobject]$output
	
}
