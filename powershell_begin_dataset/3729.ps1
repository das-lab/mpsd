














function Test-GetActionRulesFilteredByParameters
{
	$severityFilter = "Sev3"
	$monitorService = "Platform"
	$actionRules = Get-AzActionRule -Severity $severityFilter -MonitorService $monitorService

	Assert-NotNull $actionRules.Count
}

function Test-CreateUpdateAndDeleteSuppressionRule
{
	try
	{
		$resourceGroupName = Get-TestResourceGroupName "suppression"
		$location = Get-ProviderLocation ResourceManagement
		$actionRuleName = Get-TestActionRuleName "suppression"

		
		New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

		$createdActionRule = Set-AzActionRule -ResourceGroupName $resourceGroupName -Name $actionRuleName -Scope "/subscriptions/dd91de05-d791-4ceb-b6dc-988682dc7d72/resourceGroups/alertslab","/subscriptions/dd91de05-d791-4ceb-b6dc-988682dc7d72/resourceGroups/Test-VMs" -SeverityCondition "Equals:Sev0,Sev1" -MonitorCondition "NotEquals:Resolved" -Description "Test description" -Status "Enabled" -ActionRuleType "Suppression" -ReccurenceType "Weekly" -SuppressionStartTime "06/26/2018 06:00:00" -SuppressionEndTime "07/27/2018 06:00:00" -ReccurentValue 1,4,6

		Assert-NotNull $createdActionRule 

		
		$updatedActionRule = Update-AzActionRule -ResourceGroupName $resourceGroupName -Name $actionRuleName -Status "Disabled"
		Assert-NotNull $updatedActionRule 
		Assert-AreEqual "Disabled" $updatedActionRule.Status
	}
	finally
	{
		CleanUp $resourceGroupName $actionRuleName
	}
}

function Test-CreateUpdateAndDeleteActionGroupRule
{
	try
	{
		$resourceGroupName = Get-TestResourceGroupName "actiongroup"
		$location = Get-ProviderLocation ResourceManagement
		$actionRuleName = Get-TestActionRuleName "actiongroup"

		
		New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

		$createdActionRule = Set-AzActionRule -ResourceGroupName $resourceGroupName -Name $actionRuleName -Scope "/subscriptions/dd91de05-d791-4ceb-b6dc-988682dc7d72/resourceGroups/alertslab","/subscriptions/dd91de05-d791-4ceb-b6dc-988682dc7d72/resourceGroups/Test-VMs" -SeverityCondition "Equals:Sev0,Sev1" -MonitorCondition "NotEquals:Resolved" -Description "Test description" -Status "Enabled" -ActionRuleType "ActionGroup" -ActionGroupId "/subscriptions/1e3ff1c0-771a-4119-a03b-be82a51e232d/resourceGroups/alertscorrelationrg/providers/Microsoft.insights/actiongroups/testAG"

		Assert-NotNull $createdActionRule 

		
		$updatedActionRule = Update-AzActionRule -ResourceGroupName $resourceGroupName -Name $actionRuleName -Status "Disabled"
		Assert-NotNull $updatedActionRule 
		Assert-AreEqual "Disabled" $updatedActionRule.Status
	}
	finally
	{
		CleanUp $resourceGroupName $actionRuleName
	}
}

function Test-CreateUpdateAndDeleteDiagnosticsRule
{
	try
	{
		$resourceGroupName = Get-TestResourceGroupName "diag"
		$location = Get-ProviderLocation ResourceManagement
		$actionRuleName = Get-TestActionRuleName "diag"

		
		New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

		$createdActionRule = Set-AzActionRule -ResourceGroupName $resourceGroupName -Name $actionRuleName -Scope "/subscriptions/dd91de05-d791-4ceb-b6dc-988682dc7d72/resourceGroups/alertslab","/subscriptions/dd91de05-d791-4ceb-b6dc-988682dc7d72/resourceGroups/Test-VMs" -SeverityCondition "Equals:Sev0,Sev1" -MonitorCondition "NotEquals:Resolved" -Description "Test description" -Status "Enabled" -ActionRuleType "Diagnostics"

		Assert-NotNull $createdActionRule 

		
		$updatedActionRule = Update-AzActionRule -ResourceGroupName $resourceGroupName -Name $actionRuleName -Status "Disabled"
		Assert-NotNull $updatedActionRule 
		Assert-AreEqual "Disabled" $updatedActionRule.Status
	}
	finally
	{
		CleanUp $resourceGroupName $actionRuleName
	}
}