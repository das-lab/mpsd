













function Test-AzureVMGetJobs
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location
	
	try
	{
		
		$vm1 = Create-VM $resourceGroupName $location 1
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		Enable-Protection $vault $vm1

		

		$startDate1 = Get-QueryDateInUtc $((Get-Date).AddDays(-1)) "StartDate1"
		$endDate1 = Get-QueryDateInUtc $(Get-Date) "EndDate1"

		$jobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.ID -From $startDate1 -To $endDate1
		$jobCount1 = $jobs.Count

		$vm2 = Create-VM $resourceGroupName $location 2
		Enable-Protection $vault $vm2

		$endDate2 = Get-QueryDateInUtc $(Get-Date) "EndDate2"

		$jobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.ID -From $startDate1 -To $endDate2
		$jobCount2 = $jobs.Count

		Assert-True { $jobCount1 -lt $jobCount2 }

		
		foreach ($job in $jobs)
		{
			$jobDetails = Get-AzRecoveryServicesBackupJobDetails -VaultId $vault.ID -Job $job;
			$jobDetails2 = Get-AzRecoveryServicesBackupJobDetails `
				-VaultId $vault.ID `
				-JobId $job.JobId

			Assert-AreEqual $jobDetails.JobId $job.JobId
			Assert-AreEqual $jobDetails2.JobId $job.JobId
		}

		
		$jobs = Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startDate1 `
			-To $endDate2 `
			-Status Completed
		Assert-True { $jobs.Count -gt 0}

		
		$jobs = Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startDate1 `
			-To $endDate2 `
			-Operation ConfigureBackup
		Assert-True { $jobs.Count -gt 0}

		
		$jobs = Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startDate1 `
			-To $endDate2 `
			-BackupManagementType AzureVM
		Assert-True { $jobs.Count -gt 0}
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMGetJobsTimeFilter
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup -Location $location
	
	try
	{
		
		$vm1 = Create-VM $resourceGroupName $location 1
		$vm2 = Create-VM $resourceGroupName $location 2
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		Enable-Protection $vault $vm1
		Enable-Protection $vault $vm2

		

		$startTime1 = Get-QueryDateInUtc $((Get-Date).AddDays(-1)) "StartTime1"
		$endTime1 = Get-QueryDateInUtc $(Get-Date) "EndTime1"

		$filteredJobs = Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startTime1 `
			-To $endTime1

		
		$startTime1.AddSeconds(-1);
		$endTime1.AddSeconds(1);

		foreach ($job in $filteredJobs)
		{
			Assert-AreEqual $job.StartTime.ToUniversalTime().CompareTo($startTime1) 1
			Assert-AreEqual $endTime1.CompareTo($job.StartTime.ToUniversalTime()) 1
		}

		

		
		Assert-ThrowsContains { Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $endTime1 `
			-To $startTime1; } `
			"To filter should not be less than From filter";
		
		
		$startTime2 = Get-QueryDateLocal $((Get-Date).AddDays(-20)) "StartTime2"
		$endTime2 = $endTime1
		Assert-ThrowsContains { Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startTime2 `
			-To $endTime2 } `
			"Please specify From and To filter values in UTC. Other timezones are not supported";

		
		$startTime3 = Get-QueryDateInUtc $((Get-Date).AddDays(-40)) "StartTime3"
		$endTime3 = Get-QueryDateInUtc $(Get-Date) "EndTime3"
		Assert-ThrowsContains { Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startTime3 `
			-To $endTime3 } `
			"To filter should not be more than 30 days away from From filter";

		
		$startTime4 = Get-QueryDateInUtc $((Get-Date).AddYears(100).AddDays(-1)) "StartTime4"
		$endTime4 = Get-QueryDateInUtc $((Get-Date).AddYears(100)) "EndTime4"
		Assert-ThrowsContains { Get-AzRecoveryServicesBackupJob `
			-VaultId $vault.ID `
			-From $startTime4 `
			-To $endTime4 } `
			"From date should be less than current UTC time";
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMWaitJob
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup -Location $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm
		
		$backupJob = Backup-AzRecoveryServicesBackupItem -VaultId $vault.ID -Item $item

		Assert-True { $backupJob.Status -eq "InProgress" }

		$backupJob = Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID -Job $backupJob

		Assert-True { $backupJob.Status -eq "Completed" }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMCancelJob
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup -Location $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm
		
		$backupJob = Backup-AzRecoveryServicesBackupItem -VaultId $vault.ID -Item $item

		Assert-True { $backupJob.Status -eq "InProgress" }

		$cancelledJob = Stop-AzRecoveryServicesBackupJob -VaultId $vault.ID -Job $backupJob

		Assert-True { $cancelledJob.Status -ne "InProgress" }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}