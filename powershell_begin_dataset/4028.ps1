














function Test-CreatesNewSimpleResource
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $location = Get-Location "Microsoft.Sql" "servers" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Microsoft.Sql/servers"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
        
        $actual = New-AzResource -Name $rname -Location $location -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion
    $expected = Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType -ApiVersion $apiversion

    $list = Get-AzResource -ResourceGroupName $rgname

    
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
    $resourceTypeChild = "Microsoft.Sql/servers/databases"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $location = Get-Location "Microsoft.Sql" "servers" "West US"
    $apiversion = "2014-04-01"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
        
    $actualParent = New-AzResource -Name $rnameParent -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeParent -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion
    $expectedParent = Get-AzResource -Name $rnameParent -ResourceGroupName $rgname -ResourceType $resourceTypeParent -ApiVersion $apiversion

    $actualChild = New-AzResource -Name $rnameChild -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -PropertyObject @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "1073741824"} -ApiVersion $apiversion
    $expectedChild = Get-AzResource -Name $rnameChild -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -ApiVersion $apiversion

    $list = Get-AzResource -ResourceGroupName $rgname

    $parentFromList = $list | where {$_.ResourceType -eq $resourceTypeParent} | Select-Object -First 1
    $childFromList = $list | where {$_.ResourceType -eq $resourceTypeChild} | Select-Object -First 1

    $listOfServers = Get-AzResource -ResourceType $resourceTypeParent -ResourceGroupName $rgname
    $listOfDatabases = Get-AzResource -ResourceType $resourceTypeChild -ResourceGroupName $rgname

    
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
    $resourceTypeChild = "Microsoft.Sql/servers/databases"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $location = Get-Location "Microsoft.Sql" "servers" "West US"
    $apiversion = "2014-04-01"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
        
    New-AzResource -Name $rnameParent -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeParent -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion
    New-AzResource -Name $rnameChild -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -PropertyObject @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "1073741824"} -ApiVersion $apiversion

    $list = Get-AzResourceGroup -Name $rgname | Get-AzResource
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
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"

    
    New-AzResourceGroup -Name $rgname -Location $location
    $listViaPiping = Get-AzResourceGroup -Name $rgname | Get-AzResource
    $listViaDirect = Get-AzResource -ResourceGroupName $rgname

    
    Assert-AreEqual 0 @($listViaPiping).Count
    Assert-AreEqual 0 @($listViaDirect).Count
}


function Test-GetResourcesFromNonExisingGroup
{
    
    $rgname = Get-ResourceGroupName

    
    Assert-Throws { Get-AzResource -ResourceGroupName $rgname } "Provided resource group does not exist."
}


function Test-GetResourcesForNonExisingType
{
    
    $list = Get-AzResource -ResourceType 'Non-Existing'

    
    Assert-AreEqual 0 @($list).Count
}


function Test-GetResourceForNonExisingResource
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceGroupName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $resourceTypeWeb = "Microsoft.Web/sites"
    $resourceTypeSql = "Microsoft.Sql/servers"
    $apiversion = "2014-04-01"

    
    New-AzResourceGroup -Name $rgname -Location $location
    Assert-Throws { Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceTypeWeb -ApiVersion $apiversion } "Provided resource does not exist."
    Assert-Throws { Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceTypeSql -ApiVersion $apiversion } "Provided resource does not exist."
    Assert-Throws { Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType 'Microsoft.Fake/nonexisting' -ApiVersion $apiversion } "Provided resource does not exist."
}


function Test-GetResourcesViaPipingFromAnotherResource
{
    
    $rgname = Get-ResourceGroupName
    $rnameParent = Get-ResourceName
    $rnameChild = Get-ResourceName
    $resourceTypeChild = "Microsoft.Sql/servers/databases"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $location = Get-Location "Microsoft.Sql" "servers" "West US"
    $apiversion = "2014-04-01"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
        
    New-AzResource -Name $rnameParent -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeParent -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion
    New-AzResource -Name $rnameChild -Location $location -ResourceGroupName $rgname -ResourceType $resourceTypeChild -ParentResource servers/$rnameParent -PropertyObject @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "1073741824"} -ApiVersion $apiversion

    $list = Get-AzResource -ResourceGroupName $rgname | Get-AzResource -ApiVersion $apiversion

    
    Assert-AreEqual 2 @($list).Count
}


function Test-MoveAResource
{
    
    $rgname = Get-ResourceGroupName
    $rgname2 = Get-ResourceGroupName + "test3"
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation
        New-AzResourceGroup -Name $rgname2 -Location $rglocation
        $resource = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -ApiVersion $apiversion -Force
        Move-AzResource -ResourceId $resource.ResourceId -DestinationResourceGroupName $rgname2 -Force

        $movedResource = Get-AzResource -ResourceGroupName $rgname2 -ResourceName $rname -ResourceType $resourceType

        
        Assert-AreEqual $movedResource.Name $resource.Name
        Assert-AreEqual $movedResource.ResourceGroupName $rgname2
        Assert-AreEqual $movedResource.ResourceType $resource.ResourceType
    }
    finally
    {
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $rgname2
    }
}


function Test-MoveResourceFailed
{
    
    $exceptionMessage = "At least one valid resource Id must be provided.";
    Assert-Throws { Get-AzResource | Where-Object { $PSItem.Name -eq "NonExistingResource" } | Move-AzResource -DestinationResourceGroupName "AnyResourceGroup" } $exceptionMessage

    
    $resourceId1 = "/subscriptions/fb3a3d6b-44c8-44f5-88c9-b20917c9b96b/resourceGroups/tianorg1/providers/Microsoft.Storage/storageAccounts/temp1"
    $resourceId2 = "/subscriptions/fb3a3d6b-44c8-44f5-88c9-b20917c9b96b/resourceGroups/tianorg2/providers/Microsoft.Storage/storageAccounts/temp1"
    $exceptionMessage = "The resources being moved must all reside in the same resource group. The resources: *"
    Assert-ThrowsLike { Move-AzResource -DestinationResourceGroupName "AnyGroup" -ResourceId @($resourceId1, $resourceId2) } $exceptionMessage
}


function Test-SetAResource
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $resource = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force

        
        $oldSku = $resource.Sku.psobject
        $oldSkuNameProperty = $oldSku.Properties
        Assert-AreEqual $oldSkuNameProperty.Name "name"
        Assert-AreEqual $resource.SKu.Name "A0"

        
        Set-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -Properties @{"key2" = "value2"} -Force
        $job = Set-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -SkuObject @{ Name = "A1" }  -Force -AsJob
        $job | Wait-Job

        $modifiedResource = Get-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType

        
        Assert-AreEqual $modifiedResource.Properties.key2 "value2"
        Assert-AreEqual $modifiedResource.Sku.Name "A1"
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-SetAResourceUsingPiping
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation
        New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        $resource = Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType

        
        Assert-AreEqual $resource.Name $rname
        Assert-AreEqual $resource.ResourceGroupName $rgname
        Assert-AreEqual $resource.ResourceType $resourceType
        Assert-AreEqual $resource.Sku.Name "A0"
        Assert-AreEqual $resource.Tags["testtag"] "testval"
        Assert-AreEqual $resource.Properties.key "value"

        
        
        $setResource = $resource | Set-AzResource -Force
        Assert-NotNull $setResource
        Assert-AreEqual $setResource.Name $rname
        Assert-AreEqual $setResource.ResourceGroupName $rgname
        Assert-AreEqual $setResource.ResourceType $resourceType
        Assert-AreEqual $setResource.Sku.Name "A0"
        Assert-AreEqual $setResource.Tags["testtag"] "testval"
        Assert-AreEqual $setResource.Properties.key "value"

        
        $resource.Tags.Add("testtag1", "testval1")
        $resource.Sku.Name = "A1"
        $setResource = $resource | Set-AzResource -Force
        Assert-NotNull $setResource
        Assert-AreEqual $setResource.Name $rname
        Assert-AreEqual $setResource.ResourceGroupName $rgname
        Assert-AreEqual $setResource.ResourceType $resourceType
        Assert-AreEqual $setResource.Sku.Name "A1"
        Assert-AreEqual $setResource.Tags["testtag"] "testval"
        Assert-AreEqual $setResource.Tags["testtag1"] "testval1"
        Assert-AreEqual $setResource.Properties.key "value"

        $modifiedResource = Get-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType

        
        Assert-NotNull $modifiedResource
        Assert-AreEqual $modifiedResource.Name $rname
        Assert-AreEqual $modifiedResource.ResourceGroupName $rgname
        Assert-AreEqual $modifiedResource.ResourceType $resourceType
        Assert-AreEqual $modifiedResource.Sku.Name "A1"
        Assert-AreEqual $modifiedResource.Tags["testtag"] "testval"
        Assert-AreEqual $modifiedResource.Tags["testtag1"] "testval1"
        Assert-AreEqual $modifiedResource.Properties.key "value"
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-SetAResourceWithPatch
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
    $resource = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
    Set-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -Properties @{"key2" = "value2"} -Force
    Set-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType -SkuObject @{ Name = "A1" } -UsePatchSemantics -Force

    $modifiedResource = Get-AzResource -ResourceGroupName $rgname -ResourceName $rname -ResourceType $resourceType

    
    Assert-AreEqual $modifiedResource.Properties.key2 "value2"
    Assert-AreEqual $modifiedResource.Sku.Name "A1"
}


function Test-FindAResource
{
    
    $rgname = Get-ResourceGroupName
    $rname = "testname"
    $rname2 = "test2name"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $actual = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        $expected = Get-AzResource -ResourceName "*test*" -ResourceGroupName "*$rgname*"
        Assert-NotNull $expected
        Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

        $expected = Get-AzResource -ResourceType $resourceType -ResourceGroupName "*$rgName*"
        Assert-NotNull $expected
        Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

        New-AzResource -Name $rname2 -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        $expected = Get-AzResource -ResourceName "*test*" -ResourceGroupName "*$rgname*"
        Assert-AreEqual 2 @($expected).Count

        $expected = Get-AzResource -ResourceGroupName $rgname -ResourceName $rname
        Assert-NotNull $expected
        Assert-AreEqual $actual.ResourceId $expected[0].ResourceId
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-FindAResource-ByTag
{
    
    $rgname = Get-ResourceGroupName
    $rname = "testname"
    $rname2 = "test2name"
    $rname3 = "test3name"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $actual1 = New-AzResource -Name $rname -Location $rglocation -Tags @{ScenarioTestTag = "ScenarioTestVal"} -ResourceGroupName $rgname -ResourceType $resourceType -ApiVersion $apiversion -Force
        $actual2 = New-AzResource -Name $rname2 -Location $rglocation -Tags @{ScenarioTestTag = $null} -ResourceGroupName $rgname -ResourceType $resourceType -ApiVersion $apiversion -Force
        $actual3 = New-AzResource -Name $rname3 -Location $rglocation -Tags @{ScenarioTestTag = "RandomTestVal"; RandomTestVal = "ScenarioTestVal"} -ResourceGroupName $rgname -ResourceType $resourceType -ApiVersion $apiversion -Force

        
        $expected = Get-AzResource -Tag @{ScenarioTestTag = "ScenarioTestVal"}
        Assert-NotNull $expected
        Assert-AreEqual $expected.Count 1
        Assert-AreEqual $actual1.ResourceId $expected[0].ResourceId

        $expected = Get-AzResource -TagName "ScenarioTestTag" -TagValue "ScenarioTestVal"
        Assert-NotNull $expected
        Assert-AreEqual $expected.Count 1
        Assert-AreEqual $actual1.ResourceId $expected[0].ResourceId

        
        $expected = Get-AzResource -Tag @{ScenarioTestTag = $null}
        Assert-NotNull $expected
        Assert-AreEqual $expected.Count 3
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual1.ResourceId } }
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual2.ResourceId } }
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual3.ResourceId } }

        $expected = Get-AzResource -TagName "ScenarioTestTag"
        Assert-NotNull $expected
        Assert-AreEqual $expected.Count 3
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual1.ResourceId } }
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual2.ResourceId } }
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual3.ResourceId } }

        
        $expected = Get-AzResource -TagValue "ScenarioTestVal"
        Assert-NotNull $expected
        Assert-AreEqual $expected.Count 2
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual1.ResourceId } }
        Assert-NotNull { $expected | where { $_.ResourceId -eq $actual3.ResourceId } }
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-GetResourceExpandProperties
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $resource = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        $resourceGet = Get-AzResource -ResourceName $rname -ResourceGroupName $rgname -ExpandProperties

        
        $properties = $resourceGet.Properties.psobject
        $keyProperty = $properties.Properties
        Assert-AreEqual $keyProperty.Name "key"
        Assert-AreEqual $resourceGet.Properties.key "value"
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-GetResourceByIdAndProperties
{
	
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

	try
	{
		
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $resource = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        $resourceGet = Get-AzResource -ResourceId $resource.ResourceId

		
		Assert-NotNull $resourceGet
		Assert-AreEqual $resourceGet.Name $rname
		Assert-AreEqual $resourceGet.ResourceGroupName $rgname
		Assert-AreEqual $resourceGet.ResourceType $resourceType
		$properties = $resourceGet.Properties
		Assert-NotNull $properties
		Assert-NotNull $properties.key
		Assert-AreEqual $properties.key "value"
	}
	finally
	{
		Clean-ResourceGroup $rgname
	}
}


function Test-GetChildResourcesById
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $location = "West US 2"
    $siteType = "Microsoft.Web/sites"
    $slotType = "Microsoft.Web/sites/slots"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $location
        $deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile webapp-with-slots-azuredeploy.json -TemplateParameterFile webapp-with-slots-azuredeploy.parameters.json

	    Assert-AreEqual Succeeded $deployment.ProvisioningState

        $sites = Get-AzResource -ResourceGroupName $rgname -ResourceType $siteType
        $slots = Get-AzResource -ResourceGroupName $rgname -ResourceType $slotType

        Assert-NotNull $sites
        Assert-NotNull $slots
        Assert-AreEqual $sites.Count 1
        Assert-AreEqual $slots.Count 4

        $resourceId = $sites.ResourceId + "/slots"
        $slots = Get-AzResource -ResourceId $resourceId
        Assert-NotNull $slots
        Assert-AreEqual $slots.Count 4
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-SetNestedResourceByPiping
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $location = "West US 2"
    $siteType = "Microsoft.Web/sites"
    $configType = "Microsoft.Web/sites/config"
    $apiVersion = "2018-02-01"

    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $location
        $deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile webapp-with-slots-azuredeploy.json -TemplateParameterFile webapp-with-slots-azuredeploy.parameters.json
	    Assert-AreEqual Succeeded $deployment.ProvisioningState

        $sites = Get-AzResource -ResourceGroupName $rgname -ResourceType $siteType
        Assert-NotNull $sites

        $siteName = $sites.Name
        $config = Get-AzResource -ResourceGroupName $rgname -ResourceType $configType -Name $siteName -ApiVersion $apiVersion
        Assert-NotNull $config

        $result = $config | Set-AzResource -ApiVersion $apiVersion -Force
        Assert-NotNull $result
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}


function Test-GetResourceByComponentsAndProperties
{
	
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

	try
	{
		
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $resource = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        $resourceGet = Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType

		
		Assert-NotNull $resourceGet
		Assert-AreEqual $resourceGet.Name $rname
		Assert-AreEqual $resourceGet.ResourceGroupName $rgname
		Assert-AreEqual $resourceGet.ResourceType $resourceType
		$properties = $resourceGet.Properties
		Assert-NotNull $properties
		Assert-NotNull $properties.key
		Assert-AreEqual $properties.key "value"
	}
	finally
	{
		Clean-ResourceGroup $rgname
	}
}


function Test-ManageResourceWithZones
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $location = "Central US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
    $created = New-AzResource -Name $rname -Location $location -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -Zones @("2") -Force

    
    Assert-NotNull $created
    Assert-AreEqual $created.Zones.Length 1
    Assert-AreEqual $created.Zones[0] "2"

    $resourceGet = Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType

    
    Assert-NotNull $resourceGet
    Assert-AreEqual $resourceGet.Zones.Length 1
    Assert-AreEqual $resourceGet.Zones[0] "2"

    $resourceSet = set-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType -Zones @("3") -Force

    
    Assert-NotNull $resourceSet
    Assert-AreEqual $resourceSet.Zones.Length 1
    Assert-AreEqual $resourceSet.Zones[0] "3"

    $resourceGet = Get-AzResource -Name $rname -ResourceGroupName $rgname -ResourceType $resourceType

    
    Assert-NotNull $resourceGet
    Assert-AreEqual $resourceGet.Zones.Length 1
    Assert-AreEqual $resourceGet.Zones[0] "3"
}


function Test-RemoveAResource
{
    
    $rgname = Get-ResourceGroupName
    $rname = "testname"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
    $job = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force -AsJob
    $job | Wait-Job
    $actual = $job | Receive-Job
    
    Wait-Seconds 2
    $expected = Get-AzResource -ResourceName $rname -ResourceGroupName $rgname
    Assert-NotNull $expected
    Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

    $job = Remove-AzResource -ResourceId $expected[0].ResourceId -Force -AsJob
    $job | Wait-Job

    $expected = Get-AzResource -ResourceName $rname -ResourceGroupName $rgname
    Assert-Null $expected
}


function Test-RemoveASetOfResources
{
    
    $rgname = Get-ResourceGroupName
    $rname = "testname"
    $rname2 = "test2name"
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"

    
    New-AzResourceGroup -Name $rgname -Location $rglocation
    $actual = New-AzResource -Name $rname -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
    $expected = Get-AzResource -ResourceName "*test*" -ResourceGroupName "*$rgname*"
    Assert-NotNull $expected
    Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

    $expected = Get-AzResource -ResourceType $resourceType -ResourceGroupName "*$rgName*"
    Assert-NotNull $expected
    Assert-AreEqual $actual.ResourceId $expected[0].ResourceId

    New-AzResource -Name $rname2 -Location $rglocation -Tags @{testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"key" = "value"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
    $expected = Get-AzResource -ResourceName "*test*" -ResourceGroupName "*$rgname*"
    Assert-AreEqual 2 @($expected).Count

    Get-AzResource -ResourceName "*test*" -ResourceGroupName "*$rgname*" | Remove-AzResource -Force
    $expected = Get-AzResource -ResourceName "*test*" -ResourceGroupName "*$rgname*"
    Assert-Null $expected
}