













function Test-AzureSqlGetItems
{
	
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "sqlpaasrg" -Name "sqlpaasrn";
	
	
	$namedContainer = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL" `
		-Name "Sql;sqlpaasrg;sqlpaasserver";
	Assert-AreEqual $namedContainer.Name "Sql;sqlpaasrg;sqlpaasserver";

	
	$item = Get-AzRecoveryServicesBackupItem `
		-VaultId $vault.ID `
		-Container $namedContainer `
		-WorkloadType "AzureSQLDatabase";
	Assert-AreEqual $item.Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";

	
	$item = Get-AzRecoveryServicesBackupItem `
		-VaultId $vault.ID `
		-Container $namedContainer `
		-WorkloadType "AzureSQLDatabase" `
		-Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";
	Assert-AreEqual $item.Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";
}

function Test-AzureSqlDisableProtection
{
	
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "sqlpaasrg" -Name "sqlpaasrn";
	
	
	$namedContainer = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL" `
		-Name "Sql;sqlpaasrg;sqlpaasserver";
	Assert-AreEqual $namedContainer.Name "Sql;sqlpaasrg;sqlpaasserver";

	
	$item = Get-AzRecoveryServicesBackupItem `
		-VaultId $vault.ID `
		-Container $namedContainer `
		-WorkloadType "AzureSQLDatabase" `
		-Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";
	Assert-AreEqual $item.Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";

	$job = Disable-AzRecoveryServicesBackupProtection `
		-VaultId $vault.ID `
		-Item $item `
		-RemoveRecoveryPoints `
		-Force;
}

function Test-AzureSqlGetRPs
{
	
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "sqlpaasrg" -Name "sqlpaasrn";
	
	
	$namedContainer = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType "AzureSQL" `
		-BackupManagementType "AzureSQL" `
		-Name "Sql;sqlpaasrg;sqlpaasserver";
	Assert-AreEqual $namedContainer.Name "Sql;sqlpaasrg;sqlpaasserver";

	
	$item = Get-AzRecoveryServicesBackupItem `
		-VaultId $vault.ID `
		-Container $namedContainer `
		-WorkloadType "AzureSQLDatabase" `
		-Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";
	Assert-AreEqual $item.Name "dsName;satyay-sea-d1-fc1-catalog-2016-11-11-17-20;661f0942-d5b7-486a-b3cb-68f97d325a3c";

	$fixedStartDate = Get-Date -Date "2016-06-13 16:30:00Z"
	$startDate = $fixedStartDate.ToUniversalTime()
	$fixedEndDate = Get-Date -Date "2016-06-18 10:30:00Z"
	$endDate = $fixedEndDate.ToUniversalTime()
	
	$recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint `
		-VaultId $vault.ID `
		-Item $item[0] `
		-StartDate $startDate `
		-EndDate $endDate
	if (!($recoveryPoints -eq $null))
	{
		foreach($recoveryPoint in $recoveryPoints)
		{
			Assert-NotNull $recoveryPoint.RecoveryPointTime 'RecoveryPointTime should not be null'
			Assert-NotNull $recoveryPoint.RecoveryPointType 'RecoveryPointType should not be null'
			Assert-NotNull $recoveryPoint.Name  'RecoveryPointId should not be null'
		}
	}
}

