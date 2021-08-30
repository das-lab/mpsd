

function Test-SetAzureRmVMSqlServerAKVExtension
{
    Set-StrictMode -Version latest; $ErrorActionPreference = 'Stop'

    
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    
    New-AzResourceGroup -Name $rgname -Location $loc -Force;

    
    $vmsize = 'Standard_A2';
    $vmname = 'vm' + $rgname;
    $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize;
    Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

    
    $subnet = New-AzVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
    $vnet = New-AzVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
    $vnet = Get-AzVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
    $subnetId = $vnet.Subnets[0].Id;
    $pubip = New-AzPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
    $pubip = Get-AzPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
    $pubipId = $pubip.Id;
    $nic = New-AzNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
    $nic = Get-AzNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
    $nicId = $nic.Id;

    $p = Add-AzVMNetworkInterface -VM $p -Id $nicId;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

    
    $stoname = 'sto' + $rgname;
    $stotype = 'Standard_GRS';
    New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    Retry-IfException { $global:stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname; }

    $osDiskName = 'osDisk';
    $osDiskCaching = 'ReadWrite';
    $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
    $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

    $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
    $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

    
    $user = "localadmin";
    $password = $PLACEHOLDER;
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
    $computerName = 'test';
    $vhdContainer = "https://$stoname.blob.core.windows.net/test";

    $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
    $p = Set-AzVMSourceImage -VM $p -PublisherName MicrosoftSQLServer -Offer SQL2014SP2-WS2012R2 -Skus Enterprise -Version "latest"

    
    New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

    

    $extensionName = "SqlIaaSExtension";

    

    $securepfxpwd = ConvertTo-SecureString –String "Amu6y/RzJcc7JBzdAdRVv6mk=" –AsPlainText –Force;
    $aps_akv = New-AzVMSqlServerKeyVaultCredentialConfig -ResourceGroupName $rgname -Enable -CredentialName "CredentialTesting" -AzureKeyVaultUrl "https://Testkeyvault.vault.azure.net/" -ServicePrincipalName "0326921f-bf005595337c" -ServicePrincipalSecret $securepfxpwd;
    Set-AzVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose; 

    
    $extension = Get-AzVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;

    

    Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials.Count 1;
	Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials[0].CredentialName "CredentialTesting"

    

    $aps_akv = New-AzVMSqlServerKeyVaultCredentialConfig -ResourceGroupName $rgname -Enable -CredentialName "CredentialTest" -AzureKeyVaultUrl "https://Testkeyvault.vault.azure.net/" -ServicePrincipalName "0326921f-82af-4ab3-9d46-bf005595337c" -ServicePrincipalSecret $securepfxpwd;
    Set-AzVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose; 

    
    $extension = Get-AzVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;
		
    Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials.Count 2;
	Assert-AreEqual $extension.KeyVaultCredentialSettings.Credentials[1].CredentialName "CredentialTest"

    

    Set-AzVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv  -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.2"

    
    Set-AzVMSqlServerExtension -KeyVaultCredentialSettings $aps_akv  -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.*"
}

function Test-SetAzureRmVMSqlServerExtension
{
    Set-StrictMode -Version latest; $ErrorActionPreference = 'Stop'

    
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation

    
    New-AzResourceGroup -Name $rgname -Location $loc -Force;

    
    $vmsize = 'Standard_A2';
    $vmname = 'vm' + $rgname;
    $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize;
    Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

    
    $subnet = New-AzVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
    $vnet = New-AzVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
    $vnet = Get-AzVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
    $subnetId = $vnet.Subnets[0].Id;
    $pubip = New-AzPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
    $pubip = Get-AzPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
    $pubipId = $pubip.Id;
    $nic = New-AzNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
    $nic = Get-AzNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
    $nicId = $nic.Id;

    $p = Add-AzVMNetworkInterface -VM $p -Id $nicId;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

    
    $stoname = 'sto' + $rgname;
    $stotype = 'Standard_GRS';
    New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    Retry-IfException { $global:stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname; }

    $osDiskName = 'osDisk';
    $osDiskCaching = 'ReadWrite';
    $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
    $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

    $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
    $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

    
    $user = "localadmin";
    $password = $PLACEHOLDER;
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
    $computerName = 'test';
    $vhdContainer = "https://$stoname.blob.core.windows.net/test";

    $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
    $p = Set-AzVMSourceImage -VM $p -PublisherName MicrosoftSQLServer -Offer SQL2014SP2-WS2012R2 -Skus Enterprise -Version "latest"

    
    New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

    

    $extensionName = "SqlIaaSExtension";

    
    $aps = New-AzVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Thursday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
	$storageBlobUrl = "https://$stoname.blob.core.windows.net";
	$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;
	$storageKeyAsSecureString = ConvertTo-SecureString -String $storageKey -AsPlainText -Force;
	$abs = New-AzVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 5 -ResourceGroupName $rgname -StorageUri $storageBlobUrl -StorageKey $storageKeyAsSecureString
    Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

    
    $extension = Get-AzVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;

    
    Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Thursday"
    Assert-AreEqual $extension.AutoPatchingSettings.MaintenanceWindowStartingHour 20
    Assert-AreEqual $extension.AutoPatchingSettings.MaintenanceWindowDuration 120
    Assert-AreEqual $extension.AutoPatchingSettings.PatchCategory "Important"

	Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 5
    Assert-AreEqual $extension.AutoBackupSettings.Enable $true

    
    $aps = New-AzVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Monday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
    $abs = New-AzVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 10 -ResourceGroupName $rgname -StorageUri $storageBlobUrl -StorageKey $storageKeyAsSecureString
	Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs  -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

    

    $extension = Get-AzVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;
    Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Monday"
	Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 10

    
    Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.2"

    
    Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.*"

}


function Test-SetAzureRmVMSqlServerExtensionWith2016Image
{
    Set-StrictMode -Version latest; $ErrorActionPreference = 'Stop'

    
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation
   
   
    New-AzResourceGroup -Name $rgname -Location $loc -Force;

    
    $vmsize = 'Standard_A2';
    $vmname = 'vm' + $rgname;
    $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize;
    Assert-AreEqual $p.HardwareProfile.VmSize $vmsize;

    
    $subnet = New-AzVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
    $vnet = New-AzVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
    $vnet = Get-AzVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
    $subnetId = $vnet.Subnets[0].Id;
    $pubip = New-AzPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
    $pubip = Get-AzPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
    $pubipId = $pubip.Id;
    $nic = New-AzNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
    $nic = Get-AzNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
    $nicId = $nic.Id;

    $p = Add-AzVMNetworkInterface -VM $p -Id $nicId;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
    Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;

    
    $stoname = 'sto' + $rgname;
    $stotype = 'Standard_GRS';
    New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    Retry-IfException { $global:stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname; }

    $osDiskName = 'osDisk';
    $osDiskCaching = 'ReadWrite';
    $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
    $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

    $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
    $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

    
    $user = "localadmin";
    $password = $PLACEHOLDER;
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
    $computerName = 'test';
    $vhdContainer = "https://$stoname.blob.core.windows.net/test";

    $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
    $p = Set-AzVMSourceImage -VM $p -PublisherName MicrosoftSQLServer -Offer SQL2016-WS2012R2 -Skus Enterprise -Version "latest"

    
    New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

    

    $extensionName = "Microsoft.SqlServer.Management.SqlIaaSAgent";

    
    $aps = New-AzVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Thursday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
	$storageBlobUrl = "https://$stoname.blob.core.windows.net";
	$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;
	$storageKeyAsSecureString = ConvertTo-SecureString -String $storageKey -AsPlainText -Force;
	$abs = New-AzVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 5 -ResourceGroupName $rgname -StorageUri $storageBlobUrl -StorageKey $storageKeyAsSecureString `
		-BackupScheduleType Manual -BackupSystemDbs -FullBackupStartHour 10 -FullBackupWindowInHours 5 -FullBackupFrequency Daily -LogBackupFrequencyInMinutes 30
    Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

    
    $extension = Get-AzVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;

    
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

    
    $aps = New-AzVMSqlServerAutoPatchingConfig -Enable -DayOfWeek "Monday" -MaintenanceWindowStartingHour 20 -MaintenanceWindowDuration 120 -PatchCategory "Important"
    $abs = New-AzVMSqlServerAutoBackupConfig -Enable -RetentionPeriodInDays 10 -ResourceGroupName $rgname -StorageUri $storageBlobUrl `
			-StorageKey $storageKeyAsSecureString -BackupScheduleType Automated
	Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmname -Version "1.2" -Verbose -Name $extensionName;

    
    $extension = Get-AzVMSqlServerExtension -ResourceGroupName $rgname -VmName $vmName -Name $extensionName;
    Assert-AreEqual $extension.AutoPatchingSettings.DayOfWeek "Monday"
	Assert-AreEqual $extension.AutoBackupSettings.RetentionPeriod 10
    Assert-AreEqual $extension.AutoBackupSettings.Enable $true
    Assert-AreEqual $extension.AutoBackupSettings.BackupScheduleType "Automated"

    
    Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.2"

    
    Set-AzVMSqlServerExtension -AutoPatchingSettings $aps -AutoBackupSettings $abs -ResourceGroupName $rgname -VMName $vmName -Name $extensionName -Version "1.*"
}


function Get-DefaultResourceGroupLocation
{
    if ((Get-ComputeTestMode) -ne 'Playback')
    {
        $namespace = "Microsoft.Resources"
        $type = "resourceGroups"
        $location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

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
