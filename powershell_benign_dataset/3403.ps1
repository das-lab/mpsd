

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
