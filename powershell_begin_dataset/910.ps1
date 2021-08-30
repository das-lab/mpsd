
$subscriptionId = 'yourSubscriptionId'


$resourceGroupName ='yourResourceGroupName'


$diskName = 'yourDiskName'


$diskSize = '128'


$storageType = 'Premium_LRS'





$location = 'westus'




$sourceVHDURI = 'https://contosostorageaccount1.blob.core.windows.net/vhds/contosovhd123.vhd'




$storageAccountId = '/subscriptions/yourSubscriptionId/resourceGroups/yourResourceGroupName/providers/Microsoft.Storage/storageAccounts/yourStorageAccountName'


Select-AzSubscription -SubscriptionId $SubscriptionId

$diskConfig = New-AzDiskConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI

New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $diskName
