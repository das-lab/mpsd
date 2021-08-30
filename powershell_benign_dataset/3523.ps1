














function Get-AzureRmPolicyState-LatestManagementGroupScope
{
	$managementGroupName = Get-TestManagementGroupName
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -ManagementGroupName $managementGroupName -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllManagementGroupScope
{
	$managementGroupName = Get-TestManagementGroupName
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -All -ManagementGroupName $managementGroupName -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestSubscriptionScope
{
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllSubscriptionScope
{
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -All -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestResourceGroupScope
{
	$resourceGroupName = Get-TestResourceGroupName
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -ResourceGroupName $resourceGroupName -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllResourceGroupScope
{
	$resourceGroupName = Get-TestResourceGroupName
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -All -ResourceGroupName $resourceGroupName -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestResourceScope
{
	$resourceId = Get-TestResourceId
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -ResourceId $resourceId -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllResourceScope
{
	$resourceId = Get-TestResourceId
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -All -ResourceId $resourceId -Top 10 -From $from
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestPolicySetDefinitionScope
{
	$policySetDefinitionName = Get-TestPolicySetDefinitionName

    $policyStates = Get-AzPolicyState -PolicySetDefinitionName $policySetDefinitionName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllPolicySetDefinitionScope
{
	$policySetDefinitionName = Get-TestPolicySetDefinitionName

    $policyStates = Get-AzPolicyState -All -PolicySetDefinitionName $policySetDefinitionName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestPolicyDefinitionScope
{
	$policyDefinitionName = Get-TestPolicyDefinitionName

    $policyStates = Get-AzPolicyState -PolicyDefinitionName $policyDefinitionName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllPolicyDefinitionScope
{
	$policyDefinitionName = Get-TestPolicyDefinitionName

    $policyStates = Get-AzPolicyState -All -PolicyDefinitionName $policyDefinitionName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestSubscriptionLevelPolicyAssignmentScope
{
	$policyAssignmentName = Get-TestPolicyAssignmentName

    $policyStates = Get-AzPolicyState -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllSubscriptionLevelPolicyAssignmentScope
{
	$policyAssignmentName = Get-TestPolicyAssignmentName

    $policyStates = Get-AzPolicyState -All -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-LatestResourceGroupLevelPolicyAssignmentScope
{
	$resourceGroupName = Get-TestResourceGroupNameForPolicyAssignmentStates
	$policyAssignmentName = Get-TestPolicyAssignmentNameResourceGroupLevelStates

    $policyStates = Get-AzPolicyState -ResourceGroupName $resourceGroupName -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyStates $policyStates 10
}


function Get-AzureRmPolicyState-AllResourceGroupLevelPolicyAssignmentScope
{
	$resourceGroupName = Get-TestResourceGroupNameForPolicyAssignmentStates
	$policyAssignmentName = Get-TestPolicyAssignmentNameResourceGroupLevelStates

    $policyStates = Get-AzPolicyState -All -ResourceGroupName $resourceGroupName -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyStates $policyStates 10
}
