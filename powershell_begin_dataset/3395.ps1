



















function Test-SetChefExtensionBasic
{
    $rgname = Get-ComputeTestResourceName
    $loc = Get-ComputeVMLocation
	$TestOutputRoot = [System.AppDomain]::CurrentDomain.BaseDirectory;

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
        $p = Set-AzureRmVMSourceImage -VM $p -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"

        
        New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $p;

	

	
	$version = "1210.12"
	$client_rb = "$TestOutputRoot\Templates\client.rb";
	$validationPemFile = "$TestOutputRoot\Templates\tstorgnztn-validator.pem";

	
        Set-AzureRmVMChefExtension -ResourceGroupName $rgname -VMName $vmname -TypeHandlerVersion $version -ClientRb $client_rb -ValidationPem $validationPemFile -Windows
	$extension = Get-AzureRmVMChefExtension -ResourceGroupName $rgname -VMName $vmname -Windows

        Assert-NotNull $extension
        Assert-AreEqual $extension.Publisher 'Chef.Bootstrap.WindowsAzure'
        Assert-AreEqual $extension.ExtensionType 'ChefClient'
        Assert-AreEqual $extension.Name 'ChefClient'

	
        Remove-AzureRmVMChefExtension -ResourceGroupName $rgname -VMName $vmname -Windows
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
