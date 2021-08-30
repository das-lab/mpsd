
$sourceSubscriptionId='yourSourceSubscriptionId'


$sourceResourceGroupName='mySourceResourceGroupName'


$managedDiskName='myDiskName'


Select-AzSubscription -SubscriptionId $sourceSubscriptionId


$managedDisk= Get-AzDisk -ResourceGroupName $sourceResourceGroupName -DiskName $managedDiskName



$targetSubscriptionId='yourTargetSubscriptionId'


$targetResourceGroupName='myTargetResourceGroupName'



Select-AzSubscription -SubscriptionId $targetSubscriptionId

$diskConfig = New-AzDiskConfig -SourceResourceId $managedDisk.Id -Location $managedDisk.Location -CreateOption Copy 


New-AzDisk -Disk $diskConfig -DiskName $managedDiskName -ResourceGroupName $targetResourceGroupName
