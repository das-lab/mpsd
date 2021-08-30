













$location = "westus"
$resourceGroupName = "pstestwlRG1bca8"
$vaultName = "pstestwlRSV1bca8"
$newPolicyName = "testSqlPolicy"

function Test-AzureVmWorkloadPolicy
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName
		
	
	$schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType MSSQL
	Assert-NotNull $schedulePolicy
	$retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType MSSQL
	Assert-NotNull $retentionPolicy

	
	$policy = New-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name $newPolicyName `
		-WorkloadType MSSQL `
		-RetentionPolicy $retentionPolicy `
		-SchedulePolicy $schedulePolicy
	Assert-NotNull $policy
	Assert-AreEqual $policy.Name $newPolicyName

	
	$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name $newPolicyName
	Assert-NotNull $policy
	Assert-AreEqual $policy.Name $newPolicyName

	
	$schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType MSSQL
	$schedulePolicy.FullBackupSchedulePolicy.ScheduleRunFrequency = "Weekly"
	$schedulePolicy.IsDifferentialBackupEnabled = $true
	$schedulePolicy.IsCompression = $true
	Assert-NotNull $schedulePolicy
  
	$retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType MSSQL
	$retentionPolicy.FullBackupRetentionPolicy.IsDailyScheduleEnabled = $false
	$retentionPolicy.DifferentialBackupRetentionPolicy.RetentionCount = 31
	Assert-NotNull $retentionPolicy

	
	Set-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-RetentionPolicy $retentionPolicy `
		-SchedulePolicy $schedulePolicy `
		-Policy $policy
	$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name $newPolicyName
	Assert-AreEqual $policy.DifferentialBackupRetentionPolicy.RetentionCount $retentionPolicy.DifferentialBackupRetentionPolicy.RetentionCount
	Assert-AreEqual $policy.IsCompression $schedulePolicy.IsCompression
	Assert-AreEqual $schedulePolicy.IsDifferentialBackupEnabled $true
	Assert-AreEqual $schedulePolicy.IsLogBackupEnabled $true

	
	Remove-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Policy $policy `
		-Force
	$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-WorkloadType MSSQL
	Assert-False { $policy.Name -contains $newPolicyName }
}