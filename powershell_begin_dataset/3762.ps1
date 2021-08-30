













function CurrentApiVersion 
{
	return "2018-07-01-preview"
}

function SampleMetadata
{
	return @{ "key1" = "value1"; "key2" = "value2"; "key3" = "value3"; }
}


function TestSetup-CreateResourceGroup
{
    $resourceGroupName = "RG-" + (getAssetname)
	$location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $location

	return $resourceGroup
}


function TestSetup-CreateIntegrationAccount ([string]$resourceGroupName, [string]$integrationAccountName)
{
	$location = Get-Location "Microsoft.Logic" "integrationAccounts" "West US"
	$integrationAccount = New-AzIntegrationAccount -ResourceGroupName $resourceGroupName -IntegrationAccountName $integrationAccountName -Location $location -Sku "Standard"
	return $integrationAccount
}


function TestSetup-CreateWorkflow ([string]$resourceGroupName, [string]$workflowName, [string]$AppServicePlan)
{
	$location = Get-Location "Microsoft.Logic" "workflows" "West US"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $rglocation -Force

	$definitionFilePath = Join-Path "Resources" "TestSimpleWorkflowDefinition.json"
	$parameterFilePath = Join-Path "Resources" "TestSimpleWorkflowParameter.json"
	$workflow = $resourceGroup | New-AzLogicApp -Name $workflowName -Location $location -DefinitionFilePath $definitionFilePath -ParameterFilePath $parameterFilePath
    return $workflow
}


function SleepInRecordMode ([int]$SleepIntervalInMillisec)
{
	$mode = $env:AZURE_TEST_MODE
	if ( $mode -ne $null -and $mode.ToUpperInvariant() -eq "RECORD")
	{
		Sleep -Milliseconds $SleepIntervalInMillisec 
	}
}