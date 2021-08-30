













function Test-MabGetContainers
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "pstestrg" -Name "pstestrsvault";
	$containers = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "Windows" `
		-BackupManagementType "MARS";
	
	Assert-AreEqual $containers[0].FriendlyName "ADIT-PC.FAREAST.CORP.MICROSOFT.COM";

	$namedContainer = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "Windows" `
		-BackupManagementType "MARS" `
		-FriendlyName "ADIT-PC.FAREAST.CORP.MICROSOFT.COM";
	Assert-AreEqual $namedContainer.FriendlyName "ADIT-PC.FAREAST.CORP.MICROSOFT.COM";
}

function Test-MabUnregisterContainer
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "pstestrg" -Name "pstestrsvault";
	
	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "Windows" `
		-BackupManagementType "MARS" `
		-FriendlyName "ADIT-PC.FAREAST.CORP.MICROSOFT.COM";
	Assert-AreEqual $container.FriendlyName "ADIT-PC.FAREAST.CORP.MICROSOFT.COM";

	Unregister-AzRecoveryServicesBackupContainer -VaultId $vault.ID -Container $container;
	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "Windows" `
		-BackupManagementType "MARS" `
		-FriendlyName "ADIT-PC.FAREAST.CORP.MICROSOFT.COM";
	Assert-Null $container;
}