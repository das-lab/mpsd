














function Get-AzureRmPolicyStateSummary-ManagementGroupScope
{
    $managementGroupName = Get-TestManagementGroupName
	$from = Get-TestQueryIntervalStart

	$policyStateSummary = Get-AzPolicyStateSummary -ManagementGroupName $managementGroupName -Top 10 -From $from
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-SubscriptionScope
{
	$from = Get-TestQueryIntervalStart

    $policyStateSummary = Get-AzPolicyStateSummary -Top 10 -From $from
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-ResourceGroupScope
{
	$resourceGroupName = Get-TestResourceGroupName
	$from = Get-TestQueryIntervalStart

    $policyStateSummary = Get-AzPolicyStateSummary -ResourceGroupName $resourceGroupName -Top 10 -From $from
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-ResourceScope
{
	$resourceId = Get-TestResourceId
	$from = Get-TestQueryIntervalStart

    $policyStateSummary = Get-AzPolicyStateSummary -ResourceId $resourceId -Top 10 -From $from
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-PolicySetDefinitionScope
{
	$policySetDefinitionName = Get-TestPolicySetDefinitionName

    $policyStateSummary = Get-AzPolicyStateSummary -PolicySetDefinitionName $policySetDefinitionName -Top 10
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-PolicyDefinitionScope
{
	$policyDefinitionName = Get-TestPolicyDefinitionName

    $policyStateSummary = Get-AzPolicyStateSummary -PolicyDefinitionName $policyDefinitionName -Top 10
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-SubscriptionLevelPolicyAssignmentScope
{
	$policyAssignmentName = Get-TestPolicyAssignmentName

    $policyStateSummary = Get-AzPolicyStateSummary -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyStateSummary $policyStateSummary
}


function Get-AzureRmPolicyStateSummary-ResourceGroupLevelPolicyAssignmentScope
{
	$resourceGroupName = Get-TestResourceGroupNameForPolicyAssignmentStates
	$policyAssignmentName = Get-TestPolicyAssignmentNameResourceGroupLevelStates

    $policyStateSummary = Get-AzPolicyStateSummary -ResourceGroupName $resourceGroupName -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyStateSummary $policyStateSummary
}
