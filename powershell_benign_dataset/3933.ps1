














function Test-VirtualNetworkTapCRUDUsingIpConfig
{
    
    

    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $nicName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/networkInterfaces"
    $location = Get-ProviderLocation $resourceTypeParent
    $rname = Get-ResourceName

    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $job = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip -AsJob
        $job | Wait-Job
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        
        $DestinationEndpoint = $expectedNic.IpConfigurations[0]
        $actualVtap = New-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $rname -Location $location -DestinationNetworkInterfaceIPConfiguration $DestinationEndpoint

        $vVirtualNetworkTap = Get-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vVirtualNetworkTap;
        Assert-AreEqual $vVirtualNetworkTap.ResourceGroupName $actualVtap.ResourceGroupName;
        Assert-AreEqual $vVirtualNetworkTap.Name $rname;
        Assert-AreEqual $vVirtualNetworkTap.DestinationNetworkInterfaceIPConfiguration.Id $DestinationEndpoint.Id

        $list = Get-AzVirtualNetworkTap -ResourceGroupName "*"
        Assert-True { $list.Count -ge 0 }

        $list = Get-AzVirtualNetworkTap -Name "*"
        Assert-True { $list.Count -ge 0 }

        $list = Get-AzVirtualNetworkTap -ResourceGroupName "*" -Name "*"
        Assert-True { $list.Count -ge 0 }

        $vVirtualNetworkTaps = Get-AzureRmVirtualNetworkTap -ResourceGroupName $rgname;
        Assert-NotNull $vVirtualNetworkTaps;

        $vVirtualNetworkTapsAll = Get-AzureRmVirtualNetworkTap;
        Assert-NotNull $vVirtualNetworkTapsAll;

        
        $vVirtualNetworkTap.DestinationPort = 8888;
        Set-AzVirtualNetworkTap -VirtualNetworkTap $vVirtualNetworkTap

        $vVirtualNetworkTap = Get-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vVirtualNetworkTap;
        Assert-AreEqual $vVirtualNetworkTap.ResourceGroupName $actualVtap.ResourceGroupName;
        Assert-AreEqual $vVirtualNetworkTap.Name $rname;
        Assert-AreEqual $vVirtualNetworkTap.DestinationNetworkInterfaceIPConfiguration.Id $DestinationEndpoint.Id
        Assert-AreEqual $vVirtualNetworkTap.DestinationPort 8888

        
        $removeVirtualNetworkTap = Remove-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $rname -PassThru -Force;
        Assert-AreEqual $true $removeVirtualNetworkTap;

        
        Assert-ThrowsLike { Get-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $rname } "*${rname}*not found*";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

