














function Test-GetVirtualCluster
{
	
	$location = Get-ProviderLocation "Microsoft.Sql/virtualclusters"
	$rg = Create-ResourceGroupForTest $location

	$rgName = $rg.ResourceGroupName
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $location $rgName
	$subnetId = $virtualNetwork.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId

	try
	{
		
		$virtualClusterList = Get-AzSqlVirtualCluster
		$virtualCluster = $virtualClusterList.where({$_.SubnetId -eq $subnetId})
		Assert-AreEqual $rgName $virtualCluster.ResourceGroupName
		$virtualClusterName = $virtualCluster.VirtualClusterName

		$virtualClusterList = Get-AzSqlVirtualCluster -ResourceGroupName $rgName
		$virtualCluster = $virtualClusterList.where({$_.SubnetId -eq $subnetId})
		Assert-AreEqual $rgName $virtualCluster.ResourceGroupName
		Assert-AreEqual $virtualClusterName $virtualCluster.VirtualClusterName

		$virtualCluster = Get-AzSqlVirtualCluster -ResourceGroupName $rgName -Name $virtualClusterName
		Assert-AreEqual $rgName $virtualCluster.ResourceGroupName
		Assert-AreEqual $virtualClusterName $virtualCluster.VirtualClusterName
		Assert-AreEqual $subnetId $virtualCluster.SubnetId
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RemoveVirtualCluster
{
	
	$location = Get-ProviderLocation "Microsoft.Sql/virtualclusters"
	$rg = Create-ResourceGroupForTest $location

	$rgName = $rg.ResourceGroupName
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $location $rgName
	$subnetId = $virtualNetwork.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId

	try
	{
		$virtualClusterList = Get-AzSqlVirtualCluster -ResourceGroupName $rgName
		$virtualCluster = $virtualClusterList.where({$_.SubnetId -eq $subnetId})
		$virtualClusterName = $virtualCluster.VirtualClusterName

		
		$managedInstance | Remove-AzSqlInstance -Force

		
		$virtualCluster | Remove-AzSqlVirtualCluster

		$all = Get-AzSqlVirtualCluster -ResourceGroupName $rgName
		$virtualCluster = $all.where({$_.VirtualClusterName -eq $virtualClusterName})
		Assert-AreEqual $virtualCluster.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
