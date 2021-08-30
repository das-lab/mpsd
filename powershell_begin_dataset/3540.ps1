













function Test-AzureSqlGetContainers
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "sqlpaasrg" -Name "sqlpaasrn";
	$containers = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL";
	
	Assert-AreEqual $containers[0].Name "Sql;sqlpaasrg;sqlpaasserver";

	$namedContainer = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL" `
		-Name "Sql;sqlpaasrg;sqlpaasserver";
	Assert-AreEqual $namedContainer.Name "Sql;sqlpaasrg;sqlpaasserver";
}

function Test-AzureSqlUnregisterContainer
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "sqlpaasrg" -Name "sqlpaasrn";
	
	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL" `
		-Name "Sql;sqlpaasrg;sqlpaasserver";
	Assert-AreEqual $container.Name "Sql;sqlpaasrg;sqlpaasserver";

	Unregister-AzRecoveryServicesBackupContainer -VaultId $vault.ID -Container $container;
	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL" `
		-Name "Sql;sqlpaasrg;sqlpaasserver";
	Assert-Null $container;
}