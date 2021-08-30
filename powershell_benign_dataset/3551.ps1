













$containerName = "pstestwlvm1bca8"
$resourceGroupName = "pstestwlRG1bca8"
$vaultName = "pstestwlRSV1bca8"
$resourceId = "/subscriptions/da364f0f-307b-41c9-9d47-b7413ec45535/resourceGroups/pstestwlRG1bca8/providers/Microsoft.Compute/virtualMachines/pstestwlvm1bca8"
$policyName = "HourlyLogBackup"

 function Enable-Protection(
	$vault,
	$container)
{
	$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name $policyName

	$protectableItems = Get-AzRecoveryServicesBackupProtectableItem `
		-VaultId $vault.ID `
		-Container $container `
		-WorkloadType "MSSQL";

	Enable-AzRecoveryServicesBackupProtection `
		-VaultId $vault.ID `
		-Policy $policy `
		-ProtectableItem $protectableItems[1]

	$item = Get-AzRecoveryServicesBackupItem `
		-VaultId $vault.ID `
		-Container $container `
		-WorkloadType MSSQL;

 	return $item
}
function Cleanup-Vault(
	$vault,
	$item,
	$container)
{
	Disable-AzureRmRecoveryServicesBackupProtection `
			-VaultId $vault.ID `
			-Item $item `
			-RemoveRecoveryPoints `
			-Force;

	
	Unregister-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-Container $container
}