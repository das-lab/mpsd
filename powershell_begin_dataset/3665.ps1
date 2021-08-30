














function Test-CreateUpdateDatabaseReadScale ($serverVersion = "12.0", $location = "Southeast Asia")
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location
	
	
	$databaseName1 = Get-DatabaseName
	$db1 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName1 -Edition Premium
	Assert-AreEqual $db1.DatabaseName $databaseName1
	
	try
	{
		
		$db1 = Set-AzSqlDatabase -ResourceGroupName $db1.ResourceGroupName -ServerName $db1.ServerName -DatabaseName $db1.DatabaseName -ReadScale Disabled
		Assert-AreEqual Disabled $db1.ReadScale
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-GetDatabaseReadScale ($serverVersion = "12.0", $location = "Southeast Asia")
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location
	
	
	$databaseName = Get-DatabaseName
	$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -Edition Premium
	Assert-AreEqual $db.DatabaseName $databaseName

	try
	{
		$db1 = Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupname -ServerName $server.ServerName -DatabaseName $db.DatabaseName
		Assert-AreEqual Enabled $db1.ReadScale
		Assert-AreEqual 1 $db1.ReadReplicaCount

		
		$db2 = Set-AzSqlDatabase -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName `
			-ReadScale Disabled -ReadReplicaCount -1
		Assert-AreEqual Disabled $db2.ReadScale
		Assert-AreEqual 0 $db2.ReadReplicaCount
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-DatabaseReadReplicaCount ($serverVersion = "12.0", $location = "Southeast Asia")
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location
	
	
	$databaseName = Get-DatabaseName
	$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -Edition Hyperscale `
		-VCore 4 -ComputeGeneration Gen5
	Assert-AreEqual $db.DatabaseName $databaseName

	try
	{
		$db1 = Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupname -ServerName $server.ServerName -DatabaseName $db.DatabaseName
		Assert-AreEqual Enabled $db1.ReadScale
		Assert-AreEqual 1 $db1.ReadReplicaCount

		
		$db2 = Set-AzSqlDatabase -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName `
			-ReadScale Enabled -ReadReplicaCount 0
		Assert-AreEqual Disabled $db2.ReadScale
		Assert-AreEqual 0 $db2.ReadReplicaCount
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}