



$registryName = "<container-registry-name>"
$resourceGroup = "<resource-group-name>"
$servicePrincipalId = "<service-principal-id>"



$registry = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $registryName



$sp = Get-AzADServicePrincipal -ServicePrincipalName $servicePrincipalId






$role = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName acrpull -Scope $registry.Id
