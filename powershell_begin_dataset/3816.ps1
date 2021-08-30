














function Test-ProximityPlacementGroup
{
    param ($loc)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');
        
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $ppgname = $rgname + 'ppg'
        New-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname -Location $loc -ProximityPlacementGroupType "Standard" -Tag @{key1 = "val1"};
        
        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;

        Assert-AreEqual $rgname $ppg.ResourceGroupName;
        Assert-AreEqual $ppgname $ppg.Name;
        Assert-AreEqual $loc $ppg.Location;
        Assert-AreEqual "Standard" $ppg.ProximityPlacementGroupType;
        Assert-True { $ppg.Tags.Keys.Contains("key1") };
        Assert-AreEqual "val1" $ppg.Tags["key1"];

        $ppgs = Get-AzProximityPlacementGroup -ResourceGroupName $rgname;
        Assert-AreEqual 1 $ppgs.Count;

        $ppgs = Get-AzProximityPlacementGroup;
        Assert-True {  $ppgs.Count -ge 1 };

        Remove-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname -Force;

        $ppgs = Get-AzProximityPlacementGroup -ResourceGroupName $rgname;
        Assert-AreEqual 0 $ppgs.Count;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ProximityPlacementGroupAvSet
{
    param ($loc)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');
        
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $ppgname = $rgname + 'ppg'
        New-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname -Location $loc -ProximityPlacementGroupType "Standard" -Tag @{key1 = "val1"};
        
        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;

        Assert-AreEqual $rgname $ppg.ResourceGroupName;
        Assert-AreEqual $ppgname $ppg.Name;
        Assert-AreEqual $loc $ppg.Location;
        Assert-AreEqual "Standard" $ppg.ProximityPlacementGroupType;
        Assert-True { $ppg.Tags.Keys.Contains("key1") };
        Assert-AreEqual "val1" $ppg.Tags["key1"];

        $asetName = $rgname + 'as';
        New-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Location $loc -ProximityPlacementGroupId $ppg.Id -Sku 'Classic';
        $av = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName;
        Assert-AreEqual $ppg.Id $av.ProximityPlacementGroup.Id;

        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;
        Assert-AreEqual $av.Id $ppg.AvailabilitySets[0].Id;

        Remove-AzAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Force;
        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;
        Assert-Null $ppg.AvailabilitySets;

        Remove-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ProximityPlacementGroupVM
{
    param ($loc)
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        [string]$loc = Get-ComputeVMLocation;
        $loc = $loc.Replace(' ', '');
        
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        
        $ppgname = $rgname + 'ppg'
        New-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname -Location $loc -ProximityPlacementGroupType "Standard" -Tag @{key1 = "val1"};
        
        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;

        Assert-AreEqual $rgname $ppg.ResourceGroupName;
        Assert-AreEqual $ppgname $ppg.Name;
        Assert-AreEqual $loc $ppg.Location;
        Assert-AreEqual "Standard" $ppg.ProximityPlacementGroupType;
        Assert-True { $ppg.Tags.Keys.Contains("key1") };
        Assert-AreEqual "val1" $ppg.Tags["key1"];

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix 192.168.1.0/24;

        
        $vnet = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $loc -Name  ('vnet' + $rgname) -AddressPrefix 192.168.0.0/16 -Subnet $subnet;

        
        $pip = New-AzPublicIpAddress -ResourceGroupName $rgname -Location $loc -Name ('pubip' + $rgname) -AllocationMethod Static -IdleTimeoutInMinutes 4;

        
        $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgname -Location $loc -Name ('netsg' + $rgname);

        
        $nic = New-AzNetworkInterface -Name ('nic' + $rgname) -ResourceGroupName $rgname -Location $loc `
                                      -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id;

        $vmname = 'vm' + $rgname;
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);

        
        $p = New-AzVMConfig -VMName $vmName -VMSize Standard_A1 -ProximityPlacementGroupId $ppg.Id `
                  | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred `
                  | Add-AzVMNetworkInterface -Id $nic.Id;

        $imgRef = Get-DefaultCRPImage -loc $loc;
        $p = ($imgRef | Set-AzVMSourceImage -VM $p);

        
        New-AzVM -ResourceGroupName $rgname -Location $loc -VM $p;
        $vm = Get-AzVM -ResourceGroupName $rgname -Name $vmName;
        Assert-AreEqual $ppg.Id $vm.ProximityPlacementGroup.Id;

        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;
        Assert-AreEqual $vm.Id $ppg.VirtualMachines[0].Id;

        Remove-AzVM -ResourceGroupName $rgname -Name $vmName -Force;
        $ppg = Get-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname;
        Assert-Null $ppg.VirtualMachines;

        Remove-AzProximityPlacementGroup -ResourceGroupName $rgname -Name $ppgname -Force;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
