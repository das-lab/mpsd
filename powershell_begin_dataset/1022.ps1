$rgName = <Specify your lab's resource group name>
$subscriptionId = <Specify your subscription ID>
$labName = <Specify your lab name>


Get-AzProviderOperation -OperationSearchString "Microsoft.DevTestLab/*"

(Get-AzRoleDefinition "DevTest Labs User").Actions

$policyRoleDef = (Get-AzRoleDefinition "DevTest Labs User")
$policyRoleDef.Id = $null
$policyRoleDef.Name = "Policy Contributor"
$policyRoleDef.IsCustom = $true
$policyRoleDef.AssignableScopes.Clear()
$policyRoleDef.AssignableScopes.Add("/subscriptions/" + $subscriptionId)
$policyRoleDef.Actions.Add("Microsoft.DevTestLab/labs/policySets/policies/*")
$policyRoleDef = (New-AzRoleDefinition -Role $policyRoleDef)

$user=Get-AzADUser -SearchString "SomeUser"
$scope = '/subscriptions/' + subscriptionId + '/resourceGroups/' + $rgName + '/providers/Microsoft.DevTestLab/labs/' + $labName + '/policySets/default/policies/AllowedVmSizesInLab'
New-AzRoleAssignment -ObjectId $user.ObjectId -RoleDefinitionName "Policy Contributor" -Scope $scope
