













function Test-AzureSqlPolicy
{
	$vault = Get-AzRecoveryServicesVault -ResourceGroupName "sqlpaasrg" -Name "sqlpaasrn";
	
	
	$retPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureSQL"
	Assert-NotNull $retPolicy

	
	$policy = New-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name "swatipol1" `
		-WorkloadType "AzureSQL" `
		-RetentionPolicy $retPolicy
		
	
	$policy1 = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name "swatipol1"
	Assert-AreEqual $policy1.RetentionPolicy.RetentionCount 10;
	Assert-AreEqual $policy1.RetentionPolicy.RetentionDurationType "Months"

	$retPolicy.RetentionDurationType = "Weeks"
	$retPolicy.RetentionCount = 2
	Set-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-RetentionPolicy $retPolicy `
		-Policy $policy1

	$policy1 = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name "swatipol1"
	Assert-AreEqual $policy1.RetentionPolicy.RetentionCount 2
	Assert-AreEqual $policy1.RetentionPolicy.RetentionDurationType "Weeks"

	
	$policy2 = New-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Name "swatipol2" `
		-WorkloadType "AzureSQL" `
		-RetentionPolicy $retPolicy

	$listPolicy = Get-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-WorkloadType "AzureSQLDatabase"
	Assert-NotNull $listPolicy

	
	Remove-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Policy $policy1 -Force
	Remove-AzRecoveryServicesBackupProtectionPolicy `
		-VaultId $vault.ID `
		-Policy $policy2 -Force
}