














function Test-CreateStretchDatabase
{
	$rplocation = Get-ProviderLocation "Microsoft.Sql/servers"
	Test-CreateDatabaseInternal "12.0" $rplocation
}


function Test-CreateDatabaseInternal ($serverVersion, $location = "westcentralus")
{
	
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		$collationName = "SQL_Latin1_General_CP1_CI_AS"
		$maxSizeBytes = 250GB
		$job = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
				-CollationName $collationName -MaxSizeBytes $maxSizeBytes -Edition Stretch -RequestedServiceObjectiveName DS100 -AsJob
		$job | Wait-Job
		$strechdb = $job.Output

		Assert-AreEqual $databaseName $strechdb.DatabaseName 
		Assert-AreEqual $maxSizeBytes $strechdb.MaxSizeBytes 
		Assert-AreEqual Stretch $strechdb.Edition 
		Assert-AreEqual DS100 $strechdb.CurrentServiceObjectiveName
		Assert-AreEqual $collationName $strechdb.CollationName 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateStretchDatabase
{
	$rplocation = Get-ProviderLocation "Microsoft.Sql/servers"
	Test-UpdateDatabaseInternal "12.0" $rplocation
}


function Test-UpdateDatabaseInternal ($serverVersion, $location = "westcentralus")
{
	
		$rg = Create-ResourceGroupForTest $location
		$server = Create-ServerForTest $rg $location
	try {
		
		$databaseName = Get-DatabaseName
		$collationName = "SQL_Latin1_General_CP1_CI_AS"
		$maxSizeBytes = 250GB
		$strechdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
		-CollationName $collationName -MaxSizeBytes $maxSizeBytes -Edition Stretch -RequestedServiceObjectiveName DS100

		
		$job = Set-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $strechdb.DatabaseName `
		-MaxSizeBytes $maxSizeBytes -Edition Stretch -RequestedServiceObjectiveName DS200 -AsJob
		$job | Wait-Job
		$strechdb2 = $job.Output

		Assert-AreEqual $strechdb.DatabaseName $strechdb2.DatabaseName
		Assert-AreEqual $maxSizeBytes $strechdb2.MaxSizeBytes
		Assert-AreEqual Stretch $strechdb2.Edition
		Assert-AreEqual DS200 $strechdb2.CurrentServiceObjectiveName
		Assert-AreEqual $collationName $strechdb2.CollationName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-GetStretchDatabase
{
	$rplocation = Get-ProviderLocation "Microsoft.Sql/servers"
	Test-GetDatabaseInternal "12.0" $rplocation
}


function Test-GetDatabaseInternal  ($serverVersion, $location = "westcentralus")
{
	
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		$strechdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
				-CollationName SQL_Latin1_General_CP1_CI_AS -MaxSizeBytes 250GB -Edition Stretch -RequestedServiceObjectiveName DS100
		$strechdb2 = Get-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupname -ServerName $server.ServerName -DatabaseName $strechdb.DatabaseName
		Assert-AreEqual $strechdb.DatabaseName $strechdb2.DatabaseName
		Assert-AreEqual $strechdb.MaxSizeBytes $strechdb2.MaxSizeBytes
		Assert-AreEqual $strechdb.Edition $strechdb2.Edition
		Assert-AreEqual $strechdb.CurrentServiceObjectiveName $strechdb2.CurrentServiceObjectiveName
		Assert-AreEqual $strechdb.CollationName $strechdb2.CollationName

		
		$all = $server | Get-AzSqlDatabase
		Assert-AreEqual $all.Count 2 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-RemoveStretchDatabase
{
	$rplocation = Get-ProviderLocation "Microsoft.Sql/servers"
	Test-RemoveDatabaseInternal "12.0" $rplocation
}


function Test-RemoveDatabaseInternal  ($serverVersion, $location = "westcentralus")
{
	
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		$stretchdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-CollationName "SQL_Latin1_General_CP1_CI_AS" -MaxSizeBytes 250GB -Edition Stretch -RequestedServiceObjectiveName DS100
		Assert-AreEqual $databaseName $stretchdb.DatabaseName

		
		Remove-AzSqlDatabase -ResourceGroupName $server.ResourceGroupname -ServerName $server.ServerName -DatabaseName $stretchdb.DatabaseName -Force
		
		
		$all = $server | Get-AzSqlDatabase
		Assert-AreEqual $all.Count 1 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}