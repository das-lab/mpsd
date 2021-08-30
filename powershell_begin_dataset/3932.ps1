














function Test-BastionCRUD
{

    
   
    $rgname = Get-ResourceGroupName
    $bastionName = Get-ResourceName
	$resourceTypeParent = "Microsoft.Network/bastionHosts"
    $location = Get-ProviderLocation $resourceTypeParent

    $vnetName = Get-ResourceName
    $subnetName = "AzureBastionSubnet"
    $publicIpName = Get-ResourceName
    
	try
	{
		
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location

		
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

		
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard
		
		 
        $bastion = New-AzBastion -ResourceGroupName $rgname –Name $bastionName -PublicIpAddressRgName $rgname -PublicIpAddressName $publicIpName -VirtualNetworkRgName $rgname -VirtualNetworkName $vnetName 

		
		$bastionObj = Get-AzBastion -ResourceGroupName $rgname -Name $bastionName
        Assert-NotNull $bastionObj

		
        Assert-AreEqual $rgName $bastionObj.ResourceGroupName
        Assert-AreEqual $bastionName $bastionObj.Name
        Assert-NotNull $bastionObj.Etag
        Assert-AreEqual 1 @($bastionObj.IpConfigurations).Count
        Assert-NotNull $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-NotNull $bastionObj.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $subnet.Id $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip.Id $bastionObj.IpConfigurations[0].PublicIpAddress.Id

		
		$bastionObj = Get-AzBastion -ResourceId $bastion.id
        Assert-NotNull $bastionObj

		
        Assert-AreEqual $rgName $bastionObj.ResourceGroupName
        Assert-AreEqual $bastionName $bastionObj.Name
        Assert-NotNull $bastionObj.Etag
        Assert-AreEqual 1 @($bastionObj.IpConfigurations).Count
        Assert-NotNull $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-NotNull $bastionObj.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $subnet.Id $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip.Id $bastionObj.IpConfigurations[0].PublicIpAddress.Id

		
        $bastions = Get-AzBastion -ResourceGroupName $rgName
        Assert-NotNull $bastions

		
        $bastionsAll = Get-AzBastion
        Assert-NotNull $bastionsAll
       
	   
        $delete = Remove-AzBastion -ResourceGroupName $rgname -Name $bastionName -PassThru -Force
		Assert-AreEqual true $delete

		
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

		$list = Get-AzBastion -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
	}
	finally
	{
		
		Clean-ResourceGroup $rgname
	}
}


function Test-BastionVnetsIpObjectsParams
{

   
    $rgname = Get-ResourceGroupName
    $bastionName = Get-ResourceName
	$resourceTypeParent = "Microsoft.Network/bastionHosts"
    $location = Get-ProviderLocation $resourceTypeParent

    $vnetName = Get-ResourceName
    $subnetName = "AzureBastionSubnet"
    $publicIpName = Get-ResourceName
    
	try
	{
		
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location

		
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

		
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard
		
		 
        $bastion = New-AzBastion -ResourceGroupName $rgname –Name $bastionName -PublicIpAddress $publicip -VirtualNetwork $vnet

		
		$bastionObj = Get-AzBastion -ResourceGroupName $rgname -Name $bastionName
        Assert-NotNull $bastionObj
		
		
        Assert-AreEqual $rgName $bastionObj.ResourceGroupName
        Assert-AreEqual $bastionName $bastionObj.Name
        Assert-NotNull $bastionObj.Etag
        Assert-AreEqual 1 @($bastionObj.IpConfigurations).Count
        Assert-NotNull $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-NotNull $bastionObj.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $subnet.Id $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip.Id $bastionObj.IpConfigurations[0].PublicIpAddress.Id

		
        $delete = Remove-AzBastion -ResourceGroupName $rgname -Name $bastionName -PassThru -Force
		Assert-AreEqual true $delete

		
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

		$list = Get-AzBastion -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
	}
	finally
	{
		
		Clean-ResourceGroup $rgname
	}
}

function Test-BastionVnetObjectParam
{

   
    $rgname = Get-ResourceGroupName
    $bastionName = Get-ResourceName
	$resourceTypeParent = "Microsoft.Network/bastionHosts"
    $location = Get-ProviderLocation $resourceTypeParent

    $vnetName = Get-ResourceName
    $subnetName = "AzureBastionSubnet"
    $publicIpName = Get-ResourceName
    
	try
	{
		
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location

		
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

		
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard
		
		 
        $bastion = New-AzBastion -ResourceGroupName $rgname –Name $bastionName -PublicIpAddressRgName $rgname -PublicIpAddressName $publicIpName -VirtualNetwork $vnet

		
		$bastionObj = Get-AzBastion -ResourceGroupName $rgname -Name $bastionName
        Assert-NotNull $bastionObj
		
		
        Assert-AreEqual $rgName $bastionObj.ResourceGroupName
        Assert-AreEqual $bastionName $bastionObj.Name
        Assert-NotNull $bastionObj.Etag
        Assert-AreEqual 1 @($bastionObj.IpConfigurations).Count
        Assert-NotNull $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-NotNull $bastionObj.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $subnet.Id $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip.Id $bastionObj.IpConfigurations[0].PublicIpAddress.Id

		
        $delete = Remove-AzBastion -InputObject $bastionObj -PassThru -Force
		Assert-AreEqual true $delete

		
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

		$list = Get-AzBastion -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
	}
	finally
	{
		
		Clean-ResourceGroup $rgname
	}
}

function Test-BastionIpObjectParam
{

   
    $rgname = Get-ResourceGroupName
    $bastionName = Get-ResourceName
	$resourceTypeParent = "Microsoft.Network/bastionHosts"
    $location = Get-ProviderLocation $resourceTypeParent

    $vnetName = Get-ResourceName
    $subnetName = "AzureBastionSubnet"
    $publicIpName = Get-ResourceName
    
	try
	{
		
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location

		
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

		
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard
		
		 
        $bastion = New-AzBastion -ResourceGroupName $rgname –Name $bastionName -PublicIpAddress $publicip -VirtualNetworkRgName $rgname -VirtualNetworkName $vnetName

		
		$bastionObj = Get-AzBastion -ResourceGroupName $rgname -Name $bastionName
        Assert-NotNull $bastionObj
		
		
        Assert-AreEqual $rgName $bastionObj.ResourceGroupName
        Assert-AreEqual $bastionName $bastionObj.Name
        Assert-NotNull $bastionObj.Etag
        Assert-AreEqual 1 @($bastionObj.IpConfigurations).Count
        Assert-NotNull $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-NotNull $bastionObj.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $subnet.Id $bastionObj.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip.Id $bastionObj.IpConfigurations[0].PublicIpAddress.Id

		
        $delete = Remove-AzBastion -InputObject $bastionObj -PassThru -Force
		Assert-AreEqual true $delete

		
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

		$list = Get-AzBastion -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
	}
	finally
	{
		
		Clean-ResourceGroup $rgname
	}
}
