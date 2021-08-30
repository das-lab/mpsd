
$subscriptionId = 'yourSubscriptionId'


$resourceGroupName ='yourResourceGroupName'


$snapshotName = 'yourSnapshotName'


$storageType = 'StandardLRS'





$location = 'westus'




$sourceVHDURI = 'https://yourStorageAccountName.blob.core.windows.net/vhds/yourVHDName.vhd'




$storageAccountId = '/subscriptions/yourSubscriptionId/resourceGroups/yourResourceGroupName/providers/Microsoft.Storage/storageAccounts/yourStorageAccountName'


Select-AzSubscription -SubscriptionId $SubscriptionId

$snapshotConfig = New-AzSnapshotConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI 
Â 
New-AzSnapshot -Snapshot $snapshotConfig -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName
Â 
