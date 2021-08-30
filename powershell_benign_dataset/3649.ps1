














function Test-ManagedInstanceActiveDirectoryAdministrator
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId
        
	
	$activeDirectoryGroup1 = "aadadmin"
	$activeDirectoryGroup1ObjectId = "52b6d571-5ff9-4b8f-92de-4a5b1bcdbbef"
	$activeDirectoryUser1 = "CL AAD Test User"
	$activeDirectoryUser1ObjectId = "034bb7d9-ca26-4c6f-abe0-4aff74fdca50"

	try
	{
		
		$activeDirectoryAdmin = Get-AzSqlInstanceActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName

		Assert-Null $activeDirectoryAdmin

		
		
		
		$activeDirectoryAdmin1 = Set-AzSqlInstanceActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DisplayName $activeDirectoryGroup1 -ObjectId $activeDirectoryGroup1ObjectId

		Assert-NotNull $activeDirectoryAdmin1

		
		Assert-AreEqual $activeDirectoryAdmin1.DisplayName $activeDirectoryGroup1
		Assert-AreEqual $activeDirectoryAdmin1.ObjectId $activeDirectoryGroup1ObjectId

		
		$activeDirectoryAdmin2 = Get-AzSqlInstanceActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName

		Assert-AreEqual $activeDirectoryAdmin2.DisplayName $activeDirectoryGroup1
		Assert-AreEqual $activeDirectoryAdmin2.ObjectId $activeDirectoryGroup1ObjectId

		
		$activeDirectoryAdmin3 = Set-AzSqlInstanceActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DisplayName $activeDirectoryUser1 -ObjectId $activeDirectoryUser1ObjectId

		Assert-AreEqual $activeDirectoryAdmin3.DisplayName $activeDirectoryUser1
		Assert-AreEqual $activeDirectoryAdmin3.ObjectId $activeDirectoryUser1ObjectId

		
		$activeDirectoryAdmin4 = Remove-AzSqlInstanceActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Force

		
		$activeDirectoryAdmin5 = Get-AzSqlInstanceActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName

		Assert-Null $activeDirectoryAdmin5
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
