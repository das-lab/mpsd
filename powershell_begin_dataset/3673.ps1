














function Test-AddServerKeyVaultKey
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$rg = Create-ServerKeyVaultKeyTestEnvironment $params

	try
	{
		$job = Add-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId -AsJob
		$job | Wait-Job
		$keyResult = $job.Output

		

		Assert-AreEqual $params.keyId $keyResult.Uri 
		Assert-AreEqual $params.serverKeyName $keyResult.ServerKeyName 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetServerKeyVaultKey
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$rg = Create-ServerKeyVaultKeyTestEnvironment $params

	try
	{
		$keyResult = Add-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId
		Assert-AreEqual $params.keyId $keyResult.Uri
		Assert-AreEqual $params.serverKeyName $keyResult.ServerKeyName 

		$keyGet = Get-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId
		Assert-AreEqual $params.keyId $keyGet.Uri
		Assert-AreEqual $params.serverKeyName $keyGet.ServerKeyName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RemoveServerKeyVaultKey
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$rg = Create-ServerKeyVaultKeyTestEnvironment $params

	try
	{
		$keyResult = Add-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId
		Assert-AreEqual $params.keyId $keyResult.Uri 
		Assert-AreEqual $params.serverKeyName $keyResult.ServerKeyName 

		$keyGet = Get-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId
		Assert-AreEqual $params.keyId $keyGet.Uri
		Assert-AreEqual $params.serverKeyName $keyGet.ServerKeyName

		$job = Remove-AzSqlServerKeyVaultKey -ServerName $params.serverName -ResourceGroupName $params.rgName -KeyId $params.keyId -AsJob
		$job | Wait-Job
		$keyRemove = $job.Output
		
		Assert-AreEqual $params.serverKeyName $keyRemove.ServerKeyName
		Assert-AreEqual $params.keyId $keyRemove.Uri
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
