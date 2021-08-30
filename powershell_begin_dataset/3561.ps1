




















function Test-NewA2ADiskReplicationConfiguration
{
    $recoveryStorageAccountId ="/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/a2a-rg/providers/Microsoft.Storage/storageAccounts/a2argdisks412"
    $logStorageAccountId = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/ltrgp1705152333/providers/Microsoft.Storage/storageAccounts/stagingsa2name1705152333"
    $vhdUri = "https://powershelltestdiag414.blob.core.windows.net/vhds/pslinV2-520180112143232.vhd"

    $v = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -VhdUri  $vhdUri `
        -RecoveryAzureStorageAccountId $recoveryStorageAccountId `
        -LogStorageAccountId   $logStorageAccountId

     Assert-True { $v.vhdUri -eq $vhdUri }
     Assert-True { $v.recoveryAzureStorageAccountId -eq $recoveryStorageAccountId  }
     Assert-True { $v.logStorageAccountId -eq $logStorageAccountId }
}



function Test-NewA2AManagedDiskReplicationConfiguration
{
    $logStorageAccountId = "fdd"
    $DiskId = "diskId"
    $RecoveryResourceGroupId = "3"
    $RecoveryReplicaDiskAccountType = "Premium_LRS"
    $RecoveryTargetDiskAccountType = "Premium_LRS"

    $v = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -managed -LogStorageAccountId $logStorageAccountId `
         -DiskId "diskId" -RecoveryResourceGroupId  $RecoveryResourceGroupId -RecoveryReplicaDiskAccountType  $RecoveryReplicaDiskAccountType `
         -RecoveryTargetDiskAccountType $RecoveryTargetDiskAccountType

     Assert-True { $v.LogStorageAccountId -eq $LogStorageAccountId }
     Assert-True { $v.DiskId -eq $DiskId  }
     Assert-True { $v.RecoveryResourceGroupId -eq $RecoveryResourceGroupId }
}


function Test-NewAsrFabric {
    $seed = 35;
        $vaultRgLocation = getVaultRgLocation
        $vaultName = getVaultName
        $vaultLocation = getVaultLocation
        $vaultRg = getVaultRg
        $primaryLocation = getPrimaryLocation
        $recoveryLocation = getRecoveryLocation
        $primaryFabricName = getPrimaryFabric
        $recoveryFabricName = getRecoveryFabric
        
        New-AzResourceGroup -name $vaultRg -location $vaultRgLocation -force
        [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(20 * 1000)
    
        New-AzRecoveryServicesVault -ResourceGroupName $vaultRg -Name $vaultName -Location $vaultLocation
        [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(20 * 1000)
        $Vault = Get-AzRecoveryServicesVault -ResourceGroupName $vaultRg -Name $vaultName
        Set-ASRVaultContext -Vault $Vault
    
        
        $fabJob=  New-AzRecoveryServicesAsrFabric -Azure -Name $primaryFabricName -Location $primaryLocation
        WaitForJobCompletion -JobId $fabJob.Name
        $fab = Get-AzRecoveryServicesAsrFabric -Name $primaryFabricName
        Assert-true { $fab.name -eq $primaryFabricName }
        Assert-AreEqual $fab.FabricSpecificDetails.Location $primaryLocation
}


function Test-NewContainer{

    $seed = 33;
    $primaryPolicyName = getPrimaryPolicy
        $recoveryPolicyName = getRecoveryPolicy
        
        $primaryContainerMappingName = getPrimaryContainerMapping
        $recoveryContainerMappingName = getRecoveryContainerMapping
        
        $primaryContainerName = getPrimaryContainer
        $recoveryContainerName = getRecoveryContainer
        $vaultRgLocation = getVaultRgLocation
        $vaultName = getVaultName
        $vaultLocation = getVaultLocation
        $vaultRg = getVaultRg
        $primaryLocation = getPrimaryLocation
        $recoveryLocation = getRecoveryLocation
        $primaryFabricName = getPrimaryFabric
        $recoveryFabricName = getRecoveryFabric
        $RecoveryReplicaDiskAccountType = "Premium_LRS"
        $RecoveryTargetDiskAccountType = "Premium_LRS"

        New-AzResourceGroup -name $vaultRg -location $vaultRgLocation -force
        [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(20 * 1000)
    
        New-AzRecoveryServicesVault -ResourceGroupName $vaultRg -Name $vaultName -Location $vaultLocation
        [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(20 * 1000)
        $Vault = Get-AzRecoveryServicesVault -ResourceGroupName $vaultRg -Name $vaultName
        Set-ASRVaultContext -Vault $Vault
    
        
        $fabJob=  New-AzRecoveryServicesAsrFabric -Azure -Name $primaryFabricName -Location $primaryLocation
        WaitForJobCompletion -JobId $fabJob.Name
        $fab = Get-AzRecoveryServicesAsrFabric -Name $primaryFabricName
        Assert-true { $fab.name -eq $primaryFabricName }
        Assert-AreEqual $fab.FabricSpecificDetails.Location $primaryLocation

        $fabJob=  New-AzRecoveryServicesAsrFabric -Azure -Name $recoveryFabricName -Location $recoveryLocation
        WaitForJobCompletion -JobId $fabJob.Name
        $fab = Get-AzRecoveryServicesAsrFabric -Name $recoveryFabricName
        Assert-true { $fab.name -eq $recoveryFabricName }
        Assert-AreEqual $fab.FabricSpecificDetails.Location $recoveryLocation
        $pf = get-asrFabric -Name $primaryFabricName
        $rf = get-asrFabric -Name $recoveryFabricName
        
        
        $job = New-AzRecoveryServicesAsrProtectionContainer -Name $primaryContainerName -Fabric $pf
        WaitForJobCompletion -JobId $Job.Name
        $pc = Get-asrProtectionContainer -name $primaryContainerName -Fabric $pf
        Assert-NotNull($pc)
        Assert-AreEqual $pc.Name $primaryContainerName

}