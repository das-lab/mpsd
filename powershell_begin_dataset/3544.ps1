













function Test-BmsGetContainer
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "pstestrg" -Name "pstestrsvault";
	$containers = Get-AzRecoveryServicesBackupManagementServer -VaultId $vault.ID;

	$namedContainer = Get-AzRecoveryServicesBackupManagementServer `
		-VaultId $vault.ID `
		-Name "PRCHIDEL-VEN2.FAREAST.CORP.MICROSOFT.COM";
	Assert-AreEqual $namedContainer.FriendlyName "PRCHIDEL-VEN2.FAREAST.CORP.MICROSOFT.COM";
}

function Test-BmsUnregisterContainer
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "pstestrg" -Name "pstestrsvault";
	
	$container = Get-AzRecoveryServicesBackupManagementServer `
		-VaultId $vault.ID `
		-Name "PRCHIDEL-VEN2.FAREAST.CORP.MICROSOFT.COM";
	Assert-AreEqual $container.FriendlyName "PRCHIDEL-VEN2.FAREAST.CORP.MICROSOFT.COM";

	Unregister-AzRecoveryServicesBackupManagementServer `
		-VaultId $vault.ID `
		-AzureRmBackupManagementServer $container;
}