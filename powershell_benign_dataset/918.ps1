
$sourceSubscriptionId='yourSourceSubscriptionId'


$sourceResourceGroupName='yourResourceGroupName'


$snapshotName='yourSnapshotName'


Select-AzSubscription -SubscriptionId $sourceSubscriptionId


$snapshot= Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName -Name $snapshotName



$targetSubscriptionId='yourTargetSubscriptionId'


$targetResourceGroupName='yourTargetResourceGroupName'



Select-AzSubscription -SubscriptionId $targetSubscriptionId



$snapshotConfig = New-AzSnapshotConfig -SourceResourceId $snapshot.Id -Location $snapshot.Location -CreateOption Copy -SkuName Standard_LRS


New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $targetResourceGroupName 
