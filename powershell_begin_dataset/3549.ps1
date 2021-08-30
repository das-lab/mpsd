













$resourceGroupName = "RecoveryServicesBackupTestRg";
$resourceName = "PsTestRsVault";
$policyName = "PsTestPolicy";
$defaultPolicyName = "DefaultPolicy";
$DefaultSnapshotDays = 2;
$UpdatedSnapShotDays = 5;


$oldResourceGroupName = "shracrg"
$oldVaultName = "shracsql"
$oldPolicyName = "iaasvmretentioncheck"

function Test-AzureVMPolicy
{
	$location = Get-ResourceGroupLocation
	$resourceGroupName = Create-ResourceGroup $location

	try
	{
		
		$vault = Create-RecoveryServicesVault $resourceGroupName $location
		
		
		$schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
		Assert-NotNull $schedulePolicy
		$retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM
		Assert-NotNull $retentionPolicy

		
		$policyName = "newPolicy"
		$policy = New-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name $policyName `
			-WorkloadType AzureVM `
			-RetentionPolicy $retentionPolicy `
			-SchedulePolicy $schedulePolicy
		Assert-NotNull $policy
		Assert-AreEqual $policy.Name $policyName
		Assert-AreEqual $policy.SnapshotRetentionInDays $DefaultSnapshotDays

		
		$oldVault = Get-AzRecoveryServicesVault -ResourceGroupName $oldResourceGroupName -Name $oldVaultName
		$oldPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $oldPolicyName -VaultId $oldVault.ID
		Assert-AreEqual $oldPolicy.RetentionPolicy.DailySchedule.DurationCountInDays 1
		
		
	    $policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name $policyName
		Assert-NotNull $policy
		Assert-AreEqual $policy.Name $policyName

		$defaultPolicy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name $defaultPolicyName
		Assert-NotNull $defaultPolicy
		Assert-AreEqual $defaultPolicy.Name $defaultPolicyName
		Assert-True { $defaultPolicy.SchedulePolicy.ScheduleRunDays -contains "Saturday" }
		Assert-True { $defaultPolicy.SchedulePolicy.ScheduleRunDays -contains "Thursday" }
		Assert-False { $defaultPolicy.SchedulePolicy.ScheduleRunDays -contains "Sunday" }
		Assert-False { $defaultPolicy.SchedulePolicy.ScheduleRunDays -contains "Friday" }

		
		$schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
		Assert-NotNull $schedulePolicy
		$retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM
		Assert-NotNull $retentionPolicy

		
		$policy.SnapshotRetentionInDays = $UpdatedSnapShotDays;

		
		Set-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-RetentionPolicy $retentionPolicy `
			-SchedulePolicy $schedulePolicy `
			-Policy $policy

		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name $policyName
		Assert-AreEqual $policy.SnapshotRetentionInDays $UpdatedSnapShotDays

		
		Remove-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Policy $policy `
			-Force
	}
	finally
	{
		
		Cleanup-ResourceGroup $resourceGroupName
	}
}