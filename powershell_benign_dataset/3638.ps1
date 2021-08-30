














function Test-CreateAndUpdateVirtualNetworkRule
{
	
	$location = "East US 2"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	$virtualNetworkRuleName = Get-VirtualNetworkRuleName

	$vnetName1 = "vnet1"
	$virtualNetwork1 = CreateAndGetVirtualNetwork $rg $vnetName1 $location
	$virtualNetworkSubnetId1 = $virtualNetwork1.Subnets[0].Id

	$vnetName2 = "vnet2"
	$virtualNetwork2 = CreateAndGetVirtualNetwork $rg $vnetName2 $location
	$virtualNetworkSubnetId2 = $virtualNetwork2.Subnets[0].Id

	try
	{
		
		$job = New-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
			-VirtualNetworkRuleName $virtualNetworkRuleName -VirtualNetworkSubnetId $virtualNetworkSubnetId1 -IgnoreMissingVnetServiceEndpoint `
			-AsJob
		$job | Wait-Job
		$virtualNetworkRule = $job.Output

		Assert-AreEqual $virtualNetworkRule.ServerName $server.ServerName
		Assert-AreEqual $virtualNetworkRule.VirtualNetworkRuleName $virtualNetworkRuleName
		Assert-AreEqual $virtualNetworkRule.VirtualNetworkSubnetId $virtualNetworkSubnetId1

		
		$job = Set-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
			-VirtualNetworkRuleName $virtualNetworkRuleName -VirtualNetworkSubnetId $virtualNetworkSubnetId2 -IgnoreMissingVnetServiceEndpoint `
			-AsJob
		$job | Wait-Job
		$virtualNetworkRule = $job.Output

		Assert-AreEqual $virtualNetworkRule.ServerName $server.ServerName
		Assert-AreEqual $virtualNetworkRule.VirtualNetworkRuleName $virtualNetworkRuleName
		Assert-AreEqual $virtualNetworkRule.VirtualNetworkSubnetId $virtualNetworkSubnetId2
	}
	finally
	{
		
		Remove-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -VirtualNetworkRuleName $virtualNetworkRuleName
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetVirtualNetworkRule
{
	
	$location = "East US 2"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	$virtualNetworkRuleName1 = Get-VirtualNetworkRuleName
	$vnetName1 = "vnet1"
	$virtualNetwork1 = CreateAndGetVirtualNetwork $rg $vnetName1 $location
	$virtualNetworkSubnetId1 = $virtualNetwork1.Subnets[0].Id

	$virtualNetworkRuleName2 = Get-VirtualNetworkRuleName
	$vnetName2 = "vnet2"
	$virtualNetwork2 = CreateAndGetVirtualNetwork $rg $vnetName2 $location
	$virtualNetworkSubnetId2 = $virtualNetwork2.Subnets[0].Id

	try
	{
		
		$virtualNetworkRule1 = New-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
		-VirtualNetworkRuleName $virtualNetworkRuleName1 -VirtualNetworkSubnetId $virtualNetworkSubnetId1 -IgnoreMissingVnetServiceEndpoint
		Assert-AreEqual $virtualNetworkRule1.ServerName $server.ServerName
		Assert-AreEqual $virtualNetworkRule1.VirtualNetworkRuleName $virtualNetworkRuleName1
		Assert-AreEqual $virtualNetworkRule1.VirtualNetworkSubnetId $virtualNetworkSubnetId1

		
		$virtualNetworkRule2 = New-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
		-VirtualNetworkRuleName $virtualNetworkRuleName2 -VirtualNetworkSubnetId $virtualNetworkSubnetId2 -IgnoreMissingVnetServiceEndpoint
		Assert-AreEqual $virtualNetworkRule2.ServerName $server.ServerName
		Assert-AreEqual $virtualNetworkRule2.VirtualNetworkRuleName $virtualNetworkRuleName2
		Assert-AreEqual $virtualNetworkRule2.VirtualNetworkSubnetId $virtualNetworkSubnetId2

		
		$resp = Get-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -VirtualNetworkRuleName $virtualNetworkRuleName1
		Assert-AreEqual $resp.VirtualNetworkSubnetId $virtualNetworkSubnetId1

		
		$resp = Get-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -VirtualNetworkRuleName *
		Assert-AreEqual $resp.Count 2
	}
	finally
	{
		
		Remove-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -VirtualNetworkRuleName $virtualNetworkRuleName1
		Remove-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -VirtualNetworkRuleName $virtualNetworkRuleName2
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RemoveVirtualNetworkRule
{
	
	$location = "East US 2 EUAP"
	$rg = Create-ResourceGroupForTest $location

	$virtualNetworkRuleName = Get-VirtualNetworkRuleName
	$vnetName = "vnet1"
	$virtualNetwork = CreateAndGetVirtualNetwork $rg $vnetName $location
	$virtualNetworkSubnetId = $virtualNetwork.Subnets[0].Id

	$server = Create-ServerForTest $rg $location

	try
	{
		
		$virtualNetworkRule = New-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
		-VirtualNetworkRuleName $virtualNetworkRuleName -VirtualNetworkSubnetId $virtualNetworkSubnetId -IgnoreMissingVnetServiceEndpoint
		Assert-AreEqual $virtualNetworkRule.ServerName $server.ServerName
		Assert-AreEqual $virtualNetworkRule.VirtualNetworkRuleName $virtualNetworkRuleName
		Assert-AreEqual $virtualNetworkRule.VirtualNetworkSubnetId $virtualNetworkSubnetId

		
		$job = Remove-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
			-VirtualNetworkRuleName $virtualNetworkRuleName -AsJob
		$job | Wait-Job
		$resp = $job.Output

		$all = Get-AzSqlServerVirtualNetworkRule -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function CreateAndGetVirtualNetwork ($resourceGroup, $vnetName, $location = "westcentralus")
{
	$subnetName = "Public"

	$addressPrefix = "10.0.0.0/24"
	$serviceEndpoint = "Microsoft.Sql"

	$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $addressPrefix -ServiceEndpoint $serviceEndpoint
	$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

	$getVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup.ResourceGroupName

	return $getVnet
}
