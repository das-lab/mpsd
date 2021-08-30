














function Test-ManagedInstanceKeyVaultKeyCI
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	$managedInstanceResourceId = $managedInstance.Id

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = $managedInstance | Get-AzSqlInstanceKeyVaultKey -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"
		
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}


function Test-ManagedInstanceKeyVaultKey
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = Get-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"
		
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}



function Test-ManagedInstanceKeyVaultKeyInputObject
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -Instance $managedInstance -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = Get-AzSqlInstanceKeyVaultKey -Instance $managedInstance -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"

	
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -Instance $managedInstance 
	
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}



function Test-ManagedInstanceKeyVaultKeyResourceId
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	$managedInstanceResourceId = $managedInstance.Id

	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = Get-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"

	
	
	$keyResults = Get-AzSqlInstanceKeyVaultKey -InstanceResourceId $managedInstanceResourceId 
	
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}



function Test-ManagedInstanceKeyVaultKeyPiping
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$keyResult = $managedInstance | Add-AzSqlInstanceKeyVaultKey -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after calling Add-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Add-AzSqlInstanceKeyVaultKey"

	
	
	$keyResult2 = $managedInstance | Get-AzSqlInstanceKeyVaultKey -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult2.KeyId "KeyId mismatch after calling Get-AzSqlInstanceKeyVaultKey"
	Assert-AreEqual $params.serverKeyName $keyResult2.ManagedInstanceKeyName "ManagedInstanceKeyName mismatch after calling Get-AzSqlInstanceKeyVaultKey"

	
	
	$keyResults = $managedInstance | Get-AzSqlInstanceKeyVaultKey
	
	Assert-True {$keyResults.Count -gt 0} "List count <= 0 after calling (List) Get-AzSqlInstanceKeyVaultKey without KeyId"
}
