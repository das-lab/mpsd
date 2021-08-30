













$location = "southeastasia"
$resourceGroupName = "pstestFSRG1bca8f8e"
$vaultName = "PSTestFSRSV1bca8f8e"
$fileShareFriendlyName = "pstestfs1bca8f8e"
$fileShareName = "AzureFileShare;pstestfs1bca8f8e"
$saName = "pstestsa1bca8f8e"
$skuName="Standard_LRS"
$policyName = "AFSBackupPolicy"
$storageAccountId = "/subscriptions/da364f0f-307b-41c9-9d47-b7413ec45535/resourceGroups/pstestFSRG1bca8f8e/providers/Microsoft.Storage/storageAccounts/pstestsa1bca8f8e"























function Test-AzureFSProtectionCheck
{
	try
	{
  $status = Get-AzRecoveryServicesBackupStatus `
			-ResourceId $storageAccountId `
			-ProtectableObjectName $fileShareFriendlyName `
			-Type AzureFiles

		Assert-NotNull $status
		Assert-False { $status.BackedUp }

		$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
		$item = Enable-Protection $vault $fileShareFriendlyName $saName
		
		$status = Get-AzRecoveryServicesBackupStatus `
			-ResourceId $storageAccountId `
			-ProtectableObjectName $fileShareFriendlyName `
			-Type AzureFiles

		Assert-NotNull $status
		Assert-True { $status.BackedUp }
		Assert-True { $status.VaultId -eq $vault.ID }

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