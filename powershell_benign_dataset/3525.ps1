














function Get-TestManagementGroupName
{
   "azgovtest5"
}


function Get-TestResourceGroupName
{
   "jilimpolicytest2"
}


function Get-TestResourceId
{
   "/subscriptions/d0610b27-9663-4c05-89f8-5b4be01e86a5/resourcegroups/govintpolicyrp/providers/microsoft.network/trafficmanagerprofiles/gov-int-policy-rp"
}


function Get-TestPolicySetDefinitionName
{
   "875cf75e-49c3-47f8-ab8d-89ba3d2311a0"
}


function Get-TestPolicyDefinitionName
{
   "24813039-7534-408a-9842-eb99f45721b1"
}


function Get-TestPolicyAssignmentName
{
   "f54e881207924ca8b2e39f6a"
}


function Get-TestResourceGroupNameForPolicyAssignmentEvents
{
   "jilimpolicytest2"
}


function Get-TestPolicyAssignmentNameResourceGroupLevelEvents
{
   "e9860612d8ec4a469f59af06"
}


function Get-TestResourceGroupNameForPolicyAssignmentStates
{
   "jilimpolicytest2"
}


function Get-TestPolicyAssignmentNameResourceGroupLevelStates
{
   "e9860612d8ec4a469f59af06"
}


function Get-TestQueryIntervalStart
{
   "2019-01-20 00:00:00Z"
}


function Get-TestQueryIntervalEnd
{
   "2019-04-15 00:00:00Z"
}


function Get-TestRemediationSubscriptionPolicyAssignmentId
{
   "/subscriptions/d0610b27-9663-4c05-89f8-5b4be01e86a5/providers/Microsoft.Authorization/policyAssignments/2deae24764b447c29af7c309"
}


function Get-TestRemediationMgPolicyAssignmentId
{
   "/providers/Microsoft.Management/managementGroups/PolicyUIMG/providers/Microsoft.Authorization/policyAssignments/326b090398a649e3858e3f23"
}


function Validate-PolicyEvents
{
   param([System.Collections.Generic.List`1[[Microsoft.Azure.Commands.PolicyInsights.Models.PolicyEvent]]]$policyEvents, [int]$count)

   Assert-True { $count -ge $policyEvents.Count }
   Assert-True { $policyEvents.Count -gt 0 }
   Foreach($policyEvent in $policyEvents)
   {
      Validate-PolicyEvent $policyEvent
   }
}


function Validate-PolicyEvent
{
   param([Microsoft.Azure.Commands.PolicyInsights.Models.PolicyEvent]$policyEvent)

   Assert-NotNull $policyEvent

   Assert-NotNull $policyEvent.Timestamp
   Assert-NotNullOrEmpty $policyEvent.ResourceId
   Assert-NotNullOrEmpty $policyEvent.PolicyAssignmentId
   Assert-NotNullOrEmpty $policyEvent.PolicyDefinitionId
   Assert-NotNull $policyEvent.IsCompliant
   Assert-NotNullOrEmpty $policyEvent.SubscriptionId
   Assert-NotNullOrEmpty $policyEvent.PolicyDefinitionAction
   Assert-NotNullOrEmpty $policyEvent.TenantId
   Assert-NotNullOrEmpty $policyEvent.PrincipalOid
}


function Validate-PolicyStates
{
   param(
      [System.Collections.Generic.List`1[[Microsoft.Azure.Commands.PolicyInsights.Models.PolicyState]]]$policyStates,
	  [int]$count,
	  [switch]$expandPolicyEvaluationDetails = $false)

   Assert-True { $count -ge $policyStates.Count }
   Assert-True { $policyStates.Count -gt 0 }
   Foreach($policyState in $policyStates)
   {
      Validate-PolicyState $policyState -expandPolicyEvaluationDetails:$expandPolicyEvaluationDetails
   }
}


function Validate-PolicyState
{
   param(
      [Microsoft.Azure.Commands.PolicyInsights.Models.PolicyState]$policyState,
	  [switch]$expandPolicyEvaluationDetails = $false)

   Assert-NotNull $policyState

   Assert-NotNull $policyState.Timestamp
   Assert-NotNullOrEmpty $policyState.ResourceId
   Assert-NotNullOrEmpty $policyState.PolicyAssignmentId
   Assert-NotNullOrEmpty $policyState.PolicyDefinitionId
   Assert-NotNull $policyState.IsCompliant
   Assert-NotNullOrEmpty $policyState.SubscriptionId
   Assert-NotNullOrEmpty $policyState.PolicyDefinitionAction
   Assert-NotNullOrEmpty $policyState.ComplianceState

   if ($expandPolicyEvaluationDetails -and $policyState.ComplianceState -eq "NonCompliant")
   {
      Assert-NotNull $policyState.PolicyEvaluationDetails
   }
   else
   {
      Assert-Null $policyState.PolicyEvaluationDetails
   }
}


function Validate-PolicyStateSummary
{
   param([Microsoft.Azure.Commands.PolicyInsights.Models.PolicyStateSummary]$policyStateSummary)

   Assert-NotNull $policyStateSummary

   Assert-NotNull $policyStateSummary.Results
   Assert-NotNull $policyStateSummary.Results.NonCompliantResources
   Assert-NotNull $policyStateSummary.Results.NonCompliantPolicies

   Assert-NotNull $policyStateSummary.PolicyAssignments
   Assert-True { $policyStateSummary.PolicyAssignments.Count -gt 0 } 

   Foreach($policyAssignmentSummary in $policyStateSummary.PolicyAssignments)
   {
      Assert-NotNull $policyAssignmentSummary

      Assert-NotNullOrEmpty $policyAssignmentSummary.PolicyAssignmentId

      Assert-NotNull $policyAssignmentSummary.Results
      Assert-NotNull $policyAssignmentSummary.Results.NonCompliantResources
      Assert-NotNull $policyAssignmentSummary.Results.NonCompliantPolicies

      Assert-NotNull $policyAssignmentSummary.PolicyDefinitions
      if ($policyAssignmentSummary.PolicyDefinitions.Count -gt 0)
	  {
		  Assert-True { ($policyAssignmentSummary.PolicyDefinitions | Where-Object { $_.Results.NonCompliantResources -gt 0 }).Count -eq $policyAssignmentSummary.Results.NonCompliantPolicies }

		  Foreach($policyDefinitionSummary in $policyAssignmentSummary.PolicyDefinitions)
		  {
			 Assert-NotNull $policyDefinitionSummary

			 Assert-NotNullOrEmpty $policyDefinitionSummary.PolicyDefinitionId
			 Assert-NotNullOrEmpty $policyDefinitionSummary.Effect

			 Assert-NotNull $policyDefinitionSummary.Results
			 Assert-NotNull $policyDefinitionSummary.Results.NonCompliantResources
			 Assert-Null $policyDefinitionSummary.Results.NonCompliantPolicies
		  }
	  }
   }
}


function Validate-Remediation
{
   param([Microsoft.Azure.Commands.PolicyInsights.Models.Remediation.PSRemediation]$remediation)

   Assert-NotNull $remediation

   Assert-NotNull $remediation.CreatedOn
   Assert-NotNull $remediation.LastUpdatedOn
   Assert-True { $remediation.Id -like "*/providers/microsoft.policyinsights/remediations/*" }
   Assert-AreEqual "Microsoft.PolicyInsights/remediations" $remediation.Type
   Assert-NotNullOrEmpty $remediation.Name
   Assert-NotNullOrEmpty $remediation.PolicyAssignmentId
   Assert-NotNullOrEmpty $remediation.ProvisioningState
   Assert-NotNull $remediation.DeploymentSummary
}


function Validate-RemediationDeployment
{
   param([Microsoft.Azure.Commands.PolicyInsights.Models.Remediation.PSRemediationDeployment]$deployment)

   Assert-NotNull $deployment

   Assert-NotNull $deployment.CreatedOn
   Assert-NotNull $deployment.LastUpdatedOn
   Assert-True { $deployment.RemediatedResourceId -like "/subscriptions/*/providers/*" }
   Assert-NotNullOrEmpty $deployment.Status
   Assert-NotNullOrEmpty $deployment.ResourceLocation
}


function Assert-NotNullOrEmpty
{
   param([string]$value)

   Assert-False { [string]::IsNullOrEmpty($value) }
}
