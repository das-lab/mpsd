














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
