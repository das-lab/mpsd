














function Test-CreateIntegrationAccountSchema
{
	$schemaFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "OrderFile.xsd"
	$schemaContent = [IO.File]::ReadAllText($schemaFilePath)
	
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountSchemaName1 = getAssetname	
	$integrationAccountSchemaName2 = getAssetname	
	$integrationAccountSchemaName3 = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountSchema1 =  New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName1 -SchemaDefinition $schemaContent 
	Assert-AreEqual $integrationAccountSchemaName1 $integrationAccountSchema1.Name

	$integrationAccountSchema2 =  New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName2 -SchemaFilePath $schemaFilePath
	Assert-AreEqual $integrationAccountSchemaName2 $integrationAccountSchema2.Name

	$integrationAccountSchema3 =  New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName3 -SchemaFilePath $schemaFilePath -SchemaType "Xml" -ContentType "application/xml"
	Assert-AreEqual $integrationAccountSchemaName3 $integrationAccountSchema3.Name

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-GetIntegrationAccountSchema
{
	$schemaFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "OrderFile.xsd"
	$schemaContent = [IO.File]::ReadAllText($schemaFilePath)

	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountSchemaName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountSchema =  New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -SchemaDefinition $schemaContent
	Assert-AreEqual $integrationAccountSchemaName $integrationAccountSchema.Name

	$result =  Get-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName
	Assert-AreEqual $integrationAccountSchemaName $result.Name

	$result1 =  Get-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName
	Assert-AreEqual $integrationAccountSchemaName $result1.Name
	Assert-True { $result1.Count -gt 0 }	

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-RemoveIntegrationAccountSchema
{
	$schemaFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "OrderFile.xsd"
	$schemaContent = [IO.File]::ReadAllText($schemaFilePath)
	
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)	
	
	$integrationAccountSchemaName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountSchema =  New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -SchemaDefinition $schemaContent
	Assert-AreEqual $integrationAccountSchemaName $integrationAccountSchema.Name

	Remove-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -Force	

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-UpdateIntegrationAccountSchema
{
	$schemaFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "OrderFile.xsd"
	$schemaContent = [IO.File]::ReadAllText($schemaFilePath)
	
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	
	$integrationAccountSchemaName = getAssetname	

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountSchema =  New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -SchemaDefinition $schemaContent
	Assert-AreEqual $integrationAccountSchemaName $integrationAccountSchema.Name

	$integrationAccountSchemaUpdated =  Set-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -SchemaDefinition $schemaContent -Force
	Assert-AreEqual $integrationAccountSchemaName $integrationAccountSchema.Name

	$integrationAccountSchemaUpdated =  Set-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -SchemaDefinition $schemaContent -Force
	Assert-AreEqual $integrationAccountSchemaName $integrationAccountSchema.Name
	
	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-ListIntegrationAccountSchema
{
	$schemaFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "OrderFile.xsd"
	$schemaContent = [IO.File]::ReadAllText($schemaFilePath)

	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)

	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$val=0
	while($val -ne 1)
	{
		$val++ ;
		$integrationAccountSchemaName = getAssetname
		New-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -SchemaName $integrationAccountSchemaName -SchemaDefinition $schemaContent
	}

	$result =  Get-AzIntegrationAccountSchema -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName
	Assert-True { $result.Count -eq 1 }

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}