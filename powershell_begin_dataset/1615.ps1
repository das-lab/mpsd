
$Dest = "C:\Support\SQLBac\";    
$Daysback = "0";                 

$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem $Dest | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item