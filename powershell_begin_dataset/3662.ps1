














function Test-ServerActiveDirectoryAdministrator ($location = "North Europe")
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg "12.0" $location
	
	try
	{
		$activeDirectoryGroup1 = "testAADaccount"
		$activeDirectoryGroup1ObjectId = "41732a4a-e09e-4b18-9624-38e252d68bbf"
		$activeDirectoryUser1 = "Test User 2"
		$activeDirectoryUser1ObjectId = "e87332b2-e3ed-480a-9723-e9b3611268f8"

		
		$activeDirectoryAdmin = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName

		Assert-Null $activeDirectoryAdmin

			
		$activeDirectoryAdmin1 = Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
		-DisplayName $activeDirectoryGroup1

		Assert-NotNull $activeDirectoryAdmin1

		
		Assert-AreEqual $activeDirectoryAdmin1.DisplayName $activeDirectoryGroup1
		Assert-AreEqual $activeDirectoryAdmin1.ObjectId $activeDirectoryGroup1ObjectId

		
		$activeDirectoryAdmin2 = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName

		Assert-AreEqual $activeDirectoryAdmin2.DisplayName $activeDirectoryGroup1
		Assert-AreEqual $activeDirectoryAdmin2.ObjectId $activeDirectoryGroup1ObjectId

		
		$activeDirectoryAdmin3 = Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
		-DisplayName $activeDirectoryUser1

		Assert-AreEqual $activeDirectoryAdmin3.DisplayName $activeDirectoryUser1
		Assert-AreEqual $activeDirectoryAdmin3.ObjectId $activeDirectoryUser1ObjectId

		
		$activeDirectoryAdmin4 = Remove-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -Force

		
		$activeDirectoryAdmin5 = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName

		Assert-Null $activeDirectoryAdmin5
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

