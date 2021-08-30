














function Test-LocationCompleter
{
	$resourceTypes = @("Microsoft.Batch/operations")
	$locations = [Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters.LocationCompleterAttribute]::FindLocations($resourceTypes, -1)
	$expectedResourceType = (Get-AzResourceProvider -ProviderNamespace "Microsoft.Batch").ResourceTypes | Where-Object {$_.ResourceType -eq "operations"}
	$expectedLocations = $expectedResourceType.Locations | ForEach-Object {"`'" + $_ + "`'"}
	Assert-AreEqualArray $locations $expectedLocations
}



function Test-ResourceGroupCompleter
{
	$resourceGroups = [Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters.ResourceGroupCompleterAttribute]::GetResourceGroups(-1)
	$expectResourceGroups = Get-AzResourceGroup | ForEach-Object {$_.Name}
	Assert-AreEqualArray $resourceGroups $expectResourceGroups
}


function Test-ResourceIdCompleter
{
    $resourceType = "Microsoft.Storage/storageAccounts"
    $expectResourceIds = Get-AzResource -ResourceType $resourceType | ForEach-Object {$_.Id}
    
    $resourceIds = [Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters.ResourceIdCompleterAttribute]::GetResourceIds($resourceType)
    Assert-AreEqualArray $resourceIds $expectResourceIds
    
    $resourceIds = [Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters.ResourceIdCompleterAttribute]::GetResourceIds($resourceType)
    Assert-AreEqualArray $resourceIds $expectResourceIds
    
    [Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters.ResourceIdCompleterAttribute]::TimeToUpdate = [System.TimeSpan]::FromSeconds(0)
    
    $resourceIds = [Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters.ResourceIdCompleterAttribute]::GetResourceIds($resourceType)
    Assert-AreEqualArray $resourceIds $expectResourceIds
}
