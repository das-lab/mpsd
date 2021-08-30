














function Test-VirtualMachine
{
    param ($loc, [bool] $hasManagedDisks = $false)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        if ($loc -eq $null)
        {
            $loc = Get-ComputeVMLocation;
        }
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;


        if($hasManagedDisks -eq $false)
        {
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
        }
        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname -DisplayHint Expand;

        
        $a = $vm1 | Out-String;
        Write-Verbose("Get-AzureRmVM output:");
        Write-Verbose($a);
        Assert-True {$a.Contains("Sku");}

        
        $vm1.DisplayHint = "Compact";
        $a = $vm1 | Out-String;
        Assert-False {$a.Contains("Sku");}

        
        $a = $vm1 | Format-Table | Out-String;
        Write-Verbose("Get-AzureRmVM | Format-Table output:");
        Write-Verbose($a);

        Assert-NotNull $vm1.VmId;
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

        Assert-AreEqual $true $vm1.DiagnosticsProfile.BootDiagnostics.Enabled;
        Assert-AreEqual $stoaccount.PrimaryEndpoints.Blob $vm1.DiagnosticsProfile.BootDiagnostics.StorageUri;

        Assert-AreEqual "BGInfo" $vm1.Extensions[0].VirtualMachineExtensionType
        Assert-AreEqual "Microsoft.Compute" $vm1.Extensions[0].Publisher

        Start-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Restart-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Stop-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Force -StayProvisioned;

        
        $p.Location = $vm1.Location;
        Update-AzureRmVM -ResourceGroupName $rgname -VM $p;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm2.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        Assert-AreEqual $true $vm2.DiagnosticsProfile.BootDiagnostics.Enabled;
        Assert-AreEqual $stoaccount.PrimaryEndpoints.Blob $vm2.DiagnosticsProfile.BootDiagnostics.StorageUri;

        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        $a = $vms | Out-String;
        Write-Verbose("Get-AzureRmVM (List) output:");
        Write-Verbose($a);
        Assert-True{$a.Contains("NIC");}
        Assert-AreNotEqual $vms $null;

        
        $a = $vms[0] | Format-Custom | Out-String;
        Assert-False {$a.Contains("Sku");}

        
        $vms[0].DisplayHint = "Expand";
        $a = $vms[0] | Format-Custom | Out-String;
        Assert-True {$a.Contains("Sku");}

        
        Get-AzureRmVM -ResourceGroupName $rgname | Remove-AzureRmVM -ResourceGroupName $rgname -Force;
        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreEqual $vms $null;

        
        $asetName = 'aset' + $rgname;
        $asetSkuName = 'Classic';
        $UD = 3;
        $FD = 3;
        if($hasManagedDisks -eq $true)
        {
            $asetSkuName = 'Aligned';
            $FD = 2;
        }

        New-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Location $loc -PlatformUpdateDomainCount $UD -PlatformFaultDomainCount $FD -Sku $asetSkuName;

        $asets = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $aset = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName;
        Assert-NotNull $aset;
        Assert-AreEqual $asetName $aset.Name;
        Assert-AreEqual $UD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $FD $aset.PlatformFaultDomainCount;
        Assert-AreEqual $asetSkuName $aset.Sku;
        Assert-NotNull $asets[0].RequestId;
        Assert-NotNull $asets[0].StatusCode;

        $subId = Get-SubscriptionIdFromResourceGroup $rgname;

        $asetId = ('/subscriptions/' + $subId + '/resourceGroups/' + $rgname + '/providers/Microsoft.Compute/availabilitySets/' + $asetName);
        $vmname2 = $vmname + '2';
        $p2 = New-AzureRmVMConfig -VMName $vmname2 -VMSize $vmsize -AvailabilitySetId $asetId;
        $p2.HardwareProfile = $p.HardwareProfile;
        $p2.OSProfile = $p.OSProfile;
        $p2.NetworkProfile = $p.NetworkProfile;
        $p2.StorageProfile = $p.StorageProfile;

        $p2.StorageProfile.DataDisks = $null;
        if($hasManagedDisks -eq $false)
        {
            $p2.StorageProfile.OsDisk.Vhd.Uri = "https://$stoname.blob.core.windows.net/test/os2.vhd";
        }
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p2;

        $vm2 = Get-AzureRmVM -Name $vmname2 -ResourceGroupName $rgname;
        Assert-NotNull $vm2;
        $vm2_out = $vm2 | Out-String
        Assert-True {$vm2_out.Contains("AvailabilitySetReference")};
        Assert-AreEqual $vm2.AvailabilitySetReference.Id $asetId;
        Assert-True { $vm2.ResourceGroupName -eq $rgname }
        
        
        Remove-AzureRmVM -Name $vmname2 -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachinePiping
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
        $vmname = 'vm' + $rgname;

        
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

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize `
             | Add-AzureRmVMNetworkInterface -Id $nicId -Primary `
             | Set-AzureRmVMOSDisk -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage `
             | Add-AzureRmVMDataDisk -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty `
             | Add-AzureRmVMDataDisk -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty `
             | Set-AzureRmVMOperatingSystem -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $imgRef | Set-AzureRmVMSourceImage -VM $p | New-AzureRmVM -ResourceGroupName $rgname -Location $loc;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        Assert-AreEqual $vm1.Extensions[0].AutoUpgradeMinorVersion $true;
        Assert-AreEqual $vm1.Extensions[0].Publisher "Microsoft.Compute"
        Assert-AreEqual $vm1.Extensions[0].VirtualMachineExtensionType "BGInfo";

        Get-AzureRmVM -ResourceGroupName $rgname | Start-AzureRmVM;
        Get-AzureRmVM -ResourceGroupName $rgname | Restart-AzureRmVM;
        Get-AzureRmVM -ResourceGroupName $rgname | Stop-AzureRmVM -Force -StayProvisioned;

        
        Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname `
        | Add-AzureRmVMDataDisk -Name 'testDataDisk3' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty `
        | Update-AzureRmVM;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm2.StorageProfile.DataDisks.Count 3;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        Get-AzureRmVM -ResourceGroupName $rgname | Stop-AzureRmVM -Force;
        Get-AzureRmVM -ResourceGroupName $rgname | Set-AzureRmVM -Generalize;

        $dest = Get-ComputeTestResourceName;
        $templatePath = "$TestOutputRoot\template.txt";
        Get-AzureRmVM -ResourceGroupName $rgname | Save-AzureRmVMImage -DestinationContainerName $dest -VHDNamePrefix 'pslib' -Overwrite -Path $templatePath;

        $template = Get-Content $templatePath;
        Assert-True { $template[1].Contains("$schema"); }

        
        Get-AzureRmVM -ResourceGroupName $rgname | Remove-AzureRmVM -Force;
        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreEqual $vms $null;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineUpdateWithoutNic
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_A4';
        $vmname = 'vm' + $rgname;

        
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

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize `
             | Add-AzureRmVMNetworkInterface -Id $nicId -Primary `
             | Set-AzureRmVMOSDisk -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage `
             | Add-AzureRmVMDataDisk -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty `
             | Add-AzureRmVMDataDisk -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty `
             | Set-AzureRmVMOperatingSystem -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $imgRef | Set-AzureRmVMSourceImage -VM $p | New-AzureRmVM -ResourceGroupName $rgname -Location $loc;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        Assert-AreEqual $vm1.Extensions[0].AutoUpgradeMinorVersion $true;
        Assert-AreEqual $vm1.Extensions[0].Publisher "Microsoft.Compute";
        Assert-AreEqual $vm1.Extensions[0].VirtualMachineExtensionType "BGInfo";

        
        $vm = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname | Remove-AzureRmVMNetworkInterface;

        Assert-ThrowsContains { Update-AzureRmVM -ResourceGroupName $rgname -VM $vm; } "must have at least one network interface"
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-VirtualMachineList
{
    
    $passed = $false;

    try
    {
        $s1 = Get-AzureRmVM;
        $s2 = Get-AzureRmVM;

        if ($s2 -ne $null)
        {
            Assert-NotNull $s2[0].Id;
        }

        Assert-ThrowsContains { $s3 = Get-AzureRmVM -NextLink "http://www.test.com/test"; } "Unable to deserialize the response"

        $passed = $true;
    }
    finally
    {
        Assert-True { $passed };
    }
}


function Test-VirtualMachineImageList
{
    
    $passed = $false;

    try
    {
        $locStr = Get-ComputeVMLocation;

        
        $foundAnyImage = $false;
        $pubNames = Get-AzureRmVMImagePublisher -Location $locStr | select -ExpandProperty PublisherName;
        $maxPubCheck = 3;
        $numPubCheck = 1;
        $pubNameFilter = '*Windows*';
        foreach ($pub in $pubNames)
        {
            
            if (-not ($pub -like $pubNameFilter)) { continue; }

            $s2 = Get-AzureRmVMImageOffer -Location $locStr -PublisherName $pub;
            if ($s2.Count -gt 0)
            {
                
                $numPubCheck = $numPubCheck + 1;
                if ($numPubCheck -gt $maxPubCheck) { break; }

                $offerNames = $s2 | select -ExpandProperty Offer;
                foreach ($offer in $offerNames)
                {
                    $s3 = Get-AzureRmVMImageSku -Location $locStr -PublisherName $pub -Offer $offer;
                    if ($s3.Count -gt 0)
                    {
                        $skus = $s3 | select -ExpandProperty Skus;
                        foreach ($sku in $skus)
                        {
                            $s4 = Get-AzureRmVMImage -Location $locStr -PublisherName $pub -Offer $offer -Sku $sku;
                            if ($s4.Count -gt 0)
                            {
                                $versions = $s4 | select -ExpandProperty Version;

                                foreach ($ver in $versions)
                                {
                                    if ($ver -eq $null -or $ver -eq '') { continue; }
                                    $s6 = Get-AzureRmVMImage -Location $locStr -PublisherName $pub -Offer $offer -Sku $sku -Version $ver;
                                    Assert-NotNull $s6;
                                    $s6;

                                    Assert-True { $versions -contains $ver };
                                    Assert-True { $versions -contains $s6.Name };

                                    $s6.Id;

                                    $foundAnyImage = $true;
                                }
                            }
                        }
                    }
                }
            }
        }

        Assert-True { $foundAnyImage };

        
        $foundAnyExtensionImage = $false;
        $pubNameFilter = '*Microsoft.Compute*';

        foreach ($pub in $pubNames)
        {
            
            if (-not ($pub -like $pubNameFilter)) { continue; }

            $s1 = Get-AzureRmVMExtensionImageType -Location $locStr -PublisherName $pub;
            $types = $s1 | select -ExpandProperty Type;
            if ($types.Count -gt 0)
            {
                foreach ($type in $types)
                {
                    $s2 = Get-AzureRmVMExtensionImage -Location $locStr -PublisherName $pub -Type $type -FilterExpression "startswith(name,'1')";
                    $versions = $s2 | select -ExpandProperty Version;
                    foreach ($ver in $versions)
                    {
                        $s3 = Get-AzureRmVMExtensionImage -Location $locStr -PublisherName $pub -Type $type -Version $ver;
                
                        Assert-NotNull $s3;
                        Assert-True { $s3.Version -eq $ver; }
                        $s3.Id;

                        $foundAnyExtensionImage = $true;
                    }
                }
            }
        }

        Assert-True { $foundAnyExtensionImage };

        
        $pubNameFilter = '*Microsoft*Windows*Server*';
        $imgs = Get-AzureRmVMImagePublisher -Location $locStr | where { $_.PublisherName -like $pubNameFilter } | Get-AzureRmVMImageOffer | Get-AzureRmVMImageSku | Get-AzureRmVMImage | Get-AzureRmVMImage;
        Assert-True { $imgs.Count -gt 0 };

        $pubNameFilter = '*Microsoft.Compute*';
        $extimgs = Get-AzureRmVMImagePublisher -Location $locStr | where { $_.PublisherName -like $pubNameFilter } | Get-AzureRmVMExtensionImageType | Get-AzureRmVMExtensionImage | Get-AzureRmVMExtensionImage;
        Assert-True { $extimgs.Count -gt 0 };

        
        
        $s1 = Get-AzureRmVMImagePublisher -Location $locStr;
        Assert-NotNull $s1;

        $publisherName = Get-ComputeTestResourceName;
        Assert-ThrowsContains { $s2 = Get-AzureRmVMImageOffer -Location $locStr -PublisherName $publisherName; } "$publisherName was not found";

        $offerName = Get-ComputeTestResourceName;
        Assert-ThrowsContains { $s3 = Get-AzureRmVMImageSku -Location $locStr -PublisherName $publisherName -Offer $offerName; } "was not found";
        
        $skusName = Get-ComputeTestResourceName;
        Assert-ThrowsContains { $s4 = Get-AzureRmVMImage -Location $locStr -PublisherName $publisherName -Offer $offerName -Skus $skusName; } "was not found";

        $filter = "name eq 'latest'";
        Assert-ThrowsContains { $s5 = Get-AzureRmVMImage -Location $locStr -PublisherName $publisherName -Offer $offerName -Skus $skusName -FilterExpression $filter; } "was not found";

        $version = '1.0.0';
        Assert-ThrowsContains { $s6 = Get-AzureRmVMImage -Location $locStr -PublisherName $publisherName -Offer $offerName -Skus $skusName -Version $version; } "was not found";

        
        $type = Get-ComputeTestResourceName;
        Assert-ThrowsContains { $s7 = Get-AzureRmVMExtensionImage -Location $locStr -PublisherName $publisherName -Type $type -FilterExpression $filter -Version $version; } "was not found";

        Assert-ThrowsContains { $s8 = Get-AzureRmVMExtensionImageType -Location $locStr -PublisherName $publisherName; } "was not found";

        Assert-ThrowsContains { $s9 = Get-AzureRmVMExtensionImage -Location $locStr -PublisherName $publisherName -Type $type -FilterExpression $filter; } "was not found";

        $passed = $true;
    }
    finally
    {
        
    }
}


function Test-VirtualMachineSizeAndUsage
{
    
    $rgname = Get-ComputeTestResourceName
    $passed = $false;

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $asetName = 'aset' + $rgname;
        New-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Location $loc;
        $aset = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName;

        
        $vmsize = 'Standard_A1';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize -AvailabilitySetId $aset.Id;
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage -DiskSizeInGB 200;

        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        
        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.OSDisk.DiskSizeGB 200;
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

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName $imgRef.PublisherName -Offer $imgRef.Offer -Skus $imgRef.Skus -Version $imgRef.Version;
        Assert-NotNull $p.StorageProfile.ImageReference;
        Assert-Null $p.StorageProfile.SourceImageId;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        $vm = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname;

        
        Assert-AreEqual $vm.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $vm.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $vm.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $vm.StorageProfile.OSDisk.DiskSizeGB 200;
        Assert-AreEqual $vm.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $vm.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $vm.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $vm.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $vm.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $vm.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $vm.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $vm.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $vm.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;

        
        $s1 = Get-AzureRmVMSize -Location ($loc -replace ' ');
        Assert-NotNull $s1;
        Assert-NotNull $s1.RequestId;
        Assert-NotNull $s1.StatusCode;
        Validate-VirtualMachineSize $vmsize $s1;

        $s2 = Get-AzureRmVMSize -ResourceGroupName $rgname -VMName $vmname;
        Assert-NotNull $s2;
        Validate-VirtualMachineSize $vmsize $s2;

        $asetName = $aset.Name;
        $s3 = Get-AzureRmVMSize -ResourceGroupName $rgname -AvailabilitySetName $asetName;
        Assert-NotNull $s3;
        Validate-VirtualMachineSize $vmsize $s3;

        
        $u1 = Get-AzureRmVMUsage -Location ($loc -replace ' ');

        $usageOutput = $u1 | Out-String;
        Write-Verbose("Get-AzureRmVMUsage: ");
        Write-Verbose($usageOutput);
        $usageOutput =  $u1 | Out-String;
        Write-Verbose("Get-AzureRmVMUsage | Format-Custom : ");
        $usageOutput =  $u1 | Format-Custom | Out-String;
        Write-Verbose($usageOutput);
        Validate-VirtualMachineUsage $u1;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

function Validate-VirtualMachineSize
{
    param([string] $vmSize, $vmSizeList)

    $count = 0;

    foreach ($item in $vmSizeList)
    {
        if ($item.Name -eq $vmSize)
        {
            $count = $count + 1;
        }
    }

    $valid = $count -eq 1;

    return $valid;
}

function Validate-VirtualMachineUsage
{
    param($vmUsageList)

    $valid = $true;

    foreach ($item in $vmUsageList)
    {
        Assert-NotNull $item;
        Assert-NotNull $item.Name;
        Assert-NotNull $item.Name.Value;
        Assert-NotNull $item.Name.LocalizedValue;
        Assert-True { $item.CurrentValue -le $item.Limit };
        Assert-NotNull $item.RequestId;
        Assert-NotNull $item.StatusCode;
    }

    return $valid;
}


function Test-VirtualMachinePIRv2
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

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
        $img = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-201503.01-en.us-127GB.vhd';

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);
        Assert-NotNull $p.StorageProfile.ImageReference;
        Assert-Null $p.StorageProfile.SourceImageId;

        
        $p.StorageProfile.DataDisks = $null;

        
        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineCapture
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

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
        $img = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-201503.01-en.us-127GB.vhd';

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        
        $p.StorageProfile.DataDisks = $null;

        
        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        Stop-AzureRmVM -ResourceGroupName $rgname -Name $vmname -Force;

        Set-AzureRmVM -Generalize -ResourceGroupName $rgname -Name $vmname;

        $dest = Get-ComputeTestResourceName;
        $templatePath = "$TestOutputRoot\template.txt";
        Save-AzureRmVMImage -ResourceGroupName $rgname -VMName $vmname -DestinationContainerName $dest -VHDNamePrefix 'pslib' -Overwrite -Path $templatePath;
        $template = Get-Content $templatePath;
        Assert-True { $template[1].Contains("$schema"); }

        
        Remove-AzureRmVM -ResourceGroupName $rgname -Name $vmname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineCaptureNegative
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

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
        $img = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-201503.01-en.us-127GB.vhd';

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        Assert-ThrowsContains `
            {Set-AzureRmVM -Generalize -ResourceGroupName $rgname -Name $vmname;} `
            "Please power off";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

function Test-VirtualMachineDataDisk
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";
        $dataDiskName1 = 'testDataDisk1';
        $dataDiskName2 = 'testDataDisk2';
        $dataDiskName3 = 'testDataDisk3';

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzureRmVMDataDisk -VM $p -Name $dataDiskName1 -Caching 'ReadOnly' -DiskSizeInGB 5 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name $dataDiskName2 -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;
        $p = Add-AzureRmVMDataDisk -VM $p -Name $dataDiskName3 -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;
        $p = Remove-AzureRmVMDataDisk -VM $p -Name $dataDiskName3;

        $p = Set-AzureRmVMDataDisk -VM $p -Name $dataDiskName1 -DiskSizeInGB 10;
        Assert-ThrowsContains { Set-AzureRmVMDataDisk -VM $p -Name $dataDiskName3 -Caching 'ReadWrite'; } "not currently assigned for this VM";

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;

        Assert-AreEqual $p.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Name $dataDiskName1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].CreateOption 'Empty';

        Assert-AreEqual $p.StorageProfile.DataDisks[1].Name $dataDiskName2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;
        Assert-AreEqual $p.StorageProfile.DataDisks[1].CreateOption 'Empty';

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm1.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm1.StorageProfile.DataDisks.Count 2;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[0].Name $dataDiskName1;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $vm1.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[0].CreateOption 'Empty';

        Assert-AreEqual $vm1.StorageProfile.DataDisks[1].Name $dataDiskName2;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[1].Caching 'ReadOnly';
        Assert-AreEqual $vm1.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;
        Assert-AreEqual $vm1.StorageProfile.DataDisks[1].CreateOption 'Empty';

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;

        $vm1 = Set-AzureRmVMDataDisk -VM $vm1 -Caching 'ReadWrite' -Lun 1;
        $vm1 = Set-AzureRmVMDataDisk -VM $vm1 -Name $dataDiskName2 -Caching 'ReadWrite';
        $vm1 = Add-AzureRmVMDataDisk -VM $vm1 -Name $dataDiskName3 -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri3 -CreateOption Empty;

        
        Update-AzureRmVM -ResourceGroupName $rgname -VM $vm1;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm2.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm2.StorageProfile.DataDisks.Count 3;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[0].Name $dataDiskName1;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[0].Caching 'ReadWrite';
        Assert-AreEqual $vm2.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[0].CreateOption 'Empty';

        Assert-AreEqual $vm2.StorageProfile.DataDisks[1].Name $dataDiskName2;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[1].Caching 'ReadWrite';
        Assert-AreEqual $vm2.StorageProfile.DataDisks[1].DiskSizeGB 11;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[1].Lun 2;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[1].Vhd.Uri $dataDiskVhdUri2;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[1].CreateOption 'Empty';

        Assert-AreEqual $vm2.StorageProfile.DataDisks[2].Name $dataDiskName3;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[2].Caching 'ReadOnly';
        Assert-AreEqual $vm2.StorageProfile.DataDisks[2].DiskSizeGB 12;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[2].Lun 3;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[2].Vhd.Uri $dataDiskVhdUri3;
        Assert-AreEqual $vm2.StorageProfile.DataDisks[2].CreateOption 'Empty';

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreNotEqual $vms $null;

        
        Get-AzureRmVM -ResourceGroupName $rgname | Remove-AzureRmVM -ResourceGroupName $rgname -Force;
        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreEqual $vms $null;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineDataDiskNegative
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;
        
        
        $vmsize = 'Standard_A0';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        
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

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

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
        
        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";
        $img = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-201503.01-en.us-127GB.vhd';

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        
        Assert-ThrowsContains { New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p; } "The maximum number of data disks allowed to be attached to a VM is 1.";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachinePlan
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;
        
        
        $vmsize = 'Standard_A0';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        
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

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $dataDiskVhdUri3 = "https://$stoname.blob.core.windows.net/test/data3.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";
        $img = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-201503.01-en.us-127GB.vhd';

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        $plan = Get-ComputeTestResourceName;
        $p = Set-AzureRmVMPlan -VM $p -Name $plan -Publisher $plan -Product $plan -PromotionCode $plan;

        
        Assert-ThrowsContains { New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p; } "User failed validation to purchase resources";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}




function Test-VirtualMachinePlan2
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;
        
        
        $vmsize = Get-DefaultVMSize;
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        
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

        
        $stoname = 'sto' + $rgname;
        $stotype = Get-DefaultStorageType;
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        
        
        $imgRef = (Get-MarketplaceImage)[0];
        $plan = $imgRef.PurchasePlan;
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName $imgRef.PublisherName -Offer $imgRef.Offer -Skus $imgRef.Skus -Version $imgRef.Version;
        $p = Set-AzureRmVMPlan -VM $p -Name $plan.Name -Publisher $plan.Publisher -Product $plan.Product;
        $p.OSProfile.WindowsConfiguration = $null;
        
        
        Assert-ThrowsContains { New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p; } "Legal terms have not been accepted for this item on this subscription";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-VirtualMachineTags
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;
        
        
        $vmsize = 'Standard_A0';
        $vmname = 'vm' + $rgname;
        $p = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize;
        
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

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        
        $tags = @{test1 = "testval1"; test2 = "testval2" };
        $st = New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p -Tags $tags;
        
        Assert-NotNull $st.StatusCode;
        $vm = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname;

        $a = $vm | Out-String;
        Write-Verbose("Get-AzureRmVM output:");
        Write-Verbose($a);

        Assert-NotNull $vm.RequestId;
        Assert-NotNull $vm.StatusCode;

        
        Assert-AreEqual "testval1" $vm.Tags["test1"];
        Assert-AreEqual "testval2" $vm.Tags["test2"];

        
        $vm = $vm | Update-AzureRmVM;
        $vm = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname;

        Assert-NotNull $vm.RequestId;
        Assert-NotNull $vm.StatusCode;
        Assert-AreEqual "testval1" $vm.Tags["test1"];
        Assert-AreEqual "testval2" $vm.Tags["test2"];

        
        $new_tags = @{test1 = "testval3"; test2 = "testval4" };
        $st = $vm | Update-AzureRmVM -Tags $new_tags;
        $vm = Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname;

        Assert-NotNull $vm.RequestId;
        Assert-NotNull $vm.StatusCode;
        Assert-AreEqual "testval3" $vm.Tags["test1"];
        Assert-AreEqual "testval4" $vm.Tags["test2"];

    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineWithVMAgentAutoUpdate
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";
        $imgRef = Get-DefaultCRPWindowsImageOffline;

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-Null $p.OSProfile.WindowsConfiguration.AdditionalUnattendContent "NULL";

        
        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
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

        
        Remove-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LinuxVirtualMachine
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $imgRef = Get-DefaultCRPLinuxImageOffline;

        $p = Set-AzureRmVMOperatingSystem -VM $p -Linux -ComputerName $computerName -Credential $cred
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
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

        
        Remove-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VMImageCmdletOutputFormat
{
    $locStr = Get-ComputeVMLocation;
    $imgRef = Get-DefaultCRPImage -loc $locStr;
    $publisher = $imgRef.PublisherName;
    $offer = $imgRef.Offer;
    $sku = $imgRef.Skus;
    $ver = $imgRef.Version;

    Assert-OutputContains " Get-AzureRmVMImagePublisher -Location '$locStr'" @('Id', 'Location', 'PublisherName');

    Assert-OutputContains " Get-AzureRmVMImagePublisher -Location '$locStr' | ? { `$_.PublisherName -eq `'$publisher`' } " @('Id', 'Location', 'PublisherName');

    Assert-OutputContains " Get-AzureRmVMImagePublisher -Location '$locStr' | ? { `$_.PublisherName -eq `'$publisher`' } | Get-AzureRmVMImageOffer " @('Id', 'Location', 'PublisherName', 'Offer');

    Assert-OutputContains " Get-AzureRmVMImagePublisher -Location '$locStr' | ? { `$_.PublisherName -eq `'$publisher`' } | Get-AzureRmVMImageOffer | Get-AzureRmVMImageSku " @('Id', 'Location', 'PublisherName', 'Offer', 'Sku');

    Assert-OutputContains " Get-AzureRmVMImagePublisher -Location '$locStr' | ? { `$_.PublisherName -eq `'$publisher`' } | Get-AzureRmVMImageOffer | Get-AzureRmVMImageSku | Get-AzureRmVMImage " @('Id', 'Location', 'PublisherName', 'Offer', 'Sku', 'Version', 'FilterExpression');

    Assert-OutputContains " Get-AzureRmVMImage -Location '$locStr' -PublisherName $publisher -Offer $offer -Skus $sku -Version $ver " @('Id', 'Location', 'PublisherName', 'Offer', 'Sku', 'Version', 'FilterExpression', 'Name', 'DataDiskImages', 'OSDiskImage', 'PurchasePlan');

    Assert-OutputContains " Get-AzureRmVMImage -Location '$locStr' -PublisherName $publisher -Offer $offer -Skus $sku -Version $ver " @('Id', 'Location', 'PublisherName', 'Offer', 'Sku', 'Version', 'FilterExpression', 'Name', 'DataDiskImages', 'OSDiskImage', 'PurchasePlan');
}


function Test-GetVMSizeFromAllLocations
{
    $locations = get_all_vm_locations;
    foreach ($loc in $locations)
    {
        $vmsizes = Get-AzureRmVMSize -Location $loc;
        Assert-True { $vmsizes.Count -gt 0 }
        Assert-True { ($vmsizes | where { $_.Name -eq 'Standard_A3' }).Count -eq 1 }

        Write-Output ('Found VM Size Standard_A3 in Location: ' + $loc);
    }
}

function get_all_vm_locations
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $namespace = "Microsoft.Compute"
        $type = "virtualMachines"
        $location = Get-AzureRmResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}
  
        if ($location -eq $null)
        {
            return @("West US", "East US")
        } else
        {
            return $location.Locations
        }
    }

    return @("West US", "East US")
}


function Test-VirtualMachineListWithPaging
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeDefaultLocation;
        $st = New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        $numberOfInstances = 51;
        $vmSize = 'Standard_A0';

        $templateFile = ".\Templates\azuredeploy.json";
        $paramFile = ".\Templates\azuredeploy-parameters-51vms.json";
        $paramContent =
@"
{
  "newStorageAccountName": {
    "value": "${rgname}sto"
  },
  "adminUsername": {
    "value": "Foo12"
  },
  "adminPassword": {
    "value": "BaR@123${rgname}"
  },
  "numberOfInstances": {
    "value": $numberOfInstances
  },
  "location": {
    "value": "$loc"
  },
  "vmSize": {
    "value": "$vmSize"
  }
}
"@;

        $st = Set-Content -Path $paramFile -Value $paramContent -Force;

        $st = New-AzureRmResourceGroupDeployment -Name "${rgname}dp" -ResourceGroupName $rgname -TemplateFile $templateFile -TemplateParameterFile $paramFile;

        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-True { $vms.Count -eq $numberOfInstances };

        $vms = Get-AzureRmVM;
        Assert-True { $vms.Count -ge $numberOfInstances };
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-VirtualMachineWithDifferentStorageResource
{
    
    $rgname = Get-ComputeTestResourceName
    $rgname_storage = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;
        New-AzureRmResourceGroup -Name $rgname_storage  -Location $loc -Force;

        
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname_storage -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname_storage -Name $stoname;

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

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
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

        Assert-AreEqual $true $vm1.DiagnosticsProfile.BootDiagnostics.Enabled;
        Assert-AreEqual $stoaccount.PrimaryEndpoints.Blob $vm1.DiagnosticsProfile.BootDiagnostics.StorageUri;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $rgname_storage
    }
}


function Test-VirtualMachineWithPremiumStorageAccount
{
    
    $rgname = Get-ComputeTestResourceName
    $rgname_storage = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;

        
        New-AzureRmResourceGroup -Name $rgname_storage  -Location $loc -Force;
        $stoname1 = 'sto' + $rgname_storage;
        $stotype1 = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname_storage -Name $stoname1 -Location $loc -Type $stotype1;
        $stoaccount1 = Get-AzureRmStorageAccount -ResourceGroupName $rgname_storage -Name $stoname1;

        
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Premium_LRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        
        $vmsize = 'Standard_DS1';
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

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

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
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

        Assert-AreEqual $true $vm1.DiagnosticsProfile.BootDiagnostics.Enabled;
        Assert-AreNotEqual $stoaccount.PrimaryEndpoints.Blob $vm1.DiagnosticsProfile.BootDiagnostics.StorageUri;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $rgname_storage
    }
}



function Test-VirtualMachineWithEmptyAuc
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;        

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
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

        Assert-AreEqual $true $vm1.DiagnosticsProfile.BootDiagnostics.Enabled;
        Assert-AreEqual $stoaccount.PrimaryEndpoints.Blob $vm1.DiagnosticsProfile.BootDiagnostics.StorageUri;

        
        $vm1 = Set-AzureRmVMDataDisk -VM $vm1 -Name 'testDataDisk1' -Caching 'None'

        $aucSetting = "AutoLogon";
        $aucContent = "<UserAccounts><AdministratorPassword><Value>" + $password + "</Value><PlainText>true</PlainText></AdministratorPassword></UserAccounts>";
        $vm1 = Add-AzureRmVMAdditionalUnattendContent -VM $vm1 -Content $aucContent -SettingName $aucSetting;
        [System.Collections.Generic.List[Microsoft.Azure.Management.Compute.Models.AdditionalUnattendContent]]$emptyAUC=@();
        $vm1.OSProfile.WindowsConfiguration.AdditionalUnattendContent.RemoveAt(0)

        
        Assert-NotNull $vm1.OSProfile.WindowsConfiguration.AdditionalUnattendContent;
        Assert-AreEqual 0 $vm1.OSProfile.WindowsConfiguration.AdditionalUnattendContent.Count;

        Update-AzureRmVM -ResourceGroupName $rgname -VM $vm1;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm2.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $vm2.StorageProfile.ImageReference.Version $imgRef.Version;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        Assert-AreEqual $true $vm2.DiagnosticsProfile.BootDiagnostics.Enabled;
        Assert-AreEqual $stoaccount.PrimaryEndpoints.Blob $vm2.DiagnosticsProfile.BootDiagnostics.StorageUri;

        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreNotEqual $vms $null;

        
        Get-AzureRmVM -ResourceGroupName $rgname | Remove-AzureRmVM -ResourceGroupName $rgname -Force;
        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreEqual $vms $null;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineWithBYOL
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = "Central US";
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

        
        $stoname = "mybyolosimagerdfe";

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";
        $userImageUrl = "https://mybyolosimagerdfe.blob.core.windows.net/vhdsrc2/win2012-tag2.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Windows -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -SourceImage $userImageUrl -CreateOption FromImage;
        $p = Add-AzureRmVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.DataDisks.Count 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Caching 'ReadOnly';
        Assert-AreEqual $p.StorageProfile.DataDisks[0].DiskSizeGB 10;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Lun 1;
        Assert-AreEqual $p.StorageProfile.DataDisks[0].Vhd.Uri $dataDiskVhdUri1;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";
        $licenseType = "Windows_Server";

        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate;

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -LicenseType $licenseType -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        $output = $vm1 | Out-String;
        Write-Verbose ('Output String   : ' + $output);
        Assert-AreEqual $vm1.Name $vmname;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm1.NetworkProfile.NetworkInterfaces[0].Id $nicId;

        Assert-AreEqual $vm1.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm1.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm1.HardwareProfile.VmSize $vmsize;
        Assert-AreEqual $vm1.LicenseType $licenseType;

        Assert-AreEqual $true $vm1.DiagnosticsProfile.BootDiagnostics.Enabled;

        Get-AzureRmVM -ResourceGroupName $rgname -Name $vmname `
        | Add-AzureRmVMDataDisk -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 12 -Lun 3 -VhdUri $dataDiskVhdUri2 -CreateOption Empty `
        | Update-AzureRmVM;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $vm2.StorageProfile.DataDisks.Count 2;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-AreEqual $vm2.LicenseType $licenseType;
        Assert-NotNull $vm2.Location;

        
        Get-AzureRmVM -ResourceGroupName $rgname | Remove-AzureRmVM -ResourceGroupName $rgname -Force;
        $vms = Get-AzureRmVM -ResourceGroupName $rgname;
        Assert-AreEqual $vms $null;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineRedeploy
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

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
        $img = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-201503.01-en.us-127GB.vhd';

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $vm2.StorageProfile.DataDisks.Count 2;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        
        Set-AzureRmVM -ResourceGroupName $rgname -Name $vmname -Redeploy;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $vm2.StorageProfile.DataDisks.Count 2;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        
        Remove-AzureRmVM -ResourceGroupName $rgname -Name $vmname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineGetStatus
{
    param ($loc)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        if ($loc -eq $null)
        {
            $loc = Get-ComputeVMLocation;
        }
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
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";

        $p = Set-AzureRmVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm1 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;
        $a = $vm1 | Out-String;
        Write-Verbose("Get-AzureRmVM output:");
        Write-Verbose($a);
        $a = $vm1 | Format-Table | Out-String;
        Write-Verbose("Get-AzureRmVM | Format-Table output:");
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

        $vm = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Status;
        $a = $vm | Out-String;
        Write-Verbose($a);
        Assert-True {$a.Contains("Statuses");}

        $vms = Get-AzureRmVM -ResourceGroupName $rgname -Status;
        $a = $vms | Out-String;
        Write-Verbose($a);
        Assert-True {$a.Contains("PowerState");}

        $vms = Get-AzureRmVM -Status;
        $a = $vms | Out-String;
        Write-Verbose($a);
        Assert-True {$a.Contains("PowerState");}

        
        $a = $vms[0] | Format-Custom | Out-String;
        Assert-False{$a.Contains("Sku");};

        
        $vms[0].DisplayHint = "Expand"
        $a = $vms[0] | Format-Custom | Out-String;
        Assert-True{$a.Contains("Sku");};

        
        Remove-AzureRmVM -Name $vmname -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualMachineManagedDiskConversion
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        if ($loc -eq $null)
        {
            $loc = Get-ComputeVMLocation;
        }
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

        
        $p = Add-AzureRmVMNetworkInterface -VM $p -Id $nicId -Primary;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $p.NetworkProfile.NetworkInterfaces[0].Primary $true;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_GRS';
        New-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

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

        
        $p = Set-AzureRmVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzureRmVMSourceImage -VM $p);

        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        Assert-AreEqual $p.StorageProfile.ImageReference.Offer $imgRef.Offer;
        Assert-AreEqual $p.StorageProfile.ImageReference.Publisher $imgRef.PublisherName;
        Assert-AreEqual $p.StorageProfile.ImageReference.Sku $imgRef.Skus;
        Assert-AreEqual $p.StorageProfile.ImageReference.Version $imgRef.Version;

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces.Count 1;
        Assert-AreEqual $vm2.NetworkProfile.NetworkInterfaces[0].Id $nicId;
        Assert-AreEqual $vm2.StorageProfile.DataDisks.Count 2;

        Assert-AreEqual $vm2.OSProfile.AdminUsername $user;
        Assert-AreEqual $vm2.OSProfile.ComputerName $computerName;
        Assert-AreEqual $vm2.HardwareProfile.VmSize $vmsize;
        Assert-NotNull $vm2.Location;

        Assert-Null  $vm2.StorageProfile.OSDisk.ManagedDisk
        Assert-Null  $vm2.StorageProfile.DataDisks[0].ManagedDisk
        Assert-Null  $vm2.StorageProfile.DataDisks[1].ManagedDisk

        
        Stop-AzureRmVM -ResourceGroupName $rgname -Name $vmname -Force

        
        ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgname -VMName $vmname

        $vm2 = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname;

        Assert-NotNull  $vm2.StorageProfile.OSDisk.ManagedDisk
        Assert-NotNull  $vm2.StorageProfile.DataDisks[0].ManagedDisk
        Assert-NotNull  $vm2.StorageProfile.DataDisks[1].ManagedDisk

        
        Remove-AzureRmVM -ResourceGroupName $rgname -Name $vmname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
