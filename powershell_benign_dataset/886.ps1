
$managedRgId = (Get-AzManagedApplication -ResourceGroupName DemoApp).Properties.managedResourceGroupId


$locationPolicyDefinition = Get-AzPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c


$locationsArray = @("northeurope", "westeurope")
$policyParameters = @{"listOfAllowedLocations"=$locationsArray}


New-AzPolicyAssignment -Name locationAssignment -Scope $managedRgId -PolicyDefinition $locationPolicyDefinition -PolicyParameterObject $policyParameters
