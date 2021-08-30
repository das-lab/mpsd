













$location = 'southeastasia'


function Test-UpdateTransparentDataEncryption
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location
	
	
	$databaseName = Get-DatabaseName
	$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
	Assert-AreEqual $db.DatabaseName $databaseName

	

	try
	{
		
		$tde1 = Set-AzSqlDatabaseTransparentDataEncryption -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName `
			-DatabaseName $db.DatabaseName -State Enabled

		Assert-AreEqual $tde1.State Enabled
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-GetTransparentDataEncryption
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location
	
	
	$databaseName = Get-DatabaseName
	$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
	Assert-AreEqual $db.DatabaseName $databaseName

	try
	{
		$tde1 = Get-AzSqlDatabaseTransparentDataEncryption -ResourceGroupName $server.ResourceGroupname -ServerName $server.ServerName `
			-DatabaseName $db.DatabaseName
		Assert-AreEqual $tde1.State Enabled

		$tde2 = $tde1 | Get-AzSqlDatabaseTransparentDataEncryption
		Assert-AreEqual $tde2.State Enabled

		
		$tde3 = Set-AzSqlDatabaseTransparentDataEncryption -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName `
			-DatabaseName $db.DatabaseName -State Disabled
		Assert-AreEqual $tde3.State Disabled

		Start-Sleep -s 1

		$tdeActivity = Get-AzSqlDatabaseTransparentDataEncryptionActivity -ResourceGroupName $server.ResourceGroupname `
			-ServerName $server.ServerName -DatabaseName $db.DatabaseName
		Assert-AreEqual $tdeActivity.Status Decrypting

		$tde4 = Get-AzSqlDatabaseTransparentDataEncryption -ResourceGroupName $server.ResourceGroupname `
			-ServerName $server.ServerName -DatabaseName $db.DatabaseName
		Assert-AreEqual $tde4.State Disabled
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetTransparentDataEncryptionProtector
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$encProtector1 = Get-AzSqlServerTransparentDataEncryptionProtector -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName
		Assert-AreEqual ServiceManaged $encProtector1.Type 
		Assert-AreEqual ServiceManaged $encProtector1.ServerKeyVaultKeyName 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-SetTransparentDataEncryptionProtector
{
	
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$rg = Create-ServerKeyVaultKeyTestEnvironment $params

	try
	{
		
		$encProtector1 = Get-AzSqlServerTransparentDataEncryptionProtector -ResourceGroupName $params.rgName -ServerName $params.serverName
		Assert-AreEqual ServiceManaged $encProtector1.Type 
		Assert-AreEqual ServiceManaged $encProtector1.ServerKeyVaultKeyName 

		
		$keyResult = Add-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId
		Assert-AreEqual $params.keyId $keyResult.Uri

		
		$job = Set-AzSqlServerTransparentDataEncryptionProtector -ResourceGroupName $params.rgName -ServerName $params.serverName `
			-Type AzureKeyVault -KeyId $params.keyId -Force -AsJob
		$job | Wait-Job
		$encProtector2 = $job.Output

		Assert-AreEqual AzureKeyVault $encProtector2.Type 
		Assert-AreEqual $params.serverKeyName $encProtector2.ServerKeyVaultKeyName 

		
		$encProtector3 = Set-AzSqlServerTransparentDataEncryptionProtector -ResourceGroupName $params.rgName -ServerName $params.serverName -Type ServiceManaged
		Assert-AreEqual ServiceManaged $encProtector3.Type 
		Assert-AreEqual ServiceManaged $encProtector3.ServerKeyVaultKeyName 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
