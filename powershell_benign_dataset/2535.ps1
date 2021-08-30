





$LastDayOfMonth = (Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1 -DisplayHint Date).AddMonths(1).AddDays(-1) 

Write-Host ($lastDayOfMonth).Date



$DateDiff1 = New-TimeSpan $(Get-Date -month 9 -day 29 -year 2011) $lastDayOfMonth
$DateDiff2 = New-TimeSpan $(Get-Date -month 9 -day 28 -year 2011) $lastDayOfMonth
$DateDiff3 = New-TimeSpan $(Get-Date -month 9 -day 27 -year 2011) $lastDayOfMonth
$DateDiff4 = New-TimeSpan $(Get-Date -month 9 -day 26 -year 2011) $lastDayOfMonth

Write-Host ($DateDiff1).days "9-29-2011";
Write-Host ($DateDiff2).days "9-28-2011";
Write-Host ($DateDiff3).days "9-27-2011";
Write-Host ($DateDiff4).days "9-26-2011";





	









if ((Get-Date).Day -eq 1) {
	Write-Host "The first of the month.";
}

if (($DateDiff.days -eq '1')) {
	Write-Host "The date is within one day of the end of the month.";
}
elseif (($DateDiff.days -eq '2')) {
	Write-Host "The date is within two days of the end of the month.";
}
elseif (($DateDiff.days -eq '3')) {
	Write-Host "The date is within three days of the end of the month.";
}
elseif (($DateDiff.days -eq '4')) {
	Write-Host "The date is within four days of the end of the month.";
}

