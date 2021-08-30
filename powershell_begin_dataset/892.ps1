$resourceGroupNameSub1 = "<replace-with-your-group-name>"
$resourceGroupNameSub2 = "<replace-with-desired-new-group-name>"
$webAppNameSub1 = "<replace-with-your-app-name>"
$webAppNameSub2 = "<replace-with-desired-new-app-name>"
$appServicePlanSub2 = "<replace-with-desired-new-plan-name>"
$locationSub2 = "West Europe"



Add-AzAccount


Get-AzWebAppBackupList -ResourceGroupName $resourceGroupNameSub1 -Name $webAppNameSub1




$backup = (Get-AzWebAppBackupList -ResourceGroupName $resourceGroupNameSub1 -Name $webAppNameSub1 | where {$_.BackupId -eq <replace-with-BackupID>}) 


Add-AzAccount


New-AzWebApp -ResourceGroupName $resourceGroupNameSub2 -AppServicePlan $appServicePlanSub2 -Name $webAppNameSub2 -Location $locationSub2


Restore-AzWebAppBackup -ResourceGroupName $resourceGroupNameSub2 -Name $webAppNameSub2 -StorageAccountUrl $backup.StorageAccountUrl -BlobName $backup.BlobName -Overwrite
