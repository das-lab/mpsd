














function QueryOptions-QueryResultsWithFrom
{
	$from = Get-TestQueryIntervalStart

    $policyStates = Get-AzPolicyState -From $from -Top 10
	Validate-PolicyStates $policyStates 10
}


function QueryOptions-QueryResultsWithTo
{
	$to = Get-TestQueryIntervalEnd

    $policyStates = Get-AzPolicyState -To $to -Top 10
	Validate-PolicyStates $policyStates 10
}


function QueryOptions-QueryResultsWithTop
{
    $policyStates = Get-AzPolicyState -Top 10
	Validate-PolicyStates $policyStates 10
}


function QueryOptions-QueryResultsWithOrderBy
{
    $policyStates = Get-AzPolicyState -OrderBy "Timestamp asc, PolicyDefinitionAction, PolicyAssignmentId asc" -Top 10
	Validate-PolicyStates $policyStates 10
}


function QueryOptions-QueryResultsWithSelect
{
    $policyStates = Get-AzPolicyState -Select "Timestamp, ResourceId, PolicyAssignmentId, PolicyDefinitionId, IsCompliant, SubscriptionId, PolicyDefinitionAction, ComplianceState" -Top 10
	Validate-PolicyStates $policyStates 10
}


function QueryOptions-QueryResultsWithFilter
{
    $policyStates = Get-AzPolicyState -Filter "IsCompliant eq false and PolicyDefinitionAction eq 'deny'" -Top 10
	Validate-PolicyStates $policyStates 10
}


function QueryOptions-QueryResultsWithApply
{
    $policyStates = Get-AzPolicyState -Apply "groupby((PolicyAssignmentId, PolicyDefinitionId, ResourceId))/groupby((PolicyAssignmentId, PolicyDefinitionId), aggregate(`$count as NumResources))" -Top 10
	Foreach($policyState in $policyStates)
	{
		Assert-NotNull $policyState

		Assert-Null $policyState.ResourceId
		Assert-NotNullOrEmpty $policyState.PolicyAssignmentId
		Assert-NotNullOrEmpty $policyState.PolicyDefinitionId

		Assert-NotNull $policyState.AdditionalProperties
		Assert-NotNull $policyState.AdditionalProperties["NumResources"]
	}
}


function QueryOptions-QueryResultsWithExpandPolicyEvaluationDetails
{
	$resourceId = Get-TestResourceId

    $policyStates = Get-AzPolicyState -ResourceId $resourceId -Expand "PolicyEvaluationDetails" -Top 10
	Validate-PolicyStates $policyStates 10 -expandPolicyEvaluationDetails
}
