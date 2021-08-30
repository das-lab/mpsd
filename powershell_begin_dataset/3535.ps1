













$location = "southeastasia"
$resourceGroupName = "pstestFSRG1bca8f8e"
$vaultName = "PSTestFSRSV1bca8f8e"
$fileShareFriendlyName = "pstestfs1bca8f8e"
$fileShareName = "AzureFileShare;pstestfs1bca8f8e"
$saName = "pstestsa1bca8f8e"
$skuName="Standard_LRS"
$policyName = "AFSBackupPolicy"























function Test-AzureFSContainer
{
	try
	{
		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
		$item = Enable-Protection $vault $fileShareFriendlyName $saName
		
		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered;
		Assert-True { $containers.FriendlyName -contains $saName }

		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered `
			-FriendlyName $saName;
		Assert-True { $containers.FriendlyName -contains $saName }

		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered `
			-ResourceGroupName $resourceGroupName;
		Assert-True { $containers.FriendlyName -contains $saName }
	
		
		$containers = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureStorage `
			-Status Registered `
			-FriendlyName $saName `
			-ResourceGroupName $resourceGroupName;
		Assert-True { $containers.FriendlyName -contains $saName }
	}
	finally
	{
		Cleanup-Vault $vault $item $containers
	}
}

function Test-AzureFSUnregisterContainer
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
	$item = Enable-Protection $vault $fileShareFriendlyName $saName

	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType AzureStorage `
		-Status Registered `
		-FriendlyName $saName

	
	Disable-AzRecoveryServicesBackupProtection `
		-VaultId $vault.ID `
		-Item $item `
		-RemoveRecoveryPoints `
		-Force;
	Unregister-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-Container $container

	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType AzureStorage `
		-Status Registered `
		-FriendlyName $saName
	Assert-Null $container	
}