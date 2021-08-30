














function Test-CreateDatabaseCopy()
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location
	$database = Create-DatabaseForTest $rg $server "Standard"

	$copyRg = Create-ResourceGroupForTest $location
	$copyServer = Create-ServerForTest $copyRg $location
	$copyDatabaseName = Get-DatabaseName

	try
	{
		
		$job = New-AzSqlDatabaseCopy -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
		 -CopyDatabaseName $copyDatabaseName -AsJob
		$job | Wait-Job
		$dbLocalCopy = $job.Output

		Assert-AreEqual $dbLocalCopy.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $dbLocalCopy.ServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.DatabaseName $database.DatabaseName
		Assert-AreEqual $dbLocalCopy.CopyResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $dbLocalCopy.CopyServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.CopyDatabaseName $copyDatabaseName

		
		$dbCrossServerCopy = New-AzSqlDatabaseCopy -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
		 -CopyResourceGroupName $copyRg.ResourceGroupName -CopyServerName $copyServer.ServerName -CopyDatabaseName $copyDatabaseName
		Assert-AreEqual $dbCrossServerCopy.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $dbCrossServerCopy.ServerName $server.ServerName
		Assert-AreEqual $dbCrossServerCopy.DatabaseName $database.DatabaseName
		Assert-AreEqual $dbCrossServerCopy.CopyResourceGroupName $copyRg.ResourceGroupName
		Assert-AreEqual $dbCrossServerCopy.CopyServerName $copyServer.ServerName
		Assert-AreEqual $dbCrossServerCopy.CopyDatabaseName $copyDatabaseName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $copyRg
	}
}


function Test-CreateVcoreDatabaseCopy()
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location
	$db = Create-VcoreDatabaseForTest $rg $server 1 BasePrice

	try
	{
		
		$copyDatabaseName = Get-DatabaseName
		$dbLocalCopy = New-AzSqlDatabaseCopy -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName -CopyDatabaseName $copyDatabaseName

		Assert-AreEqual $dbLocalCopy.ServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.DatabaseName $db.DatabaseName
		Assert-AreEqual $dbLocalCopy.LicenseType BasePrice 
		Assert-AreEqual $dbLocalCopy.CopyResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $dbLocalCopy.CopyServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.CopyDatabaseName $copyDatabaseName


		
		$copyDatabaseName = Get-DatabaseName
		$dbLocalCopy = New-AzSqlDatabaseCopy -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName -CopyDatabaseName $copyDatabaseName -LicenseType BasePrice

		Assert-AreEqual $dbLocalCopy.ServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.DatabaseName $db.DatabaseName
		Assert-AreEqual $dbLocalCopy.LicenseType BasePrice 
		Assert-AreEqual $dbLocalCopy.CopyResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $dbLocalCopy.CopyServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.CopyDatabaseName $copyDatabaseName

		
		$copyDatabaseName = Get-DatabaseName
		$dbLocalCopy = New-AzSqlDatabaseCopy -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName -CopyDatabaseName $copyDatabaseName -LicenseType LicenseIncluded

		Assert-AreEqual $dbLocalCopy.ServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.DatabaseName $db.DatabaseName
		Assert-AreEqual $dbLocalCopy.LicenseType LicenseIncluded 
		Assert-AreEqual $dbLocalCopy.CopyResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $dbLocalCopy.CopyServerName $server.ServerName
		Assert-AreEqual $dbLocalCopy.CopyDatabaseName $copyDatabaseName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-CreateSecondaryDatabase()
{
	
    $location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location
	$database = Create-DatabaseForTest $rg $server

	$partRg = Create-ResourceGroupForTest $location
	$partServer = Create-ServerForTest $partRg $location

	try
	{
		
		$readSecondary = New-AzSqlDatabaseSecondary -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
		 -PartnerResourceGroupName $partRg.ResourceGroupName -PartnerServerName $partServer.ServerName -AllowConnections All
		Assert-NotNull $readSecondary.LinkId
		Assert-AreEqual $readSecondary.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $readSecondary.ServerName $server.ServerName
		Assert-AreEqual $readSecondary.DatabaseName $database.DatabaseName
		Assert-AreEqual $readSecondary.Role "Primary"
		Assert-AreEqual $readSecondary.Location $location
		Assert-AreEqual $readSecondary.PartnerResourceGroupName $partRg.ResourceGroupName
		Assert-AreEqual $readSecondary.PartnerServerName $partServer.ServerName
		Assert-NotNull $readSecondary.PartnerRole
		Assert-AreEqual $readSecondary.PartnerLocation $location
		Assert-NotNull $readSecondary.AllowConnections
		Assert-NotNull $readSecondary.ReplicationState
		Assert-NotNull $readSecondary.PercentComplete
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $partRg
	}
}


function Test-GetReplicationLink()
{
	
    $location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location
	$database = Create-DatabaseForTest $rg $server

	$partRg = Create-ResourceGroupForTest $location
	$partServer = Create-ServerForTest $partRg $location

	try
	{
		
		$job = New-AzSqlDatabaseSecondary -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
			-PartnerResourceGroupName $partRg.ResourceGroupName -PartnerServerName $partServer.ServerName -AllowConnections All -AsJob
		$job | Wait-Job

		$secondary = Get-AzSqlDatabaseReplicationLink -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
		 -DatabaseName $database.DatabaseName -PartnerResourceGroupName $partRg.ResourceGroupName -PartnerServerName $partServer.ServerName
		Assert-NotNull $secondary.LinkId
		Assert-AreEqual $secondary.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $secondary.ServerName $server.ServerName
		Assert-AreEqual $secondary.DatabaseName $database.DatabaseName
		Assert-AreEqual $secondary.Role Primary
		Assert-AreEqual $secondary.Location $location
		Assert-AreEqual $secondary.PartnerResourceGroupName $partRg.ResourceGroupName
		Assert-AreEqual $secondary.PartnerServerName $partServer.ServerName
		Assert-NotNull $secondary.PartnerRole
		Assert-AreEqual $secondary.PartnerLocation $location
		Assert-NotNull $secondary.AllowConnections
		Assert-NotNull $secondary.ReplicationState
		Assert-NotNull $secondary.PercentComplete
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $partRg
	}
}


function Test-RemoveSecondaryDatabase()
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location
	$database = Create-DatabaseForTest $rg $server

	$partRg = Create-ResourceGroupForTest $location
	$partServer = Create-ServerForTest $partRg $location

	try
	{
		
		New-AzSqlDatabaseSecondary -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
		 -PartnerResourceGroupName $partRg.ResourceGroupName -PartnerServerName $partServer.ServerName -AllowConnections All

		Remove-AzSqlDatabaseSecondary -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
		 -PartnerResourceGroupName $partRg.ResourceGroupName -PartnerServerName $partServer.ServerName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $partRg
	}
}


function Test-FailoverSecondaryDatabase()
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location
	$database = Create-DatabaseForTest $rg $server

	$partRg = Create-ResourceGroupForTest $location
	$partServer = Create-ServerForTest $partRg $location

	try
	{
		
		New-AzSqlDatabaseSecondary -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $database.DatabaseName `
		 -PartnerResourceGroupName $partRg.ResourceGroupName -PartnerServerName $partServer.ServerName -AllowConnections All

		$secondary = Get-AzSqlDatabaseReplicationLink -ResourceGroupName $partRg.ResourceGroupName -ServerName $partServer.ServerName -DatabaseName $database.DatabaseName -PartnerResourceGroupName $rg.ResourceGroupName -PartnerServerName $server.ServerName

		$job = $secondary | Set-AzSqlDatabaseSecondary -PartnerResourceGroupName $rg.ResourceGroupName -Failover -AsJob
		$job | Wait-Job
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $partRg
	}
}


function Create-DatabaseForTest  ($rg, $server, $edition = "Premium")
{
	$databaseName = Get-DatabaseName
	New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -Edition $edition
}



function Create-VcoreDatabaseForTest  ($rg, $server, $numCores = 1, $licenseType = "LicenseIncluded")
{
	$databaseName = Get-DatabaseName
	New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -VCore $numCores -ComputeGeneration Gen4 -Edition GeneralPurpose -LicenseType $licenseType
}