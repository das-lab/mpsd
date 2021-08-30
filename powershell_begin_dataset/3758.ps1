














function Test-StartLogicApp
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$workflowName = getAssetname
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinition.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Start-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"
}


function Test-GetAzLogicAppRunHistory
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$workflowName = getAssetname
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinition.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Start-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"

	$runHistory = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroupName -Name $workflowName 
	Assert-NotNull $runHistory
	$run = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroupName -Name $workflowName -RunName $runHistory[0].Name	
	Assert-NotNull $run
	Assert-AreEqual $runHistory[0].Name $run.Name
}


function Test-GetAzLogicAppRunAction
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$workflowName = getAssetname
	$definitionFilePath = Join-Path $TestOutputRoot "Resources\TestSimpleWorkflowTriggerDefinition.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath

	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Start-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"

	$runHistory = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroupName -Name $workflowName 
	Assert-NotNull $runHistory
	
	$actions = Get-AzLogicAppRunAction -ResourceGroupName $resourceGroupName -Name $workflowName -RunName $runHistory[0].Name
	Assert-NotNull $actions
	Assert-AreEqual 2 $actions.Count

	$action = Get-AzLogicAppRunAction -ResourceGroupName $resourceGroupName -Name $workflowName -RunName $runHistory[0].Name -ActionName "http"
	Assert-NotNull $action
}


function Test-StopAzLogicAppRun
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"

	$workflowName = getAssetname
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinitionWithDelayAction.json"

	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Start-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"

	$runHistory = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroupName -Name $workflowName

	Stop-AzLogicAppRun -ResourceGroupName $resourceGroupName -Name $workflowName -RunName $runHistory[0].Name -Force
}