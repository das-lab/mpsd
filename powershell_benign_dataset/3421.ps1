














function Test-CreatesNewSimpleResource
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$location = Get-ProviderLocation "Microsoft.Sql/servers"
	$apiversion = "2014-04-01"
	$resourceType = "Microsoft.Sql/servers"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
        
        $actual = New-AzureRmResource -Name $rname -Location $location -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion 
	$expected = Get-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType -ApiVersion $apiversion
	
	$list = Get-AzureRmResource -ResourceGroupName $rgname

	
	Assert-AreEqual $expected.Name $actual.Name
	Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
	Assert-AreEqual $expected.ResourceType $actual.ResourceType
	Assert-AreEqual 1 @($list).Count
	Assert-AreEqual $expected.Name $list[0].Name
	Assert-AreEqual $expected.Sku $actual.Sku
}


function Test-CreatesNewComplexResource
{
	
	$rgname = Get-ResourceGroupName
	$rnameParent = Get-ResourceName
	$rnameChild = Get-ResourceName
	$resourceTypeParent = "Microsoft.Sql/servers"
	$resourceTypeChild = "Microsoft.Sql/servers/databases"
	$rglocation = Get-ProviderLocation ResourceManagement
	$location = Get-ProviderLocation $resourceTypeParent
	$apiversion = "2014-04-01"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
        
	$actualParent = New-AzureRmResource -Name $rnameParent -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeParent -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion
	$expectedParent = Get-AzureRmResource -Name $rnameParent -ResourceGroupName $rgname -ResourceType $resourceTypeParent -ApiVersion $apiversion

	$actualChild = New-AzureRmResource -Name $rnameChild -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -PropertyObject @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "1073741824"} -ApiVersion $apiversion
	$expectedChild = Get-AzureRmResource -Name $rnameChild -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -ApiVersion $apiversion

	$list = Get-AzureRmResource -ResourceGroupName $rgname

	$parentFromList = $list | where {$_.ResourceType -eq $resourceTypeParent} | Select-Object -First 1
	$childFromList = $list | where {$_.ResourceType -eq $resourceTypeChild} | Select-Object -First 1

	$listOfServers = Get-AzureRmResource -ResourceType $resourceTypeParent -ResourceGroupName $rgname
	$listOfDatabases = Get-AzureRmResource -ResourceType $resourceTypeChild -ResourceGroupName $rgname

	
	Assert-AreEqual $expectedParent.Name $actualParent.Name
	Assert-AreEqual $expectedChild.Name $actualChild.Name
	Assert-AreEqual $expectedParent.ResourceType $actualParent.ResourceType
	Assert-AreEqual $expectedChild.ResourceType $actualChild.ResourceType

	Assert-AreEqual 2 @($list).Count
	Assert-AreEqual $expectedParent.Name $parentFromList.Name
	Assert-AreEqual $expectedChild.Name $childFromList.Name
	Assert-AreEqual $expectedParent.ResourceType $parentFromList.ResourceType
	Assert-AreEqual $expectedChild.ResourceType $childFromList.ResourceType

	Assert-AreEqual 1 @($listOfServers).Count
	Assert-AreEqual 1 @($listOfDatabases).Count
}


function Test-GetResourcesViaPiping
{
	
	$rgname = Get-ResourceGroupName
	$rnameParent = Get-ResourceName
	$rnameChild = Get-ResourceName
	$resourceTypeParent = "Microsoft.Sql/servers"
	$resourceTypeChild = "Microsoft.Sql/servers/databases"
	$rglocation = Get-ProviderLocation ResourceManagement
	$location = Get-ProviderLocation $resourceTypeParent
	$apiversion = "2014-04-01"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
        
	New-AzureRmResource -Name $rnameParent -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeParent -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion		
	New-AzureRmResource -Name $rnameChild -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -PropertyObject @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "1073741824"} -ApiVersion $apiversion
		
	$list = Get-AzureRmResourceGroup -Name $rgname | Get-AzureRmResource
	$serverFromList = $list | where {$_.ResourceType -eq $resourceTypeParent} | Select-Object -First 1
	$databaseFromList = $list | where {$_.ResourceType -eq $resourceTypeChild} | Select-Object -First 1

	
	Assert-AreEqual 2 @($list).Count
	Assert-AreEqual $rnameParent $serverFromList.Name
	Assert-AreEqual $rnameChild $databaseFromList.Name
	Assert-AreEqual $resourceTypeParent $serverFromList.ResourceType
	Assert-AreEqual $resourceTypeChild $databaseFromList.ResourceType
}


function Test-GetResourcesFromEmptyGroup
{
	
	$rgname = Get-ResourceGroupName
	$location = Get-ProviderLocation ResourceManagement

	
	New-AzureRmResourceGroup -Name $rgname -Location $location
	$listViaPiping = Get-AzureRmResourceGroup -Name $rgname | Get-AzureRmResource
	$listViaDirect = Get-AzureRmResource -ResourceGroupName $rgname

	
	Assert-AreEqual 0 @($listViaPiping).Count
	Assert-AreEqual 0 @($listViaDirect).Count
}


function Test-GetResourcesFromNonExisingGroup
{
	
	$rgname = Get-ResourceGroupName

	
	Assert-Throws { Get-AzureRmResource -ResourceGroupName $rgname } "Provided resource group does not exist."
}


function Test-GetResourcesForNonExisingType
{
	
	$list = Get-AzureRmResource -ResourceType 'Non-Existing'

	
	Assert-AreEqual 0 @($list).Count
}


function Test-GetResourceForNonExisingResource
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceGroupName
	$location = Get-ProviderLocation ResourceManagement
	$resourceTypeWeb = "Microsoft.Web/sites"
	$resourceTypeSql = "Microsoft.Sql/servers"
	$apiversion = "2014-04-01"

	
	New-AzureRmResourceGroup -Name $rgname -Location $location
	Assert-Throws { Get-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceTypeWeb -ApiVersion $apiversion } "Provided resource does not exist."
	Assert-Throws { Get-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceTypeSql -ApiVersion $apiversion } "Provided resource does not exist."
	Assert-Throws { Get-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType 'Microsoft.Fake/nonexisting' -ApiVersion $apiversion } "Provided resource does not exist."
}


function Test-GetResourcesViaPipingFromAnotherResource
{
	
	$rgname = Get-ResourceGroupName
	$rnameParent = Get-ResourceName
	$rnameChild = Get-ResourceName
	$resourceTypeParent = "Microsoft.Sql/servers"
	$resourceTypeChild = "Microsoft.Sql/servers/databases"
	$rglocation = Get-ProviderLocation ResourceManagement
	$location = Get-ProviderLocation $resourceTypeParent
	$apiversion = "2014-04-01"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
        
	New-AzureRmResource -Name $rnameParent -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeParent -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion		
	New-AzureRmResource -Name $rnameChild -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -PropertyObject @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "1073741824"} -ApiVersion $apiversion
		
	$list = Get-AzureRmResource -ResourceGroupName $rgname | Get-AzureRmResource -ApiVersion $apiversion
		
	
	Assert-AreEqual 2 @($list).Count
}


function Test-MoveAResource
{
	
	$rgname = Get-ResourceGroupName
	$rgname2 = Get-ResourceGroupName + "test3"
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	New-AzureRmResourceGroup -Name $rgname2 -Location $rglocation
	$resource = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -ApiVersion $apiversion -Force
	Move-AzureRmResource -ResourceId $resource.ResourceId -DestinationResourceGroupName $rgname2 -Force

	$movedResource = Get-AzureRmResource -ResourceGroupName $rgname2 -ResourceName $rname -ResourceType $resourceType

	
	Assert-AreEqual $movedResource.Name $resource.Name
	Assert-AreEqual $movedResource.ResourceGroupName $rgname2
	Assert-AreEqual $movedResource.ResourceType $resource.ResourceType
}


function Test-MoveResourceFailed
{
	
	$exceptionMessage = "At least one valid resource Id must be provided.";
	Assert-Throws { Get-AzureRmResource | Where-Object { $PSItem.Name -eq "NonExistingResource" } | Move-AzureRmResource -DestinationResourceGroupName "AnyResourceGroup" } $exceptionMessage

	
	$resourceId1 = "/subscriptions/fb3a3d6b-44c8-44f5-88c9-b20917c9b96b/resourceGroups/tianorg1/providers/Microsoft.Storage/storageAccounts/temp1"
	$resourceId2 = "/subscriptions/fb3a3d6b-44c8-44f5-88c9-b20917c9b96b/resourceGroups/tianorg2/providers/Microsoft.Storage/storageAccounts/temp1"
	$exceptionMessage = "The resources being moved must all reside in the same resource group. The resources: *"
	Assert-ThrowsLike { Move-AzureRmResource -DestinationResourceGroupName "AnyGroup" -ResourceId @($resourceId1, $resourceId2) } $exceptionMessage
}


function Test-SetAResource
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$resource = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	
	
	$oldSku = $resource.Sku.psobject
	$oldSkuNameProperty = $oldSku.Properties
	Assert-AreEqual $oldSkuNameProperty.Name "name" 
	Assert-AreEqual $resource.SKu.Name "A0" 
	
	
	Set-AzureRmResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -Properties @{"key2" = "value2"} -Force
	Set-AzureRmResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -SkuObject @{ Name = "A1" }  -Force 

	$modifiedResource = Get-AzureRmResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType

	
	Assert-AreEqual $modifiedResource.Properties.key2 "value2"
	Assert-AreEqual $modifiedResource.Sku.Name "A1" 
}


function Test-SetAResourceWithPatch
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$resource = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	Set-AzureRmResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -Properties @{"key2" = "value2"} -Force
	Set-AzureRmResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -SkuObject @{ Name = "A1" } -UsePatchSemantics -Force 

	$modifiedResource = Get-AzureRmResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType

	
	Assert-AreEqual $modifiedResource.Properties.key2 "value2"
	Assert-AreEqual $modifiedResource.Sku.Name "A1" 
}


function Test-FindAResource
{
	
	$rgname = Get-ResourceGroupName
	$rname = "testname"
	$rname2 = "test2name"
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$actual = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId
	
	$expected = Find-AzureRmResource -ResourceType $resourceType -ResourceGroupNameContains $rgName
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

	New-AzureRmResource -Name $rname2 -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-AreEqual 2 @($expected).Count

	$expected = Find-AzureRmResource -ResourceGroupNameEquals $rgname -ResourceNameEquals $rname
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId
}


function Test-FindAResource-ByTag
{
	
	$rgname = Get-ResourceGroupName
	$rname = "testname"
	$rname2 = "test2name"
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$actual = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{ScenarioTestTag = "ScenarioTestVal"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$expected = Find-AzureRmResource -Tag @{ScenarioTestTag = "ScenarioTestVal"}
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

	$expected = Find-AzureRmResource -Tag @{ScenarioTestTag = $null}
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

	$expected = Find-AzureRmResource -TagName "ScenarioTestTag"
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

	$expected = Find-AzureRmResource -TagName "ScenarioTestTag" -TagValue "ScenarioTestVal"
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId
}


function Test-GetResourceExpandProperties
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$resource = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$resourceGet = Get-AzureRmResource -ResourceName $rname -ResourceGroupName $rgname -ExpandProperties

	
	$properties = $resourceGet.Properties.psobject
	$keyProperty = $properties.Properties
	Assert-AreEqual $keyProperty.Name "key"
	Assert-AreEqual $resourceGet.Properties.key "value"
}


function Test-GetResourceWithCollection
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "East US"
	$apiversion = "2015-08-01"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplate.json -TemplateParameterFile sampleTemplateParams.json
	$resourceGet = Get-AzureRmResource -ResourceGroupName $rgname -ResourceType Microsoft.Web/serverFarms -IsCollection -ApiVersion 2015-08-01

	
	Assert-AreEqual $resourceGet.ResourceType "Microsoft.Web/serverFarms"
}


function Test-ManageResourceWithZones
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$location = "Central US"
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
    $created = New-AzureRmResource -Name $rname -Location $location -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -Zones @("2") -Force
	
	
	Assert-NotNull $created
	Assert-AreEqual $created.Zones.Length 1
	Assert-AreEqual $created.Zones[0] "2"

	$resourceGet = Get-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType
	
	
	Assert-NotNull $resourceGet
	Assert-AreEqual $resourceGet.Zones.Length 1
	Assert-AreEqual $resourceGet.Zones[0] "2"

	$resourceSet = set-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType -Zones @("3") -Force
	
	
	Assert-NotNull $resourceSet
	Assert-AreEqual $resourceSet.Zones.Length 1
	Assert-AreEqual $resourceSet.Zones[0] "3"

	$resourceGet = Get-AzureRmResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType
	
	
	Assert-NotNull $resourceGet
	Assert-AreEqual $resourceGet.Zones.Length 1
	Assert-AreEqual $resourceGet.Zones[0] "3"
}


function Test-RemoveAResource
{
	
	$rgname = Get-ResourceGroupName
	$rname = "testname"
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$actual = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

	Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname | Remove-AzureRmResource -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-Null $expected
}


function Test-RemoveASetOfResources
{
	
	$rgname = Get-ResourceGroupName
	$rname = "testname"
	$rname2 = "test2name"
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
	$actual = New-AzureRmResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId
	
	$expected = Find-AzureRmResource -ResourceType $resourceType -ResourceGroupNameContains $rgName
	Assert-NotNull $expected
	Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

	New-AzureRmResource -Name $rname2 -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-AreEqual 2 @($expected).Count

	Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname | Remove-AzureRmResource -Force
	$expected = Find-AzureRmResource -ResourceNameContains test -ResourceGroupNameContains $rgname
	Assert-Null $expected
}