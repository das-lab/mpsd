














function Test-FailoverDatabase
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

		
		$job = Invoke-AzSqlDatabaseFailover -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -AsJob
		$job | Wait-Job
		
		
		
		try {
			Invoke-AzSqlDatabaseFailover -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
		} catch {
			$ErrorMessage = $_.Exception.Message
			Assert-AreEqual True $ErrorMessage.Contains("There was a recent failover on the database or pool")
		}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-FailoverDatabasePassThru
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

		
		$output = Invoke-AzSqlDatabaseFailover -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -PassThru
		Assert-True { $output }
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-FailoverDatabaseWithDatabasePiping
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

		
		Get-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName | Invoke-AzSqlDatabaseFailover
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-FailoverDatabaseWithServerPiping
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

		
		Get-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName | Invoke-AzSqlDatabaseFailover -DatabaseName $databaseName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-FailoverElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $poolName

		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -ElasticPoolName $poolName

		
		$job = Invoke-AzSqlElasticPoolFailover -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $poolName -AsJob
		$job | Wait-Job

		
		
		try {
			Invoke-AzSqlElasticPoolFailover -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $poolName
		} catch {
			$ErrorMessage = $_.Exception.Message
			Assert-AreEqual True $ErrorMessage.Contains("There was a recent failover on the elastic pool")
		}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-FailoverElasticPoolPassThru
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $poolName

		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -ElasticPoolName $poolName

		
		$output = Invoke-AzSqlElasticPoolFailover -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $poolName -PassThru
		Assert-True { $output }
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-FailoverElasticPoolWithPoolPiping
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $poolName

		
		$databaseName = Get-DatabaseName
		New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -ElasticPoolName $poolName

		
		Get-AzSqlElasticPool -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $poolName | Invoke-AzSqlElasticPoolFailover
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}