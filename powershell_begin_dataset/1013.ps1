



$random = (New-Guid).ToString().Substring(0,8)


$subscriptionId = "my-azure-subscription-id"
 

$apiManagementName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"
 

$storageAccountName = "backup$random"
$containerName = "backups"
$backupName = $apiManagementName + "-apimbackup"
 

Select-AzSubscription -SubscriptionId $subscriptionId
 

New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
 

New-AzStorageAccount -StorageAccountName $storageAccountName -Location $location -ResourceGroupName $resourceGroupName -Type Standard_LRS
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName)[0].Value
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey


New-AzStorageContainer -Name $containerName -Context $storageContext -Permission blob
 

New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organisation -AdminEmail $adminEmail
 

Backup-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName -StorageContext $storageContext -TargetContainerName $containerName -TargetBlobName $backupName
 

Restore-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName -StorageContext $storageContext -SourceContainerName $containerName -SourceBlobName $backupName
