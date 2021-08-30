














function Test-SetGetManagedInstanceEncryptionProtectorCI
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	
	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector  -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -Type ServiceManaged
	
	Assert-AreEqual ServiceManaged $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector  -InstanceResourceId $managedInstance.Id
	
	Assert-AreEqual ServiceManaged $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"

	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after adding managed instance key vault key"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyVaultKeyName mismatch after adding managed instance key vault key"
	
	

	$byokEncryptionProtector = $managedInstance | Set-AzSqlInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -KeyId $keyResult.KeyId -Force
	
	Assert-AreEqual AzureKeyVault $byokEncryptionProtector.Type "BYOK: Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $byokEncryptionProtector.ManagedInstanceKeyVaultKeyName "BYOK:  mismatch after setting managed instance TDE protector"

	$byokEncryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector -Instance $managedInstance
	
	Assert-AreEqual AzureKeyVault $byokEncryptionProtector2.Type "BYOK: Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $byokEncryptionProtector2.ManagedInstanceKeyVaultKeyName "BYOK: ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorServiceManaged
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector  -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -Type ServiceManaged
	
	Assert-AreEqual ServiceManaged $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector  -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName
	
	Assert-AreEqual ServiceManaged $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorServiceManagedInputObject
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector -Instance $managedInstance -Type ServiceManaged
	
	Assert-AreEqual ServiceManaged $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector -Instance $managedInstance
	
	Assert-AreEqual ServiceManaged $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorServiceManagedResourceId
{

	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	$managedInstanceResourceId = $managedInstance.Id

	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector -InstanceResourceId $managedInstanceResourceId -Type ServiceManaged
	
	Assert-AreEqual ServiceManaged $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector -InstanceResourceId $managedInstanceResourceId
	
	Assert-AreEqual ServiceManaged $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorServiceManagedPiping
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	$encryptionProtector = $managedInstance | Set-AzSqlInstanceTransparentDataEncryptionProtector -Type ServiceManaged
	
	Assert-AreEqual ServiceManaged $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = $managedInstance | Get-AzSqlInstanceTransparentDataEncryptionProtector
	
	Assert-AreEqual ServiceManaged $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual ServiceManaged $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}




function Test-SetGetManagedInstanceEncryptionProtectorByok
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after adding managed instance key vault key"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyVaultKeyName mismatch after adding managed instance key vault key"

	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector  -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -Type AzureKeyVault -KeyId $keyResult.KeyId -Force
	
	Assert-AreEqual AzureKeyVault $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector  -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName
	
	Assert-AreEqual AzureKeyVault $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorByokInputObject
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after adding managed instance key vault key"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyVaultKeyName mismatch after adding managed instance key vault key"

	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector -Instance $managedInstance -Type AzureKeyVault -KeyId $keyResult.KeyId -Force
	
	Assert-AreEqual AzureKeyVault $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector -Instance $managedInstance
	
	Assert-AreEqual AzureKeyVault $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorByokResourceId
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName
	
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after adding managed instance key vault key"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyVaultKeyName mismatch after adding managed instance key vault key"

	$managedInstanceResourceId = $managedInstance.Id

	$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector -InstanceResourceId $managedInstanceResourceId -Type AzureKeyVault -KeyId $keyResult.KeyId -Force
	
	Assert-AreEqual AzureKeyVault $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = Get-AzSqlInstanceTransparentDataEncryptionProtector -InstanceResourceId $managedInstanceResourceId
	
	Assert-AreEqual AzureKeyVault $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}


function Test-SetGetManagedInstanceEncryptionProtectorByokPiping
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after adding managed instance key vault key"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyVaultKeyName mismatch after adding managed instance key vault key"

	$encryptionProtector = $managedInstance | Set-AzSqlInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -KeyId $keyResult.KeyId -Force
	
	Assert-AreEqual AzureKeyVault $encryptionProtector.Type "Protector type mismatch after setting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after setting managed instance TDE protector"

	$encryptionProtector2 = $managedInstance | Get-AzSqlInstanceTransparentDataEncryptionProtector
	
	Assert-AreEqual AzureKeyVault $encryptionProtector2.Type "Protector type mismatch after getting managed instance TDE protector"
	Assert-AreEqual $keyResult.ManagedInstanceKeyName $encryptionProtector2.ManagedInstanceKeyVaultKeyName "ManagedInstanceKeyVaultKeyName mismatch after getting managed instance TDE protector"
}



function Test-SetGetManagedInstanceEncryptionProtectorByokFailsWithoutKeyId
{
	$params = Get-SqlServerKeyVaultKeyTestEnvironmentParameters
	$managedInstance = Get-ManagedInstanceForTdeTest $params
	$mangedInstanceRg = $managedInstance.ResourceGroupName
	$managedInstanceName = $managedInstance.ManagedInstanceName

	$correctExceptionCaught = $false
	$keyResult = Add-AzSqlInstanceKeyVaultKey -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -KeyId $params.keyId

	Assert-AreEqual $params.keyId $keyResult.KeyId "KeyId mismatch after adding managed instance key vault key"
	Assert-AreEqual $params.serverKeyName $keyResult.ManagedInstanceKeyName "ManagedInstanceKeyVaultKeyName mismatch after adding managed instance key vault key"
	
	try
	{
		$encryptionProtector = Set-AzSqlInstanceTransparentDataEncryptionProtector  -ResourceGroupName $mangedInstanceRg -InstanceName $managedInstanceName -Type AzureKeyVault -Force
	}
	Catch
	{
		$isCorrectError =  $_.Exception.Message -like '*KeyId parameter is required for encryption protector type AzureKeyVault*'
		if(!$isCorrectError){
			throw $_.Exception
		}
		$correctExceptionCaught = $true
	}

	if(!$correctExceptionCaught){
		throw [System.Exception] "Expected exception not thrown for cmdlet Set-AzSqlInstanceTransparentDataEncryptionProtector when encryptor is AzureKeyVault and KeyId is not provided"
	}
}