












Param($NumberOfDays = 30, [switch]$debug)

if($debug) { $DebugPreference = " continue" }

[timespan]$uptime = New-TimeSpan -start 0 -end 0
$currentTime = get-Date
$startUpID = 6005
$shutDownID = 6006
$minutesInPeriod = (24*60)*$NumberOfDays
$startingDate = (Get-Date -Hour 00 -Minute 00 -Second 00).adddays(-$numberOfDays)

Write-debug "'$uptime $uptime" ; start-sleep -s 1
write-debug "'$currentTime $currentTime" ; start-sleep -s 1
write-debug "'$startingDate $startingDate" ; start-sleep -s 1

foreach($server in GC c:\input.txt)
{

$events = Get-EventLog -LogName system -ComputerName $server | 
Where-Object { $_.eventID -eq  $startUpID -OR $_.eventID -eq $shutDownID `
  -and $_.TimeGenerated -ge $startingDate } 

write-debug "'$events $($events)" ; start-sleep -s 1

$sortedList = New-object system.collections.sortedlist

ForEach($event in $events)
{
 $sortedList.Add( $event.timeGenerated, $event.eventID )
} 
$uptime = $currentTime - $sortedList.keys[$($sortedList.Keys.Count-1)]
Write-Debug "Current uptime $uptime"

For($item = $sortedList.Count-2 ; $item -ge 0 ; $item -- )
{ 
 Write-Debug "$item `t `t $($sortedList.GetByIndex($item)) `t `
   $($sortedList.Keys[$item])" 
 if($sortedList.GetByIndex($item) -eq $startUpID)
 {
  $uptime += ($sortedList.Keys[$item+1] - $sortedList.Keys[$item])
  Write-Debug "adding uptime. `t uptime is now: $uptime"
 } 
} 


$UpTimeMinutes = $Uptime.TotalMinutes
$UpTimehrs = ($UpTimeMinutes / 60)
$percentDownTime = "{0:n2}" -f (100 - ($UpTimeMinutes/$minutesInPeriod)*100)
$percentUpTime = 100 - $percentDowntime
"Total up time on server $server since $startingDate is $UpTimehrs"
write-host "$percentDowntime% downtime on server $server" -ForegroundColor red
write-host "$percentUpTime% uptime on server $server" -ForegroundColor green
}