














function Test-ListServerAdvisors
{
	
	$rg = Create-ResourceGroupForTest
	$server = SetupServer $rg

	try
	{
		$response = Get-AzSqlServerAdvisor `
			-ResourceGroupName $server.ResourceGroupName `
			-ServerName $server.ServerName
		Assert-NotNull $response
		ValidateAdvisorCount $response
		foreach($advisor in $response)
		{
			ValidateServer $advisor $server
			ValidateAdvisorProperties $advisor
		}
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-ListServerAdvisorsExpanded
{
	
	$rg = Create-ResourceGroupForTest
	$server = SetupServer $rg

	try
	{
		$response = Get-AzSqlServerAdvisor `
			-ResourceGroupName $server.ResourceGroupName `
			-ServerName $server.ServerName -ExpandRecommendedActions `
			-AdvisorName *
		Assert-NotNull $response
		ValidateAdvisorCount $response
		foreach($advisor in $response)
		{
			ValidateServer $advisor $server
			ValidateAdvisorProperties $advisor
		}
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetServerAdvisor
{
	
	$rg = Create-ResourceGroupForTest
	$server = SetupServer $rg

	try
	{
		$response = Get-AzSqlServerAdvisor `
			-ResourceGroupName $server.ResourceGroupName `
			-ServerName $server.ServerName -AdvisorName CreateIndex
		Assert-NotNull $response
		ValidateServer $response $server
		ValidateAdvisorProperties $response
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateServerAdvisor
{
	
	$rg = Create-ResourceGroupForTest
	$server = SetupServer $rg

	try
	{
		$response = Set-AzSqlServerAdvisorAutoExecuteStatus `
			-ResourceGroupName $server.ResourceGroupName `
			-ServerName $server.ServerName `
			-AdvisorName CreateIndex `
			-AutoExecuteStatus Disabled
		Assert-NotNull $response
		ValidateServer $response $server
		ValidateAdvisorProperties $response
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-ListDatabaseAdvisors
{
	
	$rg = Create-ResourceGroupForTest
	$db = SetupDatabase $rg

	try
	{
		$response = Get-AzSqlDatabaseAdvisor `
			-ResourceGroupName $db.ResourceGroupName `
			-ServerName $db.ServerName `
			-DatabaseName $db.DatabaseName `
			-AdvisorName *
		Assert-NotNull $response
		ValidateAdvisorCount $response
		foreach($advisor in $response)
		{
			ValidateDatabase $advisor $db
			ValidateAdvisorProperties $advisor
		}
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-ListDatabaseAdvisorsExpanded
{
	
	$rg = Create-ResourceGroupForTest
	$db = SetupDatabase $rg

	try
	{
		$response = Get-AzSqlDatabaseAdvisor `
			-ResourceGroupName $db.ResourceGroupName `
			-ServerName $db.ServerName `
			-DatabaseName $db.DatabaseName `
			-ExpandRecommendedActions
		Assert-NotNull $response
		ValidateAdvisorCount $response
		foreach($advisor in $response)
		{
			ValidateDatabase $advisor $db
			ValidateAdvisorProperties $advisor
		}
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetDatabaseAdvisor
{
	
	$rg = Create-ResourceGroupForTest
	$db = SetupDatabase $rg

	try
	{
		$response = Get-AzSqlDatabaseAdvisor `
			-ResourceGroupName $db.ResourceGroupName `
			-ServerName $db.ServerName `
			-DatabaseName $db.DatabaseName `
			-AdvisorName CreateIndex
		Assert-NotNull $response
		ValidateDatabase $response $db
		ValidateAdvisorProperties $response
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateDatabaseAdvisor
{
	
	$rg = Create-ResourceGroupForTest
	$db = SetupDatabase $rg

	try
	{
		$response = Set-AzSqlDatabaseAdvisorAutoExecuteStatus `
			-ResourceGroupName $db.ResourceGroupName `
			-ServerName $db.ServerName `
			-DatabaseName $db.DatabaseName `
			-AdvisorName CreateIndex `
			-AutoExecuteStatus Disabled
		Assert-NotNull $response
		ValidateDatabase $response $db
		ValidateAdvisorProperties $response
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ListElasticPoolAdvisors
{
	
	$rg = Create-ResourceGroupForTest
	$ep = SetupElasticPool $rg

	try
	{
		$response = Get-AzSqlElasticPoolAdvisor `
			-ResourceGroupName $ep.ResourceGroupName`
			-ServerName $ep.ServerName`
			-ElasticPoolName $ep.ElasticPoolName `
			-AdvisorName *
		Assert-NotNull $response
		ValidateAdvisorCount $response
		foreach($advisor in $response)
		{
			ValidateElasticPool $advisor $ep
			ValidateAdvisorProperties $advisor
		}
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-ListElasticPoolAdvisorsExpanded
{
	
	$rg = Create-ResourceGroupForTest
	$ep = SetupElasticPool $rg

	try
	{
		$response = Get-AzSqlElasticPoolAdvisor `
			-ResourceGroupName $ep.ResourceGroupName `
			-ServerName $ep.ServerName `
			-ElasticPoolName $ep.ElasticPoolName `
			-ExpandRecommendedActions
		Assert-NotNull $response
		ValidateAdvisorCount $response
		foreach($advisor in $response)
		{
			ValidateElasticPool $advisor $ep
			ValidateAdvisorProperties $advisor
		}
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetElasticPoolAdvisor
{
	
	$rg = Create-ResourceGroupForTest
	$ep = SetupElasticPool $rg

	try
	{
		$response = Get-AzSqlElasticPoolAdvisor `
			-ResourceGroupName $ep.ResourceGroupName `
			-ServerName $ep.ServerName `
			-ElasticPoolName $ep.ElasticPoolName `
			-AdvisorName CreateIndex
		Assert-NotNull $response
		ValidateElasticPool $response $ep
		ValidateAdvisorProperties $response
	}
	finally
	{
		
		Remove-ResourceGroupForTest $rg
	}
}


function SetupServer($resourceGroup)
{
	$location = "Southeast Asia"
	$server = Create-ServerForTest $resourceGroup $location
	return $server
}


function SetupDatabase($resourceGroup)
{
	$server = SetupServer $resourceGroup
	$databaseName = Get-DatabaseName
	$db = New-AzSqlDatabase `
		-ResourceGroupName $server.ResourceGroupName `
		-ServerName $server.ServerName `
		-DatabaseName $databaseName `
		-Edition Basic
	return $db
}


function SetupElasticPool($resourceGroup)
{
	$server = SetupServer $resourceGroup
	$poolName = Get-ElasticPoolName
	$ep = New-AzSqlElasticPool `
		-ServerName $server.ServerName `
		-ResourceGroupName $server.ResourceGroupName `
		-ElasticPoolName $poolName -Edition Basic
	return $ep
}


function ValidateServer($responseAdvisor, $expectedServer)
{
	Assert-AreEqual $responseAdvisor.ResourceGroupName $expectedServer.ResourceGroupName
	Assert-AreEqual $responseAdvisor.ServerName $expectedServer.ServerName
}


function ValidateDatabase($responseAdvisor, $expectedDatabase)
{
	Assert-AreEqual $responseAdvisor.ResourceGroupName $expectedDatabase.ResourceGroupName
	Assert-AreEqual $responseAdvisor.ServerName $expectedDatabase.ServerName
	Assert-AreEqual $responseAdvisor.DatabaseName $expectedDatabase.DatabaseName
}


function ValidateElasticPool($responseAdvisor, $expectedElasticPool)
{
	Assert-AreEqual $responseAdvisor.ResourceGroupName $expectedElasticPool.ResourceGroupName
	Assert-AreEqual $responseAdvisor.ServerName $expectedElasticPool.ServerName
	Assert-AreEqual $responseAdvisor.ElasticPoolName $expectedElasticPool.ElasticPoolName
}


function ValidateAdvisorProperties($advisor, $expanded = $false)
{
	Assert-True {($advisor.AdvisorStatus -eq "GA") `
		-or ($advisor.AdvisorStatus -eq "PublicPreview") `
		-or ($advisor.AdvisorStatus -eq "PrivatePreview")}
	Assert-AreEqual "Disabled" $advisor.AutoExecuteStatus
	Assert-True {($advisor.AutoExecuteStatusInheritedFrom -eq "Default") -or `
		($advisor.AutoExecuteStatusInheritedFrom -eq "Server") -or `
		($advisor.AutoExecuteStatusInheritedFrom -eq "ElasticPool") -or `
		($advisor.AutoExecuteStatusInheritedFrom -eq "Database")}
}


function ValidateAdvisorCount($response)
{
	$expectedMinAdvisorCount = 4
	Assert-True { $response.Count -ge $expectedMinAdvisorCount } "Advisor count was $($response.Count), expected at least $expectedMinAdvisorCount. Response: $response"
}