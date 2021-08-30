$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"


Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname




Remove-AzWebAppBackup -ResourceGroupName $resourceGroupName -Name $webappname `
-BackupId <replace-with-BackupID>
