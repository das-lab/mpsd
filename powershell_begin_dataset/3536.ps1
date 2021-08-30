













$location = "southeastasia"
$resourceGroupName = "pstestFSRG1bca8f8e"
$vaultName = "PSTestFSRSV1bca8f8e"
$fileShareFriendlyName = "pstestfs1bca8f8e"
$fileShareName = "AzureFileShare;pstestfs1bca8f8e"
$saName = "pstestsa1bca8f8e"
$skuName="Standard_LRS"
$policyName = "AFSBackupPolicy"























function Test-AzureFSGetJob
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
		$item = Enable-Protection $vault $fileShareFriendlyName $saName

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

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered `
			-FriendlyName $saName
	}
	finally
	{
		Cleanup-Vault $vault $item $container
	}
}

function Test-AzureFSWaitJob
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
 		$item = Enable-Protection $vault $fileShareFriendlyName $saName

		
		$backupJob = Backup-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Item $item

		Assert-True { $backupJob.Status -eq "InProgress" }

		$backupJob = Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID -Job $backupJob

		Assert-True { $backupJob.Status -eq "Completed" }

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered `
			-FriendlyName $saName
	}
	finally
	{
		Cleanup-Vault $vault $item $container
	}
}

function Test-AzureFSCancelJob
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
 		$item = Enable-Protection $vault $fileShareFriendlyName $saName

		
		$backupJob = Backup-AzRecoveryServicesBackupItem ` -VaultId $vault.ID -Item $item
		
		Assert-True { $backupJob.Status -eq "InProgress" }

		$cancelledJob = Stop-AzRecoveryServicesBackupJob -VaultId $vault.ID -Job $backupJob

		Assert-True { $cancelledJob.Status -ne "InProgress" }

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered `
			-FriendlyName $saName
	}
	finally
	{
		Cleanup-Vault $vault $item $container
	}
}