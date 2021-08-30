














function Test-VirtualMachineExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk3' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;
        $p = Remove-AzureRmVMDataDisk -VM $p -Name 'testDataDisk3';
        
        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $extver = '1.1';

        
        $settingstr = '{"fileUris":[],"commandToExecute":"powershell Get-Process"}';
        $protectedsettingstr = '{"storageAccountName":"' + $stoname + '","storageAccountKey":"' + $stokey + '"}';
        Set-AzureRmVMExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -Publisher $publisher -ExtensionType $exttype -TypeHandlerVersion $extver -SettingString $settingstr -ProtectedSettingString $protectedsettingstr;

        
        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        Assert-NotNull $ext.SubStatuses;

        
        $ext | Remove-AzureRmVMExtension -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-VirtualMachineExtensionUsingHashTable
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk3' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;
        $p = Remove-AzureRmVMDataDisk -VM $p -Name 'testDataDisk3';
        
        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $extver = '1.1';

        
        $settings = @{"fileUris" = @(); "commandToExecute" = "powershell Get-Process"};
        $protectedsettings = @{"storageAccountName" = $stoname; "storageAccountKey" = $stokey};
        Set-AzureRmVMExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -Publisher $publisher -ExtensionType $exttype -TypeHandlerVersion $extver -Settings $settings -ProtectedSettings $protectedsettings;

        
        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Write-Verbose("Get-AzureRmVM: ");
        $a = $vm1 | Out-String;
        Write-Verbose($a);

        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 2;
        Assert-AreEqual $vm1.Extensions[1].Name $extname;
        Assert-AreEqual $vm1.Extensions[1].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[1].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[1].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[1].TypeHandlerVersion $extver;
        Assert-NotNull $vm1.Extensions[1].Settings;

        
        Remove-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineCustomScriptExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $fileToExecute = 'a.exe';
        $containerName = 'script';

        
        Assert-ThrowsContains { `
            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -TypeHandlerVersion $extver -StorageAccountName $stoname -StorageAccountKey $stokey `
            -FileName $fileToExecute -ContainerName $containerName; } `
            "Failed to download all specified files";

        
        $ext = Get-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;

        $expCommand = 'powershell -ExecutionPolicy Unrestricted -file ' + $fileToExecute + ' ';
        $expUri = $stoname + '.blob.core.windows.net/' + $containerName + '/' + $fileToExecute;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-True {$ext.Uri[0].Contains($expUri)};
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-True {$ext.Uri[0].Contains($expUri)};
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 2;
        Assert-AreEqual $vm1.Extensions[1].Name $extname;
        Assert-AreEqual $vm1.Extensions[1].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[1].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[1].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[1].TypeHandlerVersion $extver;
        Assert-NotNull $vm1.Extensions[1].Settings;

        
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineCustomScriptExtensionWrongStorage
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $fileToExecute = 'a.exe';
        $containerName = 'script';

        
        Assert-ThrowsContains { `
            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -TypeHandlerVersion $extver -StorageAccountName "abc" `
            -FileName $fileToExecute -ContainerName $containerName; } `
            "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineCustomScriptExtensionSecureExecution
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $fileToExecute = 'a.exe';
        $containerName = 'script';

        
        Assert-ThrowsContains { `
            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
                -Name $extname -TypeHandlerVersion $extver `
                -StorageAccountName $stoname -StorageAccountKey $stokey `
                -FileName $fileToExecute -ContainerName $containerName -SecureExecution; } `
            "Failed to download all specified files";

        
        $ext = Get-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;

        $expCommand = 'powershell -ExecutionPolicy Unrestricted -file ' + $fileToExecute + ' ';
        $expUri = $stoname + '.blob.core.windows.net/' + $containerName + '/' + $fileToExecute;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-Null $ext.CommandToExecute;
        Assert-True {$ext.Uri[0].Contains($expUri)};
        Assert-NotNull $ext.ProvisioningState;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineCustomScriptExtensionFileUri
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $containerName = 'scripts';
        $fileToExecute = 'test1.ps1';
        $duration = New-Object -TypeName TimeSpan(2,0,0);
        $type = [Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions]::Read;

        $sasFile1 = Get-SasUri $stoname $stokey $containerName $fileToExecute $duration $type;
        $sasFile2 = Get-SasUri $stoname $stokey $containerName $fileToExecute $duration $type;

        
        Assert-ThrowsContains { `
            Set-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -TypeHandlerVersion $extver -Run $fileToExecute -FileUri $sasFile1, $sasFile2; } `
            "Failed to download all specified files";

        
        $ext = Get-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;

        $expCommand = 'powershell -ExecutionPolicy Unrestricted -file ' + $fileToExecute+ ' ';
        $expUri = $stoname + '.blob.core.windows.net/' + $containerName + '/' + $fileToExecute;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-True {$ext.Uri[0].Contains($expUri)};
        Assert-True {$ext.Uri[1].Contains($expUri)};
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzureRmVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-True {$ext.Uri[0].Contains($expUri)};
        Assert-True {$ext.Uri[1].Contains($expUri)};
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 2;
        Assert-AreEqual $vm1.Extensions[1].Name $extname;
        Assert-AreEqual $vm1.Extensions[1].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[1].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[1].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[1].TypeHandlerVersion $extver;
        Assert-NotNull $vm1.Extensions[1].Settings;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineAccessExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $extver = '2.0';
        $user2 = "Bar12";
        $password2 = 'FoO@123' + $rgname;

        
        Set-AzureRmVMAccessExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -TypeHandlerVersion $extver -UserName $user2 -Password $password2;

        $publisher = 'Microsoft.Compute';
        $exttype = 'VMAccessAgent';

        
        $ext = Get-AzureRmVMAccessExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.UserName $user2;
        Assert-NotNull $ext.ProvisioningState;
        Assert-True {$ext.PublicSettings.Contains("UserName")};

        $ext = Get-AzureRmVMAccessExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        Assert-True {$ext.PublicSettings.Contains("UserName")};

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 2;
        Assert-AreEqual $vm1.Extensions[1].Name $extname;
        Assert-AreEqual $vm1.Extensions[1].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[1].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[1].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[1].TypeHandlerVersion $extver;
        Assert-NotNull $vm1.Extensions[1].Settings;

        
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AzureDiskEncryptionExtension
{
    
    
    $aadAppName = "detestaadapp";

    
    $rgName = Get-ComputeTestResourceName;
    $loc = Get-ComputeVMLocation;

    
    $adminUser = "Foo12";
    $adminPassword = $PLACEHOLDER;

    
    $vaultName = "detestvault";
    $kekName = "dstestkek";

    
    $vmName = "detestvm";
    $vmsize = 'Standard_D2';
    $imagePublisher = "MicrosoftWindowsServer";
    $imageOffer = "WindowsServer";
    $imageSku ="2012-R2-Datacenter";

    
    $storageAccountName = "deteststore";
    $stotype = 'Standard_LRS';
    $vhdContainerName = "vhds";
    $osDiskName = 'osdisk' + $vmName;
    $dataDiskName = 'datadisk' + $vmName;
    $osDiskCaching = 'ReadWrite';
    $extraDataDiskName1 = $dataDiskName + '1';
    $extraDataDiskName2 = $dataDiskName + '2';

    
    $vnetName = "detestvnet";
    $subnetName = "detestsubnet";
    $publicIpName = 'pubip' + $vmName;
    $nicName = 'nic' + $vmName;

    
    $keyEncryptionAlgorithm = "RSA-OAEP";
    $volumeType = "All";

    try
    {
        
        New-AzureRmResourceGroup -Name $rgName -Location $loc -Force;

        
        $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);
        if(-not $SvcPrincipals)
        {
            
            $identifierUri = [string]::Format("http://localhost:8080/{0}", $rgname);
            $defaultHomePage = 'http://contoso.com';
            $now = [System.DateTime]::Now;
            $oneYearFromNow = $now.AddYears(1);
            $aadClientSecret = Get-ResourceName;
            $ADApp = New-AzureRmADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $aadClientSecret;
            Assert-NotNull $ADApp;
            $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $ADApp.ApplicationId;
            $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);
            
            Assert-NotNull $SvcPrincipals;
            $aadClientID = $servicePrincipal.ApplicationId;
        }
        else
        {
            
            Assert-NotNull $aadClientSecret;
            $aadClientID = $SvcPrincipals[0].ApplicationId;
        }

        
        $keyVault = New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $rgname -Location $loc -Sku standard;
        $keyVault = Get-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $rgname
        
        Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ResourceGroupName $rgname -EnabledForDiskEncryption;
        
        Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName $aadClientID -PermissionsToKeys all -PermissionsToSecrets all 
        
        $kek = Add-AzureKeyVaultKey -VaultName $vaultName -Name $kekName -Destination "Software"

        $diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
        $keyVaultResourceId = $keyVault.ResourceId;
        $keyEncryptionKeyUrl = $kek.Key.kid;

        
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;

        
        $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name ($subnetName) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzureRmVirtualNetwork -Force -Name ($vnetName) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzureRmVirtualNetwork -Name ($vnetName) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;
        $pubip = New-AzureRmPublicIpAddress -Force -Name ($publicIpName) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ($publicIpName);
        $pubip = Get-AzureRmPublicIpAddress -Name ($publicIpName) -ResourceGroupName $rgname;
        $pubipId = $pubip.Id;
        $nic = New-AzureRmNetworkInterface -Force -Name ($nicName) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzureRmNetworkInterface -Name ($nicName) -ResourceGroupName $rgname;
        $nicId = $nic.Id;

        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId;

        
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $storageAccountName -Location $loc -Type $stotype;
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $storageAccountName).Key1;

        $osDiskVhdUri = "https://$storageAccountName.blob.core.windows.net/$vhdContainerName/$osDiskName.vhd";
        $dataDiskVhdUri = "https://$storageAccountName.blob.core.windows.net/$vhdContainerName/$dataDiskName.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name $dataDiskName -Caching 'ReadOnly' -DiskSizeInGB 2 -Lun 1 -VhdUri $dataDiskVhdUri -CreateOption Empty;

        
        $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($adminUser, $securePassword);
        $computerName = $vmName;
        $vhdContainer = "https://$storageAccountName.blob.core.windows.net/$vhdContainerName";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version "latest";

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;

        
        $p = Add-AzureRmVMDataDisk -VM $p -Name $extraDataDiskName1 -Caching 'ReadOnly' -DiskSizeInGB 2 -Lun 1 -VhdUri $dataDiskVhdUri -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name $extraDataDiskName2 -Caching 'ReadOnly' -DiskSizeInGB 2 -Lun 1 -VhdUri $dataDiskVhdUri -CreateOption Empty;
        
        Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;

        
        Disable-AzureRmVMDiskEncryption -ResourceGroupName $rgname -VMName $vmName;
        
        $encryptionStatus = Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $p.StorageProfile.OSDisk.Name;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $false;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $false;

        
        Remove-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName;
        
        $encryptionStatus = Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $false;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $false;

        
        Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;

        
        Remove-AzureRmVm -ResourceGroupName $rgname -Name $vmName -Force;

        
        $p.StorageProfile.ImageReference = $null;
        $p.OSProfile = $null;
        $p.StorageProfile.DataDisks = $null;
        $p = Set-AzureRmVMOSDisk -VM $p -Name $p.StorageProfile.OSDisk.Name -VhdUri $p.StorageProfile.OSDisk.Vhd.Uri -Caching ReadWrite -CreateOption attach -DiskEncryptionKeyUrl $encryptionStatus.OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl -DiskEncryptionKeyVaultId $encryptionStatus.OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault.Id -Windows;

        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
        
    }
}


function Test-VirtualMachineBginfoExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p -DisableBginfoExtension;

        $vm1 = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        $extname = 'csetest';
        $extver = '2.1';

        
        Set-AzureRmVMBginfoExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -TypeHandlerVersion $extver;

        $publisher = 'Microsoft.Compute';
        $exttype = 'BGInfo';

        
        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.UserName $user2;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        

        
        $vm1 = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 1;
        Assert-AreEqual $vm1.Extensions[0].Name $extname;
        Assert-AreEqual $vm1.Extensions[0].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[0].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[0].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[0].TypeHandlerVersion $extver;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineExtensionWithSwitch
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        
        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $extver = '1.1';

        
        $settingstr = '{"fileUris":[],"commandToExecute":""}';
        $protectedsettingstr = '{"storageAccountName":"' + $stoname + '","storageAccountKey":"' + $stokey + '"}';
        Set-AzureRmVMExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -Publisher $publisher `
            -ExtensionType $exttype -TypeHandlerVersion $extver -SettingString $settingstr -ProtectedSettingString $protectedsettingstr `
            -DisableAutoUpgradeMinorVersion -ForceRerun "RerunExtension";

        
        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-False{$ext.AutoUpgradeMinorVersion};
        Assert-AreEqual $ext.ForceUpdateTag "RerunExtension";

        $ext = Get-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        Assert-NotNull $ext.SubStatuses;

        
        Remove-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineADDomainExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $extver = '1.3';
        $domainName = "Workgroup2"

        
        Set-AzureRmVMADDomainExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -DomainName $domainName;

        $publisher = 'Microsoft.Compute';
        $exttype = 'JsonADDomainExtension';

        
        $ext = Get-AzureRmVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;

        
        Assert-AreEqual $domainName $ext.DomainName;
        Assert-Null $ext.OUPath;
        Assert-Null $ext.User;
        Assert-AreEqual 0 $ext.JoinOption;
        Assert-False {$ext.Restart};

        $ext = Get-AzureRmVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        Assert-AreEqual $domainName $ext.DomainName;
        Assert-Null $ext.OUPath;
        Assert-Null $ext.User;
        Assert-AreEqual 0 $ext.JoinOption;
        Assert-False {$ext.Restart};

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 2;
        Assert-AreEqual $vm1.Extensions[1].Name $extname;
        Assert-AreEqual $vm1.Extensions[1].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[1].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[1].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[1].TypeHandlerVersion $extver;
        Assert-NotNull $vm1.Extensions[1].Settings;

        Remove-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineADDomainExtensionDomainJoin
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $stoname).Key1;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $extver = '1.3';
        $domainName = "dom123.com";
        $user2 = 'dom123.com\Bar12';
        $password2 = $PLACEHOLDER;
        $securePassword2 = ConvertTo-SecureString $password2 -AsPlainText -Force;
        $cred2 = New-Object System.Management.Automation.PSCredential ($user2, $securePassword2);
        $ouPath = "OU=testOU,DC=domain,DC=Domain,DC=com";

        
        Assert-ThrowsContains { Set-AzureRmVMADDomainExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname `
            -DomainName $domainName -Credential $cred2 -OUPath $ouPath -JoinOption 3 -Restart; } `
            "occurred while joining Domain";
        $publisher = 'Microsoft.Compute';
        $exttype = 'JsonADDomainExtension';

        
        $ext = Get-AzureRmVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;

        
        Assert-AreEqual $domainName $ext.DomainName;
        Assert-AreEqual $ouPath $ext.OUPath;
        Assert-AreEqual $user2 $ext.User;
        Assert-AreEqual 3 $ext.JoinOption;
        Assert-True {$ext.Restart};

        $ext = Get-AzureRmVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        Assert-AreEqual $domainName $ext.DomainName;
        Assert-AreEqual $ouPath $ext.OUPath;
        Assert-AreEqual $user2 $ext.User;
        Assert-AreEqual 3 $ext.JoinOption;
        Assert-True {$ext.Restart};

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        Assert-AreEqual $vm1.Extensions.Count 2;
        Assert-AreEqual $vm1.Extensions[1].Name $extname;
        Assert-AreEqual $vm1.Extensions[1].Type 'Microsoft.Compute/virtualMachines/extensions';
        Assert-AreEqual $vm1.Extensions[1].Publisher $publisher;
        Assert-AreEqual $vm1.Extensions[1].VirtualMachineExtensionType $exttype;
        Assert-AreEqual $vm1.Extensions[1].TypeHandlerVersion $extver;
        Assert-NotNull $vm1.Extensions[1].Settings;

        Remove-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
