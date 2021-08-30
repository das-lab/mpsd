
$rsVaultName = "myRsVault"
$rgName = "myResourceGroup"
$location = "East US"


Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"
New-AzResourceGroup -Location $location -Name $rgName


New-AzRecoveryServicesVault `
    -Name $rsVaultName `
    -ResourceGroupName $rgName `
    -Location $location 
$vault1 = Get-AzRecoveryServicesVault -Name $rsVaultName
Set-AzRecoveryServicesProperties ` 
    -Vault $vault1 `
    -BackupStorageRedundancy GeoRedundant
    

Get-AzRecoveryServicesVault -Name $rsVaultName | Set-AzRecoveryServicesVaultContext 
$schPol = Get-AzRecoveryServicesSchedulePolicyObject -WorkloadType "AzureVM"
$retPol = Get-AzRecoveryServicesRetentionPolicyObject -WorkloadType "AzureVM"
New-AzRecoveryServicesProtectionPolicy `
    -Name "NewPolicy" `
    -WorkloadType "AzureVM" ` 
    -RetentionPolicy $retPol `
    -SchedulePolicy $schPol
    

Set-AzKeyVaultAccessPolicy `
    -VaultName "KeyVaultName" `
    -ResourceGroupName "KyeVault-RGName" ` 
    -PermissionsToKeys backup,get,list `
    -PermissionsToSecrets backup,get,list ` 
    -ServicePrincipalName 262044b1-e2ce-469f-a196-69ab7ada62d3
$pol = Get-AzRecoveryServicesProtectionPolicy -Name "NewPolicy" `
Enable-AzRecoveryServicesProtection `
    -Policy $pol `
    -Name "myVM" `
    -ResourceGroupName "VM-RGName" 
    

$retPol = Get-AzRecoveryServicesRetentionPolicyObject -WorkloadType "AzureVM"
$retPol.DailySchedule.DurationCountInDays = 365
$pol = Get-AzRecoveryServicesProtectionPolicy -Name "NewPolicy"
Set-AzRecoveryServicesProtectionPolicy `
    -Policy $pol `
    -RetentionPolicy $RetPol
    

$namedContainer = Get-AzRecoveryServicesContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName "myVM"
$item = Get-AzRecoveryServicesItem -Container $namedContainer -WorkloadType "AzureVM"
$job = Backup-AzRecoveryServicesItem -Item $item
$joblist = Get-AzRecoveryServicesJob -Status "InProgress"
Wait-AzRecoveryServicesJob `
        -Job $joblist[0] `
        -Timeout 43200
