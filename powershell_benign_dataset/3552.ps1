













$containerName = "pstestwlvm1bca8"
$resourceGroupName = "pstestwlRG1bca8"
$vaultName = "pstestwlRSV1bca8"
$resourceId = "/subscriptions/da364f0f-307b-41c9-9d47-b7413ec45535/resourceGroups/pstestwlRG1bca8/providers/Microsoft.Compute/virtualMachines/pstestwlvm1bca8"

function Get-AzureVmWorkloadContainer
{
   try
   {
      $vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName

	  
      $container = Register-AzRecoveryServicesBackupContainer `
         -ResourceId $resourceId `
         -BackupManagementType AzureWorkload `
         -WorkloadType MSSQL `
         -VaultId $vault.ID `
		 -Force
	  Assert-AreEqual $container.Status "Registered"

      
      $containers = Get-AzRecoveryServicesBackupContainer `
         -VaultId $vault.ID `
         -ContainerType AzureVMAppContainer `
         -Status Registered;
      Assert-True { $containers.FriendlyName -contains $containerName }

      
      $containers = Get-AzRecoveryServicesBackupContainer `
         -VaultId $vault.ID `
         -ContainerType AzureVMAppContainer `
         -Status Registered `
         -FriendlyName $containerName;
      Assert-True { $containers.FriendlyName -contains $containerName }

      
      $containers = Get-AzRecoveryServicesBackupContainer `
         -VaultId $vault.ID `
         -ContainerType AzureVMAppContainer `
         -Status Registered `
         -ResourceGroupName $resourceGroupName;
      Assert-True { $containers.FriendlyName -contains $containerName }
   
      
      $containers = Get-AzRecoveryServicesBackupContainer `
         -VaultId $vault.ID `
         -ContainerType AzureVMAppContainer `
         -Status Registered `
         -FriendlyName $containerName `
         -ResourceGroupName $resourceGroupName;
      Assert-True { $containers.FriendlyName -contains $containerName }
   }
   finally
   {
	  
      Unregister-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-Container $containers
   }
}

function Unregister-AzureWorkloadContainer
{
      $vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName

	  
      $container = Register-AzRecoveryServicesBackupContainer `
         -ResourceId $resourceId `
         -BackupManagementType AzureWorkload `
         -WorkloadType MSSQL `
         -VaultId $vault.ID `
		 -Force
	  Assert-AreEqual $container.Status "Registered"

	  
      Get-AzRecoveryServicesBackupContainer `
         -VaultId $vault.ID `
         -ContainerType AzureVMAppContainer `
         -Status Registered `
         -FriendlyName $containerName | Unregister-AzRecoveryServicesBackupContainer -VaultId $vault.ID

	  $container = Get-AzRecoveryServicesBackupContainer `
         -VaultId $vault.ID `
         -ContainerType AzureVMAppContainer `
         -Status Registered `
         -FriendlyName $containerName
      Assert-Null $container
}