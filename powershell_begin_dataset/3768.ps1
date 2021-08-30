














function Test-CreateAndRemoveLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$parameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"

	
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
	
	Assert-NotNull $workflow
	Assert-NotNull $workflow.Definition
	Assert-NotNull $workflow.Parameters
	Assert-AreEqual $workflowName $workflow.Name 
	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force

	
	$parameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"
    $definition = [IO.File]::ReadAllText((Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"))

	$workflowName = getAssetname
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Definition $definition -ParameterFilePath $parameterFilePath -Location $location

	Assert-NotNull $workflow
	Assert-NotNull $workflow.Definition
	Assert-NotNull $workflow.Parameters
	Assert-AreEqual $workflowName $workflow.Name 
	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force

	
	$workflowName = getAssetname
	$workflow = $resourceGroup | New-AzLogicApp -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath

	Assert-NotNull $workflow
	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force
}


function Test-CreateLogicAppWithDuplicateName
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$parameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"
	$resourceGroupName = $resourceGroup.ResourceGroupName

	$workflow = $resourceGroup | New-AzLogicApp -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath

	Assert-NotNull $workflow
	try
	{
		$workflow = $resourceGroup | New-AzLogicApp -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
	}
	catch
	{
		Assert-AreEqual $_.Exception.Message "The Resource '$WorkflowName' under resource group '$resourceGroupName' already exists."
	}
	
	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force
}


function Test-CreateLogicAppUsingInputfromWorkflowObject
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$newWorkflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$parameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath 
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $newWorkflowName -Location $location -Definition $workflow.Definition -Parameters $workflow.Parameters

	Assert-NotNull $workflow
	Assert-NotNull $workflow.Definition
	Assert-NotNull $workflow.Parameters
	Assert-AreEqual $newWorkflowName $workflow.Name 
	Assert-AreEqual "Enabled" $workflow.State

	Remove-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Force
}


function Test-CreateLogicAppUsingInputParameterAsHashTable
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"	
	$parameters = @{destinationUri="http://www.bing.com"}

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Parameters $parameters -Location $location

	Assert-NotNull $workflow
	Assert-NotNull $workflow.Parameters

	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $WorkflowName -Force	
}


function Test-CreateLogicAppUsingDefinitionWithTriggers
{		
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowTriggerDefinition.json"
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Location $location

	Assert-NotNull $workflow
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Force
}


function Test-CreateAndGetLogicAppUsingDefinitionWithActions
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowActionDefinition.json"
	
	
	$workflow1 = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Location $location
	Assert-NotNull $workflow1

	
	$workflow2 = Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	Assert-NotNull $workflow2

	
	$workflow3 = Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Version $workflow1.Version
	Assert-NotNull $workflow3

	
	$workflow4 = Get-AzLogicApp -ResourceGroupName $resourceGroupName
	Assert-NotNull $workflow4
	Assert-True { $workflow4.Length -ge 1 }

	
	$workflow5 = Get-AzLogicApp
	Assert-NotNull $workflow5
	Assert-True { $workflow5.Length -ge 1 }

	
	$workflow6 = Get-AzLogicApp -Name $workflowName
	Assert-NotNull $workflow6
	Assert-True { $workflow6.Length -ge 1 }

	
	try
	{
		Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name "InvalidWorkflow"
	}
	catch
	{
		Assert-AreEqual $_.Exception.Message "The Resource 'Microsoft.Logic/workflows/InvalidWorkflow' under resource group '$resourceGroupName' was not found."
	} 

	Remove-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Force
}


function Test-RemoveNonExistingLogicApp
{
	$WorkflowName = "09e81ac4-848a-428d-82a6-7d61953e3940"
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName

	Remove-AzLogicApp -ResourceGroupName $resourceGroupName -Name $WorkflowName -Force
}


function Test-UpdateLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$simpleDefinitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$simpleParameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"
	$workflow = $resourceGroup | New-AzLogicApp -Name $workflowName -Location $location -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath

	Assert-NotNull $workflow

	
	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowTriggerDefinition.json"

	$UpdatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -State "Disabled" -DefinitionFilePath $definitionFilePath -Parameters $null -Force
	
	Assert-NotNull $UpdatedWorkflow
	Assert-AreEqual $UpdatedWorkflow.State "Disabled"

	
	$UpdatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath -Force

	Assert-NotNull $UpdatedWorkflow

	
	$UpdatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -State "Enabled" -Force
	
	Assert-NotNull $UpdatedWorkflow
	Assert-AreEqual $UpdatedWorkflow.State "Enabled"

	
	try
	{
		$UpdatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Definition $null -Force
	}
	catch
	{
		Assert-AreEqual $_.Exception.Message "Definition content needs to be specified."
	}

	
	try
	{
		$workflowName = "82D2D842-C312-445C-8A4D-E3EE9542436D"
		$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowTriggerDefinition.json"
		Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Force
	}
	catch
	{
		Assert-AreEqual $_.Exception.Message "The Resource 'Microsoft.Logic/workflows/$workflowName' under resource group '$resourceGroupName' was not found."		
	}
}


function Test-ValidateLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$parameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath

	
	Test-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
	
	
	$definition = [IO.File]::ReadAllText($definitionFilePath)
	Test-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Location $location -Definition $definition -ParameterFilePath $parameterFilePath

	
	try
	{
		Test-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Location $location -Definition '{}'
	}
	catch
	{
		Assert-AreEqual $_.Exception.Message "The request content is not valid and could not be deserialized: 'Required property '`$schema' not found in JSON. Path 'properties.definition', line 4, position 20.'."
	}

	Remove-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Force
}


function Test-GetUpgradedDefinitionForLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$definitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$parameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath

	
	$upgradedDefinition = Get-AzLogicAppUpgradedDefinition -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -TargetSchemaVersion "2016-06-01"
	
	
	Set-AzLogicApp -ResourceGroupName $resourceGroup.ResourceGroupName -Name $workflowName -Definition $upgradedDefinition.ToString() -Force

	Remove-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Force	
}


function Test-UpdateLogicAppWithIntegrationAccount
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$simpleDefinitionFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowDefinition.json"
	$simpleParameterFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "TestSimpleWorkflowParameter.json"
	$workflow = $resourceGroup | New-AzLogicApp -Name $workflowName -Location $location -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath -IntegrationAccountId $integrationAccount.Id
	Assert-NotNull $workflow

	$updatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath -IntegrationAccountId $integrationAccount.Id -Force
	Assert-AreEqual $integrationAccount.Id $updatedWorkflow.IntegrationAccount.Id

	$updatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath -Force
	Assert-AreEqual $integrationAccount.Id $updatedWorkflow.IntegrationAccount.Id

	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName
	$updatedWorkflow = Set-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $simpleDefinitionFilePath -ParameterFilePath $simpleParameterFilePath -IntegrationAccountId $integrationAccount.Id -Force
	Assert-AreEqual $integrationAccount.Id $updatedWorkflow.IntegrationAccount.Id

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}