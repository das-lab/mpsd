














$containerName = "pstestwlvm1bca8"
$resourceGroupName = "pstestwlRG1bca8"
$vaultName = "pstestwlRSV1bca8"
$resourceId = "/subscriptions/da364f0f-307b-41c9-9d47-b7413ec45535/resourceGroups/pstestwlRG1bca8/providers/Microsoft.Compute/virtualMachines/pstestwlvm1bca8"
$policyName = "HourlyLogBackup"

function Test-AzureVmWorkloadGetJob
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
		$container = Register-AzRecoveryServicesBackupContainer `
			-ResourceId $resourceId `
			-BackupManagementType AzureWorkload `
			-WorkloadType MSSQL `
			-VaultId $vault.ID `
			-Force

		Enable-Protection $vault $container

		$item = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType MSSQL;

		$startDate1 = Get-QueryDateInUtc $((Get-Date).AddDays(-1)) "StartDate1"
		$endDate1 = Get-QueryDateInUtc $(Get-Date) "EndDate1"

		$jobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.ID -From $startDate1 -To $endDate1

		foreach ($job in $jobs)
		{
			$jobDetails = Get-AzRecoveryServicesBackupJobDetails -VaultId $vault.ID -Job $job;
			$jobDetails2 = Get-AzRecoveryServicesBackupJobDetails `
				-VaultId $vault.ID `
				-JobId $job.JobId

			Assert-AreEqual $jobDetails.JobId $job.JobId
			Assert-AreEqual $jobDetails2.JobId $job.JobId
		}
	}
	finally
	{
		Cleanup-Vault $vault $item $container
	}
}

function Test-AzureVmWorkloadWaitJob
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
 		$container = Register-AzRecoveryServicesBackupContainer `
			-ResourceId $resourceId `
			-BackupManagementType AzureWorkload `
			-WorkloadType MSSQL `
			-VaultId $vault.ID `
			-Force

		Enable-Protection $vault $container

		$item = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType MSSQL;

		
		$backupJob = Backup-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Item $item `
			-BackupType "Full";

		Assert-True { $backupJob.Status -eq "InProgress" }

		$backupJob = Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID -Job $backupJob

		Assert-True { $backupJob.Status -eq "Completed" }
	}
	finally
	{
		Cleanup-Vault $vault $item $container
	}
}

function Test-AzureVmWorkloadCancelJob
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
 		$container = Register-AzRecoveryServicesBackupContainer `
			-ResourceId $resourceId `
			-BackupManagementType AzureWorkload `
			-WorkloadType MSSQL `
			-VaultId $vault.ID `
			-Force

		Enable-Protection $vault $container

		$item = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType MSSQL;

		
		$backupJob = Backup-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Item $item `
			-BackupType "Full";
		
		Assert-True { $backupJob.Status -eq "InProgress" }

		$cancelledJob = Stop-AzRecoveryServicesBackupJob -VaultId $vault.ID -Job $backupJob

		Assert-True { $cancelledJob.Status -ne "InProgress" }
	}
	finally
	{
		Cleanup-Vault $vault $item $container
	}
}