














function Test-NetworkInterfaceExpandResource
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
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $job = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip -AsJob
        $job | Wait-Job
		$actualNic = $job | Receive-Job
		$expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-NotNull $expectedNic.ResourceGuid
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $expectedNic.IpConfigurations[0].PrivateIpAllocationMethod

		Assert-Null $expectedNic.IpConfigurations[0].PublicIpAddress.Name
		Assert-Null $expectedNic.IpConfigurations[0].Subnet.Name
        
        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -ExpandResource "IpConfigurations/Subnet"
        Assert-Null $nic.IpConfigurations[0].PublicIpAddress.Name
        Assert-NotNull $nic.IpConfigurations[0].Subnet.Name

        
        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -ExpandResource "IpConfigurations/PublicIPAddress"
        Assert-NotNull $nic.IpConfigurations[0].PublicIpAddress.Name
        Assert-Null $nic.IpConfigurations[0].Subnet.Name

        
        $nic = Get-AzNetworkInterface -ResourceId $expectedNic.Id -ExpandResource "IpConfigurations/Subnet"
        Assert-Null $nic.IpConfigurations[0].PublicIpAddress.Name
        Assert-NotNull $nic.IpConfigurations[0].Subnet.Name

        
        $nic = Get-AzNetworkInterface -ResourceId $expectedNic.Id -ExpandResource "IpConfigurations/PublicIPAddress"
        Assert-NotNull $nic.IpConfigurations[0].PublicIpAddress.Name
        Assert-Null $nic.IpConfigurations[0].Subnet.Name

        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceCRUD
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
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-NotNull $expectedNic.ResourceGuid
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $expectedNic.IpConfigurations[0].PrivateIpAllocationMethod

        $expectedNic = Get-AzNetworkInterface -ResourceId $actualNic.Id

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName
        Assert-AreEqual $expectedNic.Name $actualNic.Name
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-NotNull $expectedNic.ResourceGuid
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $expectedNic.IpConfigurations[0].PrivateIpAllocationMethod

        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $list[0].Name $actualNic.Name	
        Assert-AreEqual $list[0].Location $actualNic.Location
        Assert-AreEqual "Succeeded" $list[0].ProvisioningState
        Assert-AreEqual $actualNic.Etag $list[0].Etag

        
        $job = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force -AsJob
		$job | Wait-Job
		$delete = $job | Receive-Job
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceCRUDUsingId
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
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicip.Id
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $expectedNic.IpConfigurations[0].PrivateIpAllocationMethod

        
        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $list[0].Name $actualNic.Name	
        Assert-AreEqual $list[0].Location $actualNic.Location
        Assert-AreEqual "Succeeded" $list[0].ProvisioningState
        Assert-AreEqual $actualNic.Etag $list[0].Etag

        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceCRUDStaticAllocation
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
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -PrivateIpAddress "10.0.1.5" -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual "Static" $actualNic.IpConfigurations[0].PrivateIpAllocationMethod
        Assert-AreEqual "10.0.1.5" $actualNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        
        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-NetworkInterfaceNoPublicIpAddress
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $nicName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/networkInterfaces"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-Null $expectedNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        
        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $list[0].Name $actualNic.Name	
        Assert-AreEqual $list[0].Location $actualNic.Location
        Assert-AreEqual "Succeeded" $list[0].ProvisioningState
        Assert-AreEqual $actualNic.Etag $list[0].Etag

        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceSet
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $publicIpName2 = Get-ResourceName
    $nicName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $domainNameLabel2 = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/networkInterfaces"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicip.Id
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        
        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $publicip2 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName2 -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel2
        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        
        $nic.IpConfigurations[0].PublicIpAddress = $publicip2

        $job = $nic | Set-AzNetworkInterface -AsJob
	$job | Wait-Job

        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        
        $publicip2 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName2
        Assert-AreEqual $nic.IpConfigurations[0].PublicIpAddress.Id $publicip2.Id
        Assert-AreEqual $nic.IpConfigurations[0].Id $publicip2.IpConfiguration.Id

        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-Null $publicip.IpConfiguration

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $nic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $nic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceIDns
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
        
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -InternalDnsNameLabel "idnstest"
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $expectedNic.IpConfigurations[0].PrivateIpAllocationMethod
        Assert-AreEqual "idnstest" $expectedNic.DnsSettings.InternalDnsNameLabel
        Assert-NotNull $expectedNic.DnsSettings.InternalFqdn
		
        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceEnableIPForwarding
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
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -EnableIPForwarding
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual true $expectedNic.EnableIPForwarding

		
		$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -Force
		Assert-AreEqual $expectedNic.Name $nic.Name	
		Assert-AreEqual false $nic.EnableIPForwarding

		
		$nic.EnableIPForwarding = $true
		$nic =  $nic | Set-AzNetworkInterface

		Assert-AreEqual $expectedNic.Name $nic.Name	
		Assert-AreEqual true $nic.EnableIPForwarding
		
        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceIpv6
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
	$subnet2Name = Get-ResourceName
    $publicIpName = Get-ResourceName
    $nicName = Get-ResourceName
	$ipconfigName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/networkInterfaces"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
		$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.2.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet,$subnet2
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $list[0].Name $actualNic.Name	
        Assert-AreEqual $list[0].Location $actualNic.Location
        Assert-AreEqual "Succeeded" $list[0].ProvisioningState
        Assert-AreEqual $actualNic.Etag $list[0].Etag

		
		$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname | Add-AzNetworkInterfaceIpConfig -Name $ipconfigName -PrivateIpAddressVersion ipv6  | Set-AzNetworkInterface
		Assert-AreEqual 2 @($nic.IpConfigurations).Count

		Assert-AreEqual $expectedNic.IpConfigurations[0].Name $nic.IpConfigurations[0].Name
        Assert-AreEqual $publicip.Id $nic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $vnet.Subnets[0].Id $nic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $nic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $nic.IpConfigurations[0].PrivateIpAllocationMethod
		Assert-AreEqual $nic.IpConfigurations[0].PrivateIpAddressVersion IPv4

		Assert-AreEqual $ipconfigName $nic.IpConfigurations[1].Name
        Assert-Null $nic.IpConfigurations[1].PublicIpAddress
        Assert-Null $nic.IpConfigurations[1].Subnet
        Assert-AreEqual $nic.IpConfigurations[1].PrivateIpAddressVersion IPv6

		
		$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname | Set-AzNetworkInterfaceIpConfig -Name $nic.IpConfigurations[0].Name -Subnet $vnet.Subnets[1] -PrivateIpAddress "10.0.2.10" | Set-AzNetworkInterface
		Assert-AreEqual 2 @($nic.IpConfigurations).Count

		Assert-AreEqual $expectedNic.IpConfigurations[0].Name $nic.IpConfigurations[0].Name
        Assert-Null $nic.IpConfigurations[0].PublicIpAddress
        Assert-AreEqual $vnet.Subnets[1].Id $nic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $nic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Static" $nic.IpConfigurations[0].PrivateIpAllocationMethod
		Assert-AreEqual $nic.IpConfigurations[0].PrivateIpAddressVersion IPv4

		Assert-AreEqual $ipconfigName $nic.IpConfigurations[1].Name
        Assert-Null $nic.IpConfigurations[1].PublicIpAddress
        Assert-Null $nic.IpConfigurations[1].Subnet
        Assert-AreEqual $nic.IpConfigurations[1].PrivateIpAddressVersion IPv6

		
		$ipconfigv6 = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname | Get-AzNetworkInterfaceIpConfig -Name $ipconfigName
	
		Assert-AreEqual $ipconfigName $ipconfigv6.Name
        Assert-Null $ipconfigv6.PublicIpAddress
        Assert-Null $ipconfigv6.Subnet
        Assert-AreEqual $ipconfigv6.PrivateIpAddressVersion IPv6

		
		$ipconfigList = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname | Get-AzNetworkInterfaceIpConfig
	
		Assert-AreEqual 2 @($ipconfigList).Count

		Assert-AreEqual $expectedNic.IpConfigurations[0].Name $ipconfigList[0].Name
        Assert-Null $ipconfigList[0].PublicIpAddress.Id
        Assert-NotNull $ipconfigList[0].PrivateIpAddress
        Assert-AreEqual "Static" $nic.IpConfigurations[0].PrivateIpAllocationMethod
		Assert-AreEqual $ipconfigList[0].PrivateIpAddressVersion IPv4

		Assert-AreEqual $ipconfigName $ipconfigList[1].Name
        Assert-Null $ipconfigList[1].PublicIpAddress
        Assert-Null $ipconfigList[1].Subnet
        Assert-AreEqual $ipconfigList[1].PrivateIpAddressVersion IPv6

		
		$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname | Remove-AzNetworkInterfaceIpConfig -Name $ipconfigName | Set-AzNetworkInterface

		Assert-AreEqual 1 @($nic.IpConfigurations).Count

		Assert-AreEqual $expectedNic.IpConfigurations[0].Name $nic.IpConfigurations[0].Name
        Assert-Null $nic.IpConfigurations[0].PublicIpAddress
        Assert-AreEqual $vnet.Subnets[1].Id $nic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $nic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Static" $nic.IpConfigurations[0].PrivateIpAllocationMethod
		Assert-AreEqual $nic.IpConfigurations[0].PrivateIpAddressVersion IPv4

        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceWithIpConfiguration
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $nicName = Get-ResourceName
	$ipconfig1Name = Get-ResourceName
	$ipconfig2Name = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/networkInterfaces"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

		
		$ipconfig1 = New-AzNetworkInterfaceIpConfig -Name $ipconfig1Name -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip
		$ipconfig2 = New-AzNetworkInterfaceIpConfig -Name $ipconfig2Name -PrivateIpAddressVersion IPv6

        
        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -IpConfiguration $ipconfig1,$ipconfig2 -Tag @{ testtag = "testval" }

        Assert-AreEqual $rgname $nic.ResourceGroupName	
        Assert-AreEqual $nicName $nic.Name	
        Assert-NotNull $nic.ResourceGuid
        Assert-AreEqual "Succeeded" $nic.ProvisioningState
        Assert-AreEqual $nic.IpConfigurations[0].Name $nic.IpConfigurations[0].Name
        Assert-AreEqual $nic.IpConfigurations[0].PublicIpAddress.Id $nic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $nic.IpConfigurations[0].Subnet.Id $nic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $nic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $nic.IpConfigurations[0].PrivateIpAllocationMethod
		        
        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $nic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $nic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $nic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $nic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

		
		Assert-AreEqual 2 @($nic.IpConfigurations).Count

		Assert-AreEqual $ipconfig1Name $nic.IpConfigurations[0].Name
        Assert-AreEqual $publicip.Id $nic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $vnet.Subnets[0].Id $nic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $nic.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual "Dynamic" $nic.IpConfigurations[0].PrivateIpAllocationMethod
		Assert-AreEqual $nic.IpConfigurations[0].PrivateIpAddressVersion IPv4

		Assert-AreEqual $ipconfig2Name $nic.IpConfigurations[1].Name
        Assert-Null $nic.IpConfigurations[1].PublicIpAddress
        Assert-Null $nic.IpConfigurations[1].Subnet
        Assert-AreEqual $nic.IpConfigurations[1].PrivateIpAddressVersion IPv6

        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceWithAcceleratedNetworking
{
   
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $nicName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "West Central US"
    $resourceTypeParent = "Microsoft.Network/networkInterfaces"
    $location = Get-ProviderLocation $resourceTypeParent "West Central US"
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $actualNic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -PublicIpAddress $publicip -EnableAcceleratedNetworking
        $expectedNic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgname

        Assert-AreEqual $expectedNic.ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $expectedNic.Name $actualNic.Name	
        Assert-AreEqual $expectedNic.Location $actualNic.Location
        Assert-NotNull $expectedNic.ResourceGuid
        Assert-AreEqual "Succeeded" $expectedNic.ProvisioningState
        Assert-AreEqual $expectedNic.IpConfigurations[0].Name $actualNic.IpConfigurations[0].Name
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $actualNic.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $actualNic.IpConfigurations[0].Subnet.Id
        Assert-NotNull $expectedNic.IpConfigurations[0].PrivateIpAddress
		Assert-AreEqual $expectedNic.EnableAcceleratedNetworking $true
        Assert-AreEqual "Dynamic" $expectedNic.IpConfigurations[0].PrivateIpAllocationMethod

        
        
        $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName
        Assert-AreEqual $expectedNic.IpConfigurations[0].PublicIpAddress.Id $publicip.Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $publicip.IpConfiguration.Id

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual $expectedNic.IpConfigurations[0].Subnet.Id $vnet.Subnets[0].Id
        Assert-AreEqual $expectedNic.IpConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id

        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $actualNic.ResourceGroupName	
        Assert-AreEqual $list[0].Name $actualNic.Name	
        Assert-AreEqual $list[0].Location $actualNic.Location
        Assert-AreEqual "Succeeded" $list[0].ProvisioningState
        Assert-AreEqual $actualNic.Etag $list[0].Etag

        $list = Get-AzNetworkInterface -ResourceGroupName "*" -Name "*"
        Assert-True { $list.Count -ge 0 }

        $list = Get-AzNetworkInterface -Name "*"
        Assert-True { $list.Count -ge 0 }

        $list = Get-AzNetworkInterface -ResourceGroupName "*"
        Assert-True { $list.Count -ge 0 }

        
        $delete = Remove-AzNetworkInterface -ResourceGroupName $rgname -name $nicName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzNetworkInterface -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NetworkInterfaceTapConfigurationCRUD
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
    $vtapName = Get-ResourceName
    $vtapName2 = Get-ResourceName
    $sourceIpConfigName = Get-ResourceName
    $sourceNicName = Get-ResourceName

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
        $actualVtap = New-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $vtapName -Location $location -DestinationNetworkInterfaceIPConfiguration $DestinationEndpoint  -Force
        $vVirtualNetworkTap = Get-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $vtapName;

        
        $sourceIpConfig = New-AzNetworkInterfaceIpConfig -Name $sourceIpConfigName -Subnet $vnet.Subnets[0]
        $sourceNic = New-AzNetworkInterface -Name $sourceNicName -ResourceGroupName $rgname -Location $location -IpConfiguration $sourceIpConfig -Tag @{ testtag = "testval" }

        
        Add-AzNetworkInterfaceTapConfig -NetworkInterface $sourceNic -VirtualNetworkTap $vVirtualNetworkTap -Name $rname

        
        $tapConfig = Get-AzNetworkInterfaceTapConfig -ResourceGroupName $rgname -NetworkInterfaceName $sourceNicName -Name $rname
        Assert-NotNull $tapConfig
        Assert-AreEqual $tapConfig.ResourceGroupName $rgname
        Assert-AreEqual $tapConfig.NetworkInterfaceName $sourceNicName
        Assert-AreEqual $tapConfig.Name $rname

        $tapConfigs = Get-AzNetworkInterfaceTapConfig -ResourceGroupName $rgname -NetworkInterfaceName $sourceNicName
        Assert-NotNull $tapConfigs

        $tapConfigs = Get-AzNetworkInterfaceTapConfig -ResourceGroupName $rgname -NetworkInterfaceName $sourceNicName -Name "*"
        Assert-NotNull $tapConfigs

        $tapConfig = Get-AzNetworkInterfaceTapConfig -ResourceId $tapConfig.Id
        Assert-NotNull $tapConfig
        Assert-AreEqual $tapConfig.ResourceGroupName $rgname
        Assert-AreEqual $tapConfig.NetworkInterfaceName $sourceNicName
        Assert-AreEqual $tapConfig.Name $rname

        
        $sourceNic = Get-AzNetworkInterface -Name $sourceNicName -ResourceGroupName $rgname
        Assert-NotNull $sourceNic.TapConfigurations
        Assert-NotNull $sourceNic.TapConfigurations[0]
        Assert-AreEqual $sourceNic.TapConfigurations[0].Id $tapConfig.Id

        
        $vVirtualNetworkTap = Get-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $vtapName;
        Assert-NotNull $vVirtualNetworkTap.NetworkInterfaceTapConfigurations
        Assert-NotNull $vVirtualNetworkTap.NetworkInterfaceTapConfigurations[0]
        Assert-AreEqual $vVirtualNetworkTap.NetworkInterfaceTapConfigurations[0].Id $tapConfig.Id

        
        $job = Set-AzNetworkInterfaceTapConfig -NetworkInterfaceTapConfig $tapConfig -AsJob -Force
        $job | Wait-Job
        $tapConfig = $job | Receive-Job
        Assert-NotNull $tapConfig
        Assert-AreEqual $tapConfig.ResourceGroupName $rgname
        Assert-AreEqual $tapConfig.NetworkInterfaceName $sourceNicName
        Assert-AreEqual $tapConfig.Name $rname

        
        $removeNetworkInterfaceTapConfiguration = Remove-AzNetworkInterfaceTapConfig -ResourceGroupName $rgname -NetworkInterfaceName $sourceNicName -Name $rname -PassThru -Force;
        Assert-AreEqual $true $removeNetworkInterfaceTapConfiguration;

        $sourceNic = Get-AzNetworkInterface -Name $sourceNicName -ResourceGroupName $rgname
        Assert-NotNull $sourceNic.TapConfigurations
        Assert-Null $sourceNic.TapConfigurations[0]

        
        $vVirtualNetworkTap = Get-AzVirtualNetworkTap -ResourceGroupName $rgname -Name $vtapName;
        Assert-NotNull $vVirtualNetworkTap.NetworkInterfaceTapConfigurations
        Assert-Null $vVirtualNetworkTap.NetworkInterfaceTapConfigurations[0]

        
        Assert-ThrowsContains { Get-AzNetworkInterfaceTapConfig  -ResourceGroupName $rgname -NetworkInterfaceName $sourceNicName -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}

function Get-NameById($Id, $ResourceType)
{
    $name = $Id.Substring($Id.IndexOf($ResourceType + '/') + $ResourceType.Length + 1);
    if ($name.IndexOf('/') -ne -1)
    {
        $name = $name.Substring(0, $name.IndexOf('/'));
    }
    return $name;
}

function Test-NetworkInterfaceVmss
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Compute/virtualMachineScaleSets"
    $location = Get-ProviderLocation $resourceTypeParent
    $lbName = Get-ResourceName

    try
    {
       
       $resourceGroup = New-AzureRmResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
       
       $secpasswd = ConvertTo-SecureString "Pa$$word2018" -AsPlainText -Force
       $mycreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)

       $vmssName = "vmssip"
       $templateFile = (Resolve-Path ".\ScenarioTests\Data\VmssDeploymentTemplate.json").Path
       New-AzureRmResourceGroupDeployment -Name $rgname -ResourceGroupName $rgname -TemplateFile $templateFile;

       $listAllResults = Get-AzureRmNetworkInterface -ResourceGroupName $rgname -VirtualMachineScaleSetName $vmssName;
       Assert-NotNull $listAllResults;

       $listFirstResultId = $listAllResults[0].Id;
       $vmIndex = Get-NameById $listFirstResultId "virtualMachines";
       $nicName = Get-NameById $listFirstResultId "networkInterfaces";

       $listResults = Get-AzureRmNetworkInterface -ResourceGroupName $rgname -VirtualMachineScaleSetName $vmssName -VirtualmachineIndex $vmIndex;
       Assert-NotNull $listResults;
       Assert-AreEqualObjectProperties $listAllResults[0] $listResults[0] "List and list all results should contain equal items";

       $vmssNic = Get-AzureRmNetworkInterface -VirtualMachineScaleSetName $vmssName -ResourceGroupName $rgname -VirtualMachineIndex $vmIndex -Name $nicName;
       Assert-NotNull $vmssNic;
       Assert-AreEqualObjectProperties $vmssNic $listResults[0] "List and get results should contain equal items";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
