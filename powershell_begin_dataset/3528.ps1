














function Get-AzureRmPolicyEvent-ManagementGroupScope
{
	$managementGroupName = Get-TestManagementGroupName
	$from = Get-TestQueryIntervalStart

    $policyEvents = Get-AzPolicyEvent -ManagementGroupName $managementGroupName -Top 10 -From $from
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-SubscriptionScope
{
	$from = Get-TestQueryIntervalStart

    $policyEvents = Get-AzPolicyEvent -Top 10 -From $from
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-ResourceGroupScope
{
	$resourceGroupName = Get-TestResourceGroupName
	$from = Get-TestQueryIntervalStart

    $policyEvents = Get-AzPolicyEvent -ResourceGroupName $resourceGroupName -Top 10 -From $from
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-ResourceScope
{
	$resourceId = Get-TestResourceId
	$from = Get-TestQueryIntervalStart

    $policyEvents = Get-AzPolicyEvent -ResourceId $resourceId -Top 10 -From $from
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-PolicySetDefinitionScope
{
	$policySetDefinitionName = Get-TestPolicySetDefinitionName
	$from = Get-TestQueryIntervalStart

    $policyEvents = Get-AzPolicyEvent -PolicySetDefinitionName $policySetDefinitionName -Top 10 -From $from
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-PolicyDefinitionScope
{
	$policyDefinitionName = Get-TestPolicyDefinitionName

    $policyEvents = Get-AzPolicyEvent -PolicyDefinitionName $policyDefinitionName -Top 10
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-SubscriptionLevelPolicyAssignmentScope
{
	$policyAssignmentName = Get-TestPolicyAssignmentName
	$from = Get-TestQueryIntervalStart

    $policyEvents = Get-AzPolicyEvent -PolicyAssignmentName $policyAssignmentName -Top 10 -From $from
	Validate-PolicyEvents $policyEvents 10
}


function Get-AzureRmPolicyEvent-ResourceGroupLevelPolicyAssignmentScope
{
	$resourceGroupName = Get-TestResourceGroupNameForPolicyAssignmentEvents
	$policyAssignmentName = Get-TestPolicyAssignmentNameResourceGroupLevelEvents

    $policyEvents = Get-AzPolicyEvent -ResourceGroupName $resourceGroupName -PolicyAssignmentName $policyAssignmentName -Top 10
	Validate-PolicyEvents $policyEvents 10
}
