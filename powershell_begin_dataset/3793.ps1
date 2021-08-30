














function Test-VirtualMachineExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk3' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;
        $p = Remove-AzVMDataDisk -VM $p -Name 'testDataDisk3';

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $extver = '1.1';

        
        $settingstr = '{"fileUris":[],"commandToExecute":"powershell Get-Process"}';
        $protectedsettingstr = '{"storageAccountName":"' + $stoname + '","storageAccountKey":"' + $stokey + '"}';
        $job = Set-AzVMExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -Publisher $publisher -ExtensionType $exttype -TypeHandlerVersion $extver -SettingString $settingstr -ProtectedSettingString $protectedsettingstr -AsJob
        $job | Wait-Job

        
        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        Assert-NotNull $ext.SubStatuses;

        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname
        Assert-True { $ext.Count -ge 1 }
        Assert-Null $ext[0].Statuses

        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Status
        Assert-NotNull $ext.Statuses

        
        $ext | Remove-AzVMExtension -Force;
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk3' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;
        $p = Remove-AzVMDataDisk -VM $p -Name 'testDataDisk3';

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $extver = '1.1';

        
        $settings = @{"fileUris" = @(); "commandToExecute" = "powershell Get-Process"};
        $protectedsettings = @{"storageAccountName" = $stoname; "storageAccountKey" = $stokey};
        Set-AzVMExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -Publisher $publisher -ExtensionType $exttype -TypeHandlerVersion $extver -Settings $settings -ProtectedSettings $protectedsettings;

        
        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;
        Write-Verbose("Get-AzVM: ");
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

        
        Remove-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Force;
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $fileToExecute = 'a.exe';
        $containerName = 'script';

        
        Assert-ThrowsContains { `
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -TypeHandlerVersion $extver -StorageAccountName $stoname -StorageAccountKey $stokey `
            -FileName $fileToExecute -ContainerName $containerName; } `
            "Failed to download all specified files";

        
        $ext = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;

        $expCommand = 'powershell -ExecutionPolicy Unrestricted -file ' + $fileToExecute + ' ';
        $expUri = $stoname + '.blob.core.windows.net/' + $containerName + '/' + $fileToExecute;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;
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

function Test-VirtualMachineCustomScriptExtensionPiping
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        $vmname = 'vm' + $rgname;
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        [string]$domainNameLabel = "$vmname-$vmname".tolower();
        $vmobject = New-AzVm -Name $vmname -ResourceGroupName $rgname -Credential $cred -DomainNameLabel $domainNameLabel;

        $csename = "myCustomExtension";
        $fileUri = "https://raw.githubusercontent.com/neilpeterson/nepeters-azure-templates/master/windows-custom-script-simple/support-scripts/Create-File.ps1";
        $runname = "Create-File.ps1";

        
        Set-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $csename `
            -Location $loc -FileUri $fileUri -Run $runname;
        $cseobject = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $csename;

        Assert-NotNull $cseobject;
        Assert-Match $runname $cseobject.CommandToExecute;

        
        $argument = "-NonInteractive";
        $cseobject | Set-AzVMCustomScriptExtension -Argument $argument;
        $cseobject = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $csename;

        Assert-NotNull $cseobject;
        Assert-Match $runname $cseobject.CommandToExecute;
        Assert-Match $argument $cseobject.CommandToExecute;

        
        Set-AzVMCustomScriptExtension -ResourceId $cseobject.Id -Location $loc `
            -FileUri $fileUri -Run $runname;
        $cseobject = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $csename;

        Assert-NotNull $cseobject;
        Assert-Match $runname $cseobject.CommandToExecute;
        Assert-NotMatch $argument $cseobject.CommandToExecute;


        
        $vmobject | Set-AzVMCustomScriptExtension -Name $csename -Location $loc `
            -FileUri $fileUri -Run $runname -Argument $argument;
        $cseobject = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $csename;

        Assert-NotNull $cseobject;
        Assert-Match $runname $cseobject.CommandToExecute;
        Assert-Match $argument $cseobject.CommandToExecute;
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $fileToExecute = 'a.exe';
        $containerName = 'script';

        
        Assert-ThrowsContains { `
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = $rgname + 'ext';
        $extver = '1.1';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $fileToExecute = 'a.exe';
        $containerName = 'script';

        
        Assert-ThrowsContains { `
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
                -Name $extname -TypeHandlerVersion $extver `
                -StorageAccountName $stoname -StorageAccountKey $stokey `
                -FileName $fileToExecute -ContainerName $containerName -SecureExecution; } `
            "Failed to download all specified files";

        
        $ext = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;

        $expCommand = 'powershell -ExecutionPolicy Unrestricted -file ' + $fileToExecute + ' ';
        $expUri = $stoname + '.blob.core.windows.net/' + $containerName + '/' + $fileToExecute;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-Null $ext.CommandToExecute;
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
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
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -TypeHandlerVersion $extver -Run $fileToExecute -FileUri $sasFile1, $sasFile2; } `
            "Failed to download all specified files";

        
        $ext = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;

        $expCommand = 'powershell -ExecutionPolicy Unrestricted -file ' + $fileToExecute+ ' ';
        $expUri = $stoname + '.blob.core.windows.net/' + $containerName + '/' + $fileToExecute;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.CommandToExecute $expCommand;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;
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


function Test-VirtualMachineCustomScriptExtensionLinuxVM
{
    $testMode = Get-ComputeTestMode
    $rgname = Get-ComputeTestResourceName
    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;
        
        $vmsize = 'Standard_D2S_V3';
        $vmname = 'vm' + $rgname;
        $imagePublisher = "RedHat";
        $imageOffer = "RHEL";
        $imageSku = "7.5";
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'linuxOsDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/linuxos.vhd";
        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -Caching $osDiskCaching -CreateOption FromImage -Linux;
        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzVMOperatingSystem -VM $p -Linux -ComputerName $computerName -Credential $cred;
        $p = Set-AzVMSourceImage -VM $p -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version "latest"
        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imageOffer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imagePublisher;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imageSku;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        $csename = "myCustomExtension";
        $fileUri = "https://raw.githubusercontent.com/neilpeterson/nepeters-azure-templates/master/windows-custom-script-simple/support-scripts/Create-File.ps1";
        $runname = "Create-File.ps1";

        Assert-ThrowsContains { `
            Set-AzVMCustomScriptExtension -ResourceGroupName $rgname -VMName $vmname -Name $csename -Location $loc -FileUri $fileUri -Run $runname; } `
            "The current VM is a Linux VM.  Custom script extension can be set only to Windows VM.";
    }
    finally
    {
        Clean-ResourceGroup($rgname)
    }
}


function Test-VirtualMachineAccessExtension
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $extver = '2.0';
        $user2 = "Bar12";
        $password2 = 'FoO@123' + $rgname;
        $securePassword2 = ConvertTo-SecureString $password2 -AsPlainText -Force;

        
        $cred2 = New-Object System.Management.Automation.PSCredential ($user2, $securePassword2);
        Set-AzVMAccessExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -TypeHandlerVersion $extver -Credential $cred2

        $publisher = 'Microsoft.Compute';
        $exttype = 'VMAccessAgent';

        
        $ext = Get-AzVMAccessExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.UserName $user2;
        Assert-NotNull $ext.ProvisioningState;
        Assert-True {$ext.PublicSettings.Contains("UserName")};

        $ext = Get-AzVMAccessExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        Assert-True {$ext.PublicSettings.Contains("UserName")};

        
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;
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


function Test-AzureDiskEncryptionExtensionSinglePass
{
    $resourceGroupName = Get-ComputeTestResourceName
    try
    {
        
        $vm = Create-VirtualMachine $resourceGroupName
        $kv = Create-KeyVault $vm.ResourceGroupName $vm.Location

        
        Set-AzVMDiskEncryptionExtension `
            -ResourceGroupName $vm.ResourceGroupName `
            -VMName $vm.Name `
            -DiskEncryptionKeyVaultUrl $kv.DiskEncryptionKeyVaultUrl `
            -DiskEncryptionKeyVaultId $kv.DiskEncryptionKeyVaultId `
            -Force

        
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted Encrypted
        
        Assert-AreEqual $status.DataVolumesEncrypted Encrypted

        
        $settings = $status.OsVolumeEncryptionSettings
        Assert-NotNull $settings
        Assert-NotNull $settings.DiskEncryptionKey.SecretUrl
        Assert-AreEqual $settings.DiskEncryptionKey.SourceVault.Id $kv.DiskEncryptionKeyVaultId
    }
    finally
    {
        Clean-ResourceGroup($resourceGroupName)
    }
}


function Test-AzureDiskEncryptionExtensionSinglePassRemove
{
    $resourceGroupName = Get-ComputeTestResourceName
    try
    {
        
        $vm = Create-VirtualMachineNoDataDisks $resourceGroupName
        $kv = Create-KeyVault $vm.ResourceGroupName $vm.Location

        
        Set-AzVMDiskEncryptionExtension `
            -ResourceGroupName $vm.ResourceGroupName `
            -VMName $vm.Name `
            -DiskEncryptionKeyVaultUrl $kv.DiskEncryptionKeyVaultUrl `
            -DiskEncryptionKeyVaultId $kv.DiskEncryptionKeyVaultId `
            -Force

        
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted Encrypted
        Assert-AreEqual $status.DataVolumesEncrypted NoDiskFound

        
        $settings = $status.OsVolumeEncryptionSettings
        Assert-NotNull $settings
        Assert-NotNull $settings.DiskEncryptionKey.SecretUrl
        Assert-AreEqual $settings.DiskEncryptionKey.SourceVault.Id $kv.DiskEncryptionKeyVaultId

        
        Remove-AzVmDiskEncryptionExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Force
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted Encrypted
        Assert-AreEqual $status.DataVolumesEncrypted NoDiskFound

        
        $settings = $status.OsVolumeEncryptionSettings
        Assert-NotNull $settings
        Assert-NotNull $settings.DiskEncryptionKey.SecretUrl
        Assert-AreEqual $settings.DiskEncryptionKey.SourceVault.Id $kv.DiskEncryptionKeyVaultId

    }
    finally
    {
        Clean-ResourceGroup($resourceGroupName)
    }
}


function Test-AzureDiskEncryptionExtensionSinglePassDisableAndRemove
{
    $resourceGroupName = Get-ComputeTestResourceName
    try
    {
        
        $vm = Create-VirtualMachine $resourceGroupName
        $kv = Create-KeyVault $vm.ResourceGroupName $vm.Location

        
        Set-AzVMDiskEncryptionExtension `
            -ResourceGroupName $vm.ResourceGroupName `
            -VMName $vm.Name `
            -DiskEncryptionKeyVaultUrl $kv.DiskEncryptionKeyVaultUrl `
            -DiskEncryptionKeyVaultId $kv.DiskEncryptionKeyVaultId `
            -Force

        
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted Encrypted
        Assert-AreEqual $status.DataVolumesEncrypted Encrypted

        
        $settings = $status.OsVolumeEncryptionSettings
        Assert-NotNull $settings
        Assert-NotNull $settings.DiskEncryptionKey.SecretUrl
        Assert-AreEqual $settings.DiskEncryptionKey.SourceVault.Id $kv.DiskEncryptionKeyVaultId

        
        $status = Disable-AzVmDiskEncryption -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Force
        Assert-NotNull $status

        
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted NotEncrypted
        Assert-AreEqual $status.DataVolumesEncrypted NotEncrypted

        
        $settings = $status.OsVolumeEncryptionSettings
        Assert-Null $settings

        
        $status = Remove-AzVmDiskEncryptionExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Force
        Assert-NotNull $status
    }
    finally
    {
        Clean-ResourceGroup($resourceGroupName)
    }
}


function Test-AzureDiskEncryptionExtensionNonDefaultParams
{
    $resourceGroupName = Get-ComputeTestResourceName
    try
    {
        
        $vm = Create-VirtualMachine $resourceGroupName
        $kv = Create-KeyVault $vm.ResourceGroupName $vm.Location

        $extensionPublisher = "Microsoft.Azure.Security.Edp";
        $extensionName = "MyExtension";

        
        Set-AzVMDiskEncryptionExtension `
            -ResourceGroupName $vm.ResourceGroupName `
            -VMName $vm.Name `
            -DiskEncryptionKeyVaultUrl $kv.DiskEncryptionKeyVaultUrl `
            -DiskEncryptionKeyVaultId $kv.DiskEncryptionKeyVaultId `
            -ExtensionPublisherName $extensionPublisher `
            -ExtensionName $extensionName `
            -Force

        
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ExtensionPublisherName $extensionPublisher -ExtensionName $extensionName
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted Encrypted
        Assert-AreEqual $status.DataVolumesEncrypted Encrypted

        
        $settings = $status.OsVolumeEncryptionSettings
        Assert-NotNull $settings
        Assert-NotNull $settings.DiskEncryptionKey.SecretUrl
        Assert-AreEqual $settings.DiskEncryptionKey.SourceVault.Id $kv.DiskEncryptionKeyVaultId

        
        $status = Disable-AzVmDiskEncryption -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ExtensionPublisherName $extensionPublisher -ExtensionName $extensionName -Force
        Assert-NotNull $status

        
        $status = Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ExtensionPublisherName $extensionPublisher -ExtensionName $extensionName
        Assert-NotNull $status
        Assert-AreEqual $status.OsVolumeEncrypted NotEncrypted
        Assert-AreEqual $status.DataVolumesEncrypted NotEncrypted
    }
    finally
    {
        Clean-ResourceGroup($resourceGroupName)
    }
}


function Test-AzureDiskEncryptionLnxManagedDisk
{
    $testMode = Get-ComputeTestMode
    $rgname = Get-ComputeTestResourceName
    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;
        
        $vmsize = 'Standard_D2S_V3';
        $vmname = 'vm' + $rgname;
        $imagePublisher = "RedHat";
        $imageOffer = "RHEL";
        $imageSku = "7.5";
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'linuxOsDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/linuxos.vhd";
        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -Caching $osDiskCaching -CreateOption FromImage -Linux;
        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force; 
        
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzVMOperatingSystem -VM $p -Linux -ComputerName $computerName -Credential $cred;
        $p = Set-AzVMSourceImage -VM $p -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version "latest"
        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imageOffer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imagePublisher;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imageSku;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;
        $kv = Create-KeyVault $rgname $loc;
        
        Assert-ThrowsContains { Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmname -DiskEncryptionKeyVaultUrl $kv.DiskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $kv.DiskEncryptionKeyVaultId -VolumeType "OS" -Force; } `
            "skipVmBackup parameter is a required parameter for encrypting Linux VMs with managed disks"; 
    }
    finally
    {
        Clean-ResourceGroup($rgname)
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
    $vault2Name = "detestvault2";
    $kekName = "dstestkek";

    
    $vmName = "detestvm";
    $vmsize = 'Standard_DS2';
    $imagePublisher = "MicrosoftWindowsServer";
    $imageOffer = "WindowsServer";
    $imageSku ="2012-R2-Datacenter";

    
    $storageAccountName = "deteststore";
    $stotype = 'Premium_LRS';
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
        
        New-AzResourceGroup -Name $rgName -Location $loc -Force;

        
        $SvcPrincipals = (Get-AzADServicePrincipal -SearchString $aadAppName);
        if(-not $SvcPrincipals)
        {
            
            $identifierUri = [string]::Format("http://localhost:8080/{0}", $rgname);
            $defaultHomePage = 'http://contoso.com';
            $now = [System.DateTime]::Now;
            $oneYearFromNow = $now.AddYears(1);
            $aadClientSecret = Get-ResourceName;
            $ADApp = New-AzADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $aadClientSecret;
            Assert-NotNull $ADApp;
            $servicePrincipal = New-AzADServicePrincipal -ApplicationId $ADApp.ApplicationId;
            $SvcPrincipals = (Get-AzADServicePrincipal -SearchString $aadAppName);
            
            Assert-NotNull $SvcPrincipals;
            $aadClientID = $servicePrincipal.ApplicationId;
        }
        else
        {
            
            Assert-NotNull $aadClientSecret;
            $aadClientID = $SvcPrincipals[0].ApplicationId;
        }

        
        $keyVault = New-AzKeyVault -VaultName $vaultName -ResourceGroupName $rgname -Location $loc -Sku standard;
        $keyVault = Get-AzKeyVault -VaultName $vaultName -ResourceGroupName $rgname
        
        Set-AzKeyVaultAccessPolicy -VaultName $vaultName -ResourceGroupName $rgname -EnabledForDiskEncryption;
        
        Set-AzKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName $aadClientID -PermissionsToKeys all -PermissionsToSecrets all
        
        $kek = Add-AzKeyVaultKey -VaultName $vaultName -Name $kekName -Destination "Software"

        $diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
        $keyVaultResourceId = $keyVault.ResourceId;
        $keyEncryptionKeyUrl = $kek.Key.kid;

        
        $keyVault2 = New-AzKeyVault -VaultName $vault2Name -ResourceGroupName $rgname -Location $loc -Sku standard;
        $keyVault2 = Get-AzKeyVault -VaultName $vault2Name -ResourceGroupName $rgname
        
        Set-AzKeyVaultAccessPolicy -VaultName $vault2Name -ResourceGroupName $rgname -EnabledForDiskEncryption;
        
        Set-AzKeyVaultAccessPolicy -VaultName $vault2Name -ServicePrincipalName $aadClientID -PermissionsToKeys all -PermissionsToSecrets all

        $diskEncryptionKeyVaultUrl2 = $keyVault2.VaultUri;
        $keyVaultResourceId2 = $keyVault2.ResourceId;

        
        $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize;

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name ($subnetName) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzVirtualNetwork -Force -Name ($vnetName) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzVirtualNetwork -Name ($vnetName) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;
        $pubip = New-AzPublicIpAddress -Force -Name ($publicIpName) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ($publicIpName);
        $pubip = Get-AzPublicIpAddress -Name ($publicIpName) -ResourceGroupName $rgname;
        $pubipId = $pubip.Id;
        $nic = New-AzNetworkInterface -Force -Name ($nicName) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzNetworkInterface -Name ($nicName) -ResourceGroupName $rgname;
        $nicId = $nic.Id;

        $p = Add-AzVMNetworkInterface -VM $p -Id $nicId;

        
        New-AzStorageAccount -ResourceGroupName $rgname -Name $storageAccountName -Location $loc -Type $stotype;
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $storageAccountName)[0].Value;

        $osDiskVhdUri = "https://$storageAccountName.blob.core.windows.net/$vhdContainerName/$osDiskName.vhd";
        $dataDiskVhdUri = "https://$storageAccountName.blob.core.windows.net/$vhdContainerName/$dataDiskName.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzVMDataDisk -VM $p -Name $dataDiskName -Caching 'ReadOnly' -DiskSizeInGB 2 -Lun 1 -VhdUri $dataDiskVhdUri -CreateOption Empty;

        
        $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($adminUser, $securePassword);
        $computerName = $vmName;
        $vhdContainer = "https://$storageAccountName.blob.core.windows.net/$vhdContainerName";

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;
        $p = Set-AzVMSourceImage -VM $p -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version "latest";

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;

        
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl2 -DiskEncryptionKeyVaultId $keyVaultResourceId2 -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;

        
        $p = Add-AzVMDataDisk -VM $p -Name $extraDataDiskName1 -Caching 'ReadOnly' -DiskSizeInGB 2 -Lun 1 -VhdUri $dataDiskVhdUri -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name $extraDataDiskName2 -Caching 'ReadOnly' -DiskSizeInGB 2 -Lun 1 -VhdUri $dataDiskVhdUri -CreateOption Empty;
        
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;

        
        Disable-AzVMDiskEncryption -ResourceGroupName $rgname -VMName $vmName;
        
        $encryptionStatus = Get-AzVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $p.StorageProfile.OSDisk.Name;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $false;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $false;

        
        Remove-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName;
        
        $encryptionStatus = Get-AzVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $false;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $false;

        
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;

        
        Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId -Force;
        
        $encryptionStatus = Get-AzVmDiskEncryptionStatus -ResourceGroupName $rgname -VMName $vmName;
        
        $OsVolumeEncryptionSettings = $encryptionStatus.OsVolumeEncryptionSettings;
        Assert-AreEqual $encryptionStatus.OsVolumeEncrypted $true;
        Assert-AreEqual $encryptionStatus.DataVolumesEncrypted $true;
        
        Assert-NotNull $OsVolumeEncryptionSettings;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl;
        Assert-NotNull $OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault;
        
        Assert-Null $OsVolumeEncryptionSettings.KeyEncryptionKey.SecretUrl;
        Assert-Null $OsVolumeEncryptionSettings.KeyEncryptionKey.SourceVault;

        
        Remove-AzVm -ResourceGroupName $rgname -Name $vmName -Force;

        
        $p.StorageProfile.ImageReference = $null;
        $p.OSProfile = $null;
        $p.StorageProfile.DataDisks = $null;
        $p = Set-AzVMOSDisk -VM $p -Name $p.StorageProfile.OSDisk.Name -VhdUri $p.StorageProfile.OSDisk.Vhd.Uri -Caching ReadWrite -CreateOption attach -DiskEncryptionKeyUrl $encryptionStatus.OsVolumeEncryptionSettings.DiskEncryptionKey.SecretUrl -DiskEncryptionKeyVaultId $encryptionStatus.OsVolumeEncryptionSettings.DiskEncryptionKey.SourceVault.Id -Windows;

        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p -DisableBginfoExtension;

        $vm1 = Get-AzVM -ResourceGroupName $rgname -Name $vmname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        
        $extname = 'csetest';
        $extver = '2.1';

        
        Set-AzVMBginfoExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -TypeHandlerVersion $extver;

        $publisher = 'Microsoft.Compute';
        $exttype = 'BGInfo';

        
        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.UserName $user2;
        Assert-NotNull $ext.ProvisioningState;

        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;

        
        $vm1 = Get-AzVM -ResourceGroupName $rgname -Name $vmname;
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $publisher = 'Microsoft.Compute';
        $exttype = 'CustomScriptExtension';
        $extver = '1.1';

        
        $settingstr = '{"fileUris":[],"commandToExecute":""}';
        $protectedsettingstr = '{"storageAccountName":"' + $stoname + '","storageAccountKey":"' + $stokey + '"}';
        Set-AzVMExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname `
            -Name $extname -Publisher $publisher `
            -ExtensionType $exttype -TypeHandlerVersion $extver -SettingString $settingstr -ProtectedSettingString $protectedsettingstr `
            -DisableAutoUpgradeMinorVersion -ForceRerun "RerunExtension";

        
        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-False{$ext.AutoUpgradeMinorVersion};
        Assert-AreEqual $ext.ForceUpdateTag "RerunExtension";

        $ext = Get-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-AreEqual $ext.Name $extname;
        Assert-AreEqual $ext.Publisher $publisher;
        Assert-AreEqual $ext.ExtensionType $exttype;
        Assert-AreEqual $ext.TypeHandlerVersion $extver;
        Assert-AreEqual $ext.ResourceGroupName $rgname;
        Assert-NotNull $ext.ProvisioningState;
        Assert-NotNull $ext.Statuses;
        Assert-NotNull $ext.SubStatuses;

        
        Remove-AzVMExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Force;
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $extver = '1.3';
        $domainName = "Workgroup2"

        
        Set-AzVMADDomainExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname -DomainName $domainName;

        $publisher = 'Microsoft.Compute';
        $exttype = 'JsonADDomainExtension';

        
        $ext = Get-AzVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
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

        $ext = Get-AzVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
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

        
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;
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

        Remove-AzVM -Name $vmname -ResourceGroupName $rgname -Force;
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
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
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
        $stokey = (Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $stoname)[0].Value;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

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

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent;

        $imgRef = Get-DefaultCRPWindowsImageOffline;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;
        Assert-AreEqual $p.OSProfile.WindowsConfiguration.ProvisionVMAgent $true;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $extname = 'csetest';
        $extver = '1.3';
        $domainName = "dom123.com";
        $user2 = 'dom123.com\Bar12';
        $password2 = $PLACEHOLDER;
        $securePassword2 = ConvertTo-SecureString $password2 -AsPlainText -Force;
        $cred2 = New-Object System.Management.Automation.PSCredential ($user2, $securePassword2);
        $ouPath = "OU=testOU,DC=domain,DC=Domain,DC=com";

        
        Assert-ThrowsContains { Set-AzVMADDomainExtension -ResourceGroupName $rgname -Location $loc -VMName $vmname -Name $extname `
            -DomainName $domainName -Credential $cred2 -OUPath $ouPath -JoinOption 3 -Restart; } `
            "occured while joining Domain";
        $publisher = 'Microsoft.Compute';
        $exttype = 'JsonADDomainExtension';

        
        $ext = Get-AzVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname;
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

        $ext = Get-AzVMADDomainExtension -ResourceGroupName $rgname -VMName $vmname -Name $extname -Status;
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

        
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;
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

        Remove-AzVM -Name $vmname -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
