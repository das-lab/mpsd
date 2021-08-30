














function Test-DatabasePauseResume
{
	
	$location = "Southeast Asia"
	$serverVersion = "12.0";
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location

	
	$databaseName = Get-DatabaseName
	$collationName = "SQL_Latin1_General_CP1_CI_AS"
	$maxSizeBytes = 250GB
	$dwdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
		-CollationName $collationName -MaxSizeBytes $maxSizeBytes -Edition DataWarehouse -RequestedServiceObjectiveName DW100

	try
	{
		
		$dwdb2 = Suspend-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName
		Assert-AreEqual $dwdb2.DatabaseName $databaseName
		Assert-AreEqual $dwdb2.MaxSizeBytes $maxSizeBytes
		Assert-AreEqual $dwdb2.Edition DataWarehouse
		Assert-AreEqual $dwdb2.CurrentServiceObjectiveName DW100
		Assert-AreEqual $dwdb2.CollationName $collationName
		Assert-AreEqual $dwdb2.Status "Paused"
		
		
		$job = Resume-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName -AsJob
		$job | Wait-Job
		$dwdb3 = $job.Output

		Assert-AreEqual $dwdb3.DatabaseName $databaseName
		Assert-AreEqual $dwdb3.MaxSizeBytes $maxSizeBytes
		Assert-AreEqual $dwdb3.Edition DataWarehouse
		Assert-AreEqual $dwdb3.CurrentServiceObjectiveName DW100
		Assert-AreEqual $dwdb3.CollationName $collationName
		Assert-AreEqual $dwdb3.Status "Online"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-DatabasePauseResumePiped
{
	
	$location = "westcentralus"
	$serverVersion = "12.0";
	$rg = Create-ResourceGroupForTest

	try
	{
		$server = Create-ServerForTest $rg $location

		
		$databaseName = Get-DatabaseName
		$collationName = "SQL_Latin1_General_CP1_CI_AS"
		$maxSizeBytes = 250GB
		$dwdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-CollationName $collationName -MaxSizeBytes $maxSizeBytes -Edition DataWarehouse -RequestedServiceObjectiveName DW100


		
		$job = $dwdb | Suspend-AzSqlDatabase -AsJob
		$job | Wait-Job
		$dwdb2 = $job.Output

		Assert-AreEqual $dwdb2.DatabaseName $databaseName
		Assert-AreEqual $dwdb2.MaxSizeBytes $maxSizeBytes
		Assert-AreEqual $dwdb2.Edition DataWarehouse
		Assert-AreEqual $dwdb2.CurrentServiceObjectiveName DW100
		Assert-AreEqual $dwdb2.CollationName $collationName
		Assert-AreEqual $dwdb2.Status "Paused"
		
		
		$dwdb3 = $dwdb2 | Resume-AzSqlDatabase
		Assert-AreEqual $dwdb3.DatabaseName $databaseName
		Assert-AreEqual $dwdb3.MaxSizeBytes $maxSizeBytes
		Assert-AreEqual $dwdb3.Edition DataWarehouse
		Assert-AreEqual $dwdb3.CurrentServiceObjectiveName DW100
		Assert-AreEqual $dwdb3.CollationName $collationName
		Assert-AreEqual $dwdb3.Status "Online"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}