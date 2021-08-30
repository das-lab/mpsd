$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"



Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname




$backup = (Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname | where {$_.BackupId -eq <replace-with-BackupID>}) 


$backup | Restore-AzWebAppBackup -Overwrite
