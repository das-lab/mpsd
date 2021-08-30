















function Test-AzureVMGetContainers
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vm = Create-VM $resourceGroupName $location
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		Enable-Protection $vault $vm
		
		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-Status Registered;
		Assert-True { $containers.FriendlyName -contains $vm.Name }

		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-Status Registered `
			-FriendlyName $vm.Name;
		Assert-True { $containers.FriendlyName -contains $vm.Name }

		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-Status Registered `
			-FriendlyName $vm.Name `
			-ResourceGroupName $vm.ResourceGroupName;
		Assert-True { $containers.FriendlyName -contains $vm.Name }

		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-Status Registered `
			-ResourceGroupName $vm.ResourceGroupName;
		Assert-True { $containers.FriendlyName -contains $vm.Name }
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}