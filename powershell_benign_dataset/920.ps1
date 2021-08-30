
$subscriptionId = 'yourSubscriptionId'


$resourceGroupName ='yourResourceGroupName'


$snapshotName = 'yourSnapshotName'


$diskName = 'yourManagedDiskName'


$diskSize = '128'


$storageType = 'Premium_LRS'





$location = 'westus'


Select-AzSubscription -SubscriptionId $SubscriptionId

$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName 

$diskConfig = New-AzDiskConfig -SkuName $storageType -Location $location -CreateOption Copy -SourceResourceId $snapshot.Id
 
New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $diskName
