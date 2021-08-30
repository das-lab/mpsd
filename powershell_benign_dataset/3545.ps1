













function Test-AzureVMProtectionCheck
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-GalleryVM $resourceGroupName $location

		$status = Get-AzRecoveryServicesBackupStatus `
			-Name $vm.Name `
			-ResourceGroupName $vm.ResourceGroupName `
			-Type AzureVM

		Assert-NotNull $status
		Assert-False { $status.BackedUp }

		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		Enable-Protection $vault $vm
		
		$status = Get-AzRecoveryServicesBackupStatus -ResourceId $vm.Id
		Assert-NotNull $status
		Assert-True { $status.BackedUp }
		Assert-True { $status.VaultId -eq $vault.ID }
		
		Delete-Vault $vault

		$status = Get-AzRecoveryServicesBackupStatus -ResourceId $vm.Id

		Assert-NotNull $status
		Assert-False { $status.BackedUp }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}