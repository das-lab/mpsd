













function Test-AzureVMGetItems
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location 1
		$vm2 = Create-VM $resourceGroupName $location 12
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		Enable-Protection $vault $vm
		Enable-Protection $vault $vm2
		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name "DefaultPolicy"

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-Status Registered `
			-FriendlyName $vm.Name
		
		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-Name $vm.Name;
		Assert-True { $items.Count -eq 1 }
		Assert-True { $items.VirtualMachineId -contains $vm.Id }
		Assert-NotNull $items[0].LastBackupTime

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-ProtectionStatus Healthy;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-ProtectionState IRPending;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-Name $vm.Name `
			-ProtectionStatus Healthy;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-Name $vm.Name `
			-ProtectionState IRPending;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-ProtectionState IRPending `
			-ProtectionStatus Healthy;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM `
			-Name $vm.Name `
			-ProtectionState IRPending `
			-ProtectionStatus Healthy;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }

		
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Policy $policy;
		Assert-True { $items.VirtualMachineId -contains $vm.Id }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMProtection
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location

		
        Start-TestSleep 5000

		
		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name "DefaultPolicy";
	
		
		Enable-AzRecoveryServicesBackupProtection `
			-VaultId $vault.ID `
			-Policy $policy `
			-Name $vm.Name `
			-ResourceGroupName $vm.ResourceGroupName;

		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name "DefaultPolicy";

		Assert-True {$policy.ProtectedItemsCount -eq 1};

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-Status Registered;

		$item = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM

		
		Disable-AzRecoveryServicesBackupProtection `
			-VaultId $vault.ID `
			-Item $item `
			-RemoveRecoveryPoints `
			-Force;
		
		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name "DefaultPolicy";

		Assert-True {$policy.ProtectedItemsCount -eq 0};

	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMGetRPs
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
  		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm
		$backupJob = Backup-Item $vault $item

		
		$backupStartTime = $backupJob.StartTime.AddMinutes(-1);
		$backupEndTime = $backupJob.EndTime.AddMinutes(1);
		$recoveryPoint = Get-AzRecoveryServicesBackupRecoveryPoint `
			-VaultId $vault.ID `
			-StartDate $backupStartTime `
			-EndDate $backupEndTime `
			-Item $item;
	
		Assert-NotNull $recoveryPoint;
		Assert-True { $recoveryPoint.SourceResourceId -match $vm.Id };

		
		$recoveryPointDetail = Get-AzRecoveryServicesBackupRecoveryPoint `
			-VaultId $vault.ID `
			-RecoveryPointId $recoveryPoint[0].RecoveryPointId `
			-Item $item;
	
		Assert-NotNull $recoveryPointDetail;

		
		
		Assert-ThrowsContains { Get-AzRecoveryServicesBackupRecoveryPoint `
			-VaultId $vault.ID `
			-StartDate $backupEndTime `
			-EndDate $backupStartTime `
			-Item $item } `
			"End date should be greater than start date";
		
		
		$backupStartTime1 = Get-QueryDateInUtc $((Get-Date).AddYears(100)) "BackupStartTime1"
        Assert-ThrowsContains { Get-AzRecoveryServicesBackupRecoveryPoint `
			-VaultId $vault.ID `
			-StartDate $backupStartTime1 `
			-Item $item } `
			"Start date\time should be less than current UTC date\time";

		
		$backupStartTime2 = Get-QueryDateLocal $((Get-Date).AddDays(-20)) "BackupStartTime2"
        Assert-ThrowsContains { Get-AzRecoveryServicesBackupRecoveryPoint `
			-VaultId $vault.ID `
			-StartDate $backupStartTime2 `
			-Item $item } `
			"Please specify startdate and enddate in UTC format";
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMFullRestore
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location
	$targetResourceGroupName = Create-ResourceGroup $location 1

	try
	{
		
		$saName = Create-SA $resourceGroupName $location
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm
		$backupJob = Backup-Item $vault $item
		$rp = Get-RecoveryPoint $vault $item $backupJob

		Assert-ThrowsContains { Restore-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-VaultLocation $vault.Location `
			-RecoveryPoint $rp `
			-StorageAccountName $saName `
			-StorageAccountResourceGroupName $resourceGroupName `
			-UseOriginalStorageAccount } `
			"This recovery point doesn’t have the capability to restore disks to their original storage account. Re-run the restore command without the UseOriginalStorageAccountForDisks parameter.";

		$restoreJob1 = Restore-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-VaultLocation $vault.Location `
			-RecoveryPoint $rp `
			-StorageAccountName $saName `
			-StorageAccountResourceGroupName $resourceGroupName | `
				Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID

		Assert-True { $restoreJob1.Status -eq "Completed" }   

		$restoreJob2 = Restore-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-VaultLocation $vault.Location `
			-RecoveryPoint $rp `
			-StorageAccountName $saName `
			-StorageAccountResourceGroupName $resourceGroupName `
			-TargetResourceGroupName $targetResourceGroupName | `
				Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID

		Assert-True { $restoreJob2.Status -eq "Completed" }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
		Cleanup-ResourceGroup $targetResourceGroupName
	}
}

function Test-AzureUnmanagedVMFullRestore
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location
	
	try
	{
		$saName = Create-SA $resourceGroupName $location
		$vm = Create-UnmanagedVM $resourceGroupName $location $saName
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm $resourceGroupName
		$backupJob = Backup-Item $vault $item
		$rp = Get-RecoveryPoint $vault $item $backupJob

		$restoreJob = Restore-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-VaultLocation $vault.Location `
			-RecoveryPoint $rp `
			-StorageAccountName $saName `
			-StorageAccountResourceGroupName $resourceGroupName `
			-UseOriginalStorageAccount | Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID
		
		Assert-True { $restoreJob.Status -eq "Completed" }
	}
	finally
	{
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMRPMountScript
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm
		$backupJob = Backup-Item $vault $item
		$rp = Get-RecoveryPoint $vault $item $backupJob

		
		$mountScriptDetails = Get-AzRecoveryServicesBackupRPMountScript `
			-VaultId $vault.ID `
			-RecoveryPoint $rp

		Assert-NotNull $mountScriptDetails.OsType
		Assert-NotNull $mountScriptDetails.Password
		Assert-NotNull $mountScriptDetails.Filename
		Assert-NotNull $mountScriptDetails.FilePath

		Write-Output $mountScriptDetails

		
		Disable-AzRecoveryServicesBackupRPMountScript -VaultId $vault.ID -RecoveryPoint $rp
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMBackup
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		$item = Enable-Protection $vault $vm
		
		
		$backupJob = Backup-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Item $item | Wait-AzRecoveryServicesBackupJob -VaultId $vault.ID

		Assert-True { $backupJob.Status -eq "Completed" }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMSetVaultContext
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location

		
        Start-TestSleep 5000

		Set-AzRecoveryServicesVaultContext -Vault $vault

		
		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-Name "DefaultPolicy";
	
		
		Enable-AzRecoveryServicesBackupProtection `
			-Policy $policy `
			-Name $vm.Name `
			-ResourceGroupName $vm.ResourceGroupName;

		$container = Get-AzRecoveryServicesBackupContainer `
			-ContainerType AzureVM `
			-Status Registered;

		$item = Get-AzRecoveryServicesBackupItem `
			-Container $container `
			-WorkloadType AzureVM

		
		Disable-AzRecoveryServicesBackupProtection `
			-Item $item `
			-RemoveRecoveryPoints `
			-Force;
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}

function Test-AzureVMSoftDelete
{
	$location = "southeastasia"
	$resourceGroupName = Create-ResourceGroup $location

	try
	{	
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		Set-AzRecoveryServicesVaultContext -Vault $vault

		$item = Enable-Protection $vault $vm
		$backupJob = Backup-Item $vault $item
		
		
		
		Disable-AzRecoveryServicesBackupProtection `
			-VaultId $vault.ID `
			-Item $item `
			-RemoveRecoveryPoints `
			-Force;

		

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType "AzureVM" `
			-FriendlyName $vm.Name;

		$item = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType "AzureVM";

		

		Undo-AzRecoveryServicesBackupItemDeletion `
			-VaultId $vault.ID `
			-Item $item;

		$item = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType "AzureVM";

		
		Assert-True { $item.ProtectionState -eq "ProtectionStopped" }

	}
	finally
	{
		
	}
}