














function Test-GetAzLogicAppTrigger
{
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName

	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinition.json"
		
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Location $location

	$workflowTrigger = Get-AzLogicAppTrigger -ResourceGroupName $resourceGroupName -Name $workflowName
	Assert-NotNull $workflowTrigger

	$workflowTrigger = Get-AzLogicAppTrigger -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"
	Assert-NotNull $workflowTrigger
}


function Test-GetAzLogicAppTriggerHistory
{	
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName

	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinition.json"
		
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Location $location
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Start-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"

	$workflowTriggerHistories = Get-AzLogicAppTriggerHistory -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"
	Assert-NotNull $workflowTriggerHistories
	$firstHistory = $workflowTriggerHistories[0]

	$workflowTriggerHistory = Get-AzLogicAppTriggerHistory -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger" -HistoryName  $firstHistory.Name
	Assert-NotNull $workflowTriggerHistory
}


function Test-GetAzLogicAppTriggerCallbackUrl
{	
	$resourceGroup = TestSetup-CreateResourceGroup
	$resourceGroupName = $resourceGroup.ResourceGroupName

	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinition.json"
		
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Location $location
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	$callbackUrlString = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "manualTrigger"
	Assert-NotNull $callbackUrlString

	$curApiVersion = '*' + (CurrentApiVersion) + '*'
	Assert-True { $callbackUrlString.Value -like $curApiVersion }
}


function Test-StartAzLogicAppTrigger
{	
	$resourceGroup = TestSetup-CreateResourceGroup	
	$resourceGroupName = $resourceGroup.ResourceGroupName
	
	$workflowName = getAssetname
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"
	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowTriggerDefinition.json"
		
	$workflow = New-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -DefinitionFilePath $definitionFilePath -Location $location
	
	[int]$counter = 0
	do {
		SleepInRecordMode 2000
		$workflow =  Get-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName
	} while ($workflow.State -ne "Enabled" -and $counter++ -lt 5)
	
	Start-AzLogicApp -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"

	$workflowTriggerHistories = Get-AzLogicAppTriggerHistory -ResourceGroupName $resourceGroupName -Name $workflowName -TriggerName "httpTrigger"	
	
	Assert-AreEqual 1 $workflowTriggerHistories.Count 
}