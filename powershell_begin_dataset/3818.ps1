














function Test-VirtualMachineScaleSetDiskEncryptionExtension
{
    
    [string]$loc = Get-ComputeVMLocation;
    $loc = $loc.Replace(' ', '');
    $rgname = 'adetstrg';
    $vmssName = 'vmssadetst';
    $keyVaultResourceId = '/subscriptions/5393f919-a68a-43d0-9063-4b2bda6bffdf/resourceGroups/suredd-rg/providers/Microsoft.KeyVault/vaults/sureddeuvault';
    $diskEncryptionKeyVaultUrl = 'https://sureddeuvault.vault.azure.net';

    $vmssResult = Get-AzVmss -ResourceGroupName $rgname -VMScaleSetName $vmssName;

    
    $vmssInstanceViewResult = Get-AzVmss -ResourceGroupName $rgname -VMScaleSetName $vmssName -InstanceView;

    
    Set-AzVmssDiskEncryptionExtension -ResourceGroupName $rgname -VMScaleSetName $vmssName `
        -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -Force

    
    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $result_string = $result | Out-String;
         
    
    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $result_string = $result | Out-String;
}


function Test-DisableVirtualMachineScaleSetDiskEncryption
{
    
    [string]$loc = Get-ComputeVMLocation;
    $loc = $loc.Replace(' ', '');
    $rgname = 'adetstrg';
    $vmssName = 'vmssadetst';

    $result = Get-AzVmssDiskEncryption;
    $result_string = $result | Out-String;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname;
    $result_string = $result | Out-String;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $result_string = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $result_string = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName -InstanceId 4;
    $result_string = $result | Out-String;

    $result = Disable-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName -Force;
    $result_string = $result | Out-String;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname;
    $result_string = $result | Out-String;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $result_string = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $result_string = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName -InstanceId 4;
    $result_string = $result | Out-String;
}


function Test-DisableVirtualMachineScaleSetDiskEncryption2
{
    
    [string]$loc = Get-ComputeVMLocation;
    $loc = $loc.Replace(' ', '');
    $rgname = 'adetst2rg';
    $vmssName = 'vmssadetst2';

    $result = Disable-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName -Force;
    $result_string = $result | Out-String;
}


function Test-GetVirtualMachineScaleSetDiskEncryptionStatus
{
    
    [string]$loc = Get-ComputeVMLocation;
    $loc = $loc.Replace(' ', '');
    $rgname = 'adetst3rg';
    $vmssName = 'vmssadetst3';

    $vmssResult = Get-AzVmss -ResourceGroupName $rgname -VMScaleSetName $vmssName;

    $vmssInstanceViewResult = Get-AzVmss -ResourceGroupName $rgname -VMScaleSetName $vmssName -InstanceView;
    $output = $vmssInstanceViewResult | Out-String;

    $result = Get-AzVmssDiskEncryptionStatus -ResourceGroupName $rgname;
    $output = $result | Out-String;

    $result = Get-AzVmssDiskEncryptionStatus -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $output = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryptionStatus -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $output = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryptionStatus -ResourceGroupName $rgname -VMScaleSetName $vmssName -InstanceId "7";
    $output = $result | Out-String;
}


function Test-GetVirtualMachineScaleSetDiskEncryptionDataDisk
{
    $rgname = 'adetst4rg';
    $vmssName = 'vmssadetst4';

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname;
    $output = $result | Out-String;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $output = $result | Out-String;

    $job = Disable-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName -Force -AsJob;
    $result = $job | Wait-Job;
    Assert-AreEqual "Completed" $result.State;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname;
    $output = $result | Out-String;

    $result = Get-AzVmssDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    $output = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName;
    Assert-AreEqual "NotEncrypted" $result[0].DataVolumesEncrypted;
    $output = $result | Out-String;

    $result = Get-AzVmssVMDiskEncryption -ResourceGroupName $rgname -VMScaleSetName $vmssName -InstanceId "4";
    Assert-AreEqual "NotEncrypted" $result.DataVolumesEncrypted;
    $output = $result | Out-String;
}
