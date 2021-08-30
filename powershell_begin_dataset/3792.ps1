














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

