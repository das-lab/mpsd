














function Test-CreatesNewSimpleResourceGroup
{
    
    $rgname = Get-ResourceGroupName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"

    try
    {
        
        $actual = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval"}
        $expected = Get-AzResourceGroup -Name $rgname

        
        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.Tags["testtag"] $actual.Tags["testtag"]
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-UpdatesExistingResourceGroup
{
    
    $rgname = Get-ResourceGroupName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"

    try
    {
        
        Set-AzResourceGroup -Name $rgname -Tags @{testtag = "testval"} -ErrorAction SilentlyContinue
        Assert-True { $Error[0] -like "*Provided resource group does not exist." }
        $Error.Clear()

        $new = New-AzResourceGroup -Name $rgname -Location $location

        $actual = Set-AzResourceGroup -Name $rgname -Tags @{ testtag = "testval" }
        $expected = Get-AzResourceGroup -Name $rgname

        
        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual 0 $new.Tags.Count
        Assert-AreEqual $expected.Tags["testtag"] $actual.Tags["testtag"]
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-CreatesAndRemoveResourceGroupViaPiping
{
    
    $rgname1 = Get-ResourceGroupName
    $rgname2 = Get-ResourceGroupName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"

    
    New-AzResourceGroup -Name $rgname1 -Location $location
    New-AzResourceGroup -Name $rgname2 -Location $location

    $job = Get-AzResourceGroup | where {$_.ResourceGroupName -eq $rgname1 -or $_.ResourceGroupName -eq $rgname2} | Remove-AzResourceGroup -Force -AsJob
	Wait-Job $job

    
    Get-AzResourceGroup -Name $rgname1 -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()

    Get-AzResourceGroup -Name $rgname2 -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
}


function Test-GetNonExistingResourceGroup
{
    
    $rgname = Get-ResourceGroupName

    Get-AzResourceGroup -Name $rgname -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
}


function Test-NewResourceGroupInNonExistingLocation
{
    
    $rgname = Get-ResourceGroupName

    Assert-Throws { New-AzResourceGroup -Name $rgname -Location 'non-existing' }
}


function Test-RemoveNonExistingResourceGroup
{
    
    $rgname = Get-ResourceGroupName

    Remove-AzResourceGroup -Name $rgname -Force -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
}


function Test-AzureTagsEndToEnd
{
    
    $tag1 = getAssetName
    $tag2 = getAssetName
    Clean-Tags

    
    New-AzTag $tag1

    $tag = Get-AzTag $tag1
    Assert-AreEqual $tag1 $tag.Name

    
    New-AzTag $tag1 value1
    New-AzTag $tag1 value1
    New-AzTag $tag1 value2

    $tag = Get-AzTag $tag1
    Assert-AreEqual 2 $tag.Values.Count

    
    New-AzTag $tag2 value1
    New-AzTag $tag2 value2
    New-AzTag $tag2 value3

    $tags = Get-AzTag
    Assert-AreEqual 2 $tags.Count

    
    $tag = Remove-AzTag $tag1 -Force -PassThru

    $tags = Get-AzTag
    Assert-AreEqual $tag1 $tag.Name

    
    $tag = Remove-AzTag $tag2 value1 -Force -PassThru

    $tags = Get-AzTag
    Assert-AreEqual 0 $tags.Count

    
    Assert-Throws { Get-AzTag "non-existing" }

    Clean-Tags
}


function Test-NewDeploymentAndProviderRegistration
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $template = "Microsoft.Cache.0.4.0-preview"
    $provider = "microsoft.cache"

    try
    {
        
        $subscription = [Microsoft.WindowsAzure.Commands.Utilities.Common.AzureProfile]::Instance.CurrentSubscription
        $client = New-Object Microsoft.Azure.Commands.Resources.Models.ResourcesClient $subscription

        
        $providers = [Microsoft.WindowsAzure.Commands.Utilities.Common.AzureProfile]::Instance.CurrentSubscription.RegisteredResourceProvidersList
        if( $providers -Contains $provider )
        {
            $client.UnregisterProvider($provider)
        }

        
        $deployment = New-AzResourceGroup -Name $rgname -Location $location -GalleryTemplateIdentity $template -cacheName $rname -cacheLocation $location

        
        $client = New-Object Microsoft.Azure.Commands.Resources.Models.ResourcesClient $subscription
        $providers = [Microsoft.WindowsAzure.Commands.Utilities.Common.AzureProfile]::Instance.CurrentSubscription.RegisteredResourceProvidersList

        Assert-True { $providers -Contains $provider }

    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RemoveDeployment
{
    
    $deploymentName = "Test"
    $templateUri = "https://gallery.azure.com/artifact/20140901/Microsoft.ResourceGroup.1.0.0/DeploymentTemplates/Template.json"
    $rgName = "TestSDK0123"

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location "East US"
        $job = New-AzResourceGroupDeployment -ResourceGroupName $rgName -Name $deploymentName -TemplateUri $templateUri -AsJob
		Wait-Job $job
		$deployment = Receive-Job $job
		Assert-True { Remove-AzResourceGroupDeployment -ResourceGroupName $deployment.ResourceGroupName -Name $deployment.DeploymentName }
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-FindResourceGroup
{
    
    $rgname = Get-ResourceGroupName
	$rgname2 = Get-ResourceGroupName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
	$originalResorcrGroups = Get-AzResourceGroup
	$originalCount = @($originalResorcrGroups).Count

    try
    {
        
        $actual = New-AzResourceGroup -Name $rgname -Location $location -Tag @{ testtag = "testval" }
        $actual2 = New-AzResourceGroup -Name $rgname2 -Location $location -Tag @{ testtag = "testval2" }

        $expected1 = Get-AzResourceGroup -Name $rgname
        
        Assert-AreEqual $expected1.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected1.Tags["testtag"] $actual.Tags["testtag"]

		$expected2 = Get-AzResourceGroup -Name $rgname2
        
        Assert-AreEqual $expected2.ResourceGroupName $actual2.ResourceGroupName
        Assert-AreEqual $expected2.Tags["testtag"] $actual2.Tags["testtag"]

		$expected2 = Get-AzResourceGroup -Name ($rgname2 + "*")
        
        Assert-AreEqual $expected2.ResourceGroupName $actual2.ResourceGroupName
        Assert-AreEqual $expected2.Tags["testtag"] $actual2.Tags["testtag"]

		$expected3 = Get-AzResourceGroup
		$expectedCount = $originalCount + 2
		
		Assert-AreEqual @($expected3).Count $expectedCount

		$expected3 = Get-AzResourceGroup -Name *
		$expectedCount = $originalCount + 2
		
		Assert-AreEqual @($expected3).Count $expectedCount

		$expected4 = Get-AzResourceGroup -Tag @{ testtag = $null}
        
        Assert-AreEqual @($expected4).Count 2

		$expected5 = Get-AzResourceGroup -Tag @{ testtag = "testval" }
        
        Assert-AreEqual @($expected5).Count 1

		$expected6 = Get-AzResourceGroup -Tag @{ testtag2 = $null }
        
        Assert-AreEqual @($expected6).Count 0
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $rgname2
    }
}


function Test-GetNonExistingResourceGroupWithDebugStream
{
    $ErrorActionPreference="Continue"
    $output = $(Get-AzResourceGroup -Name "InvalidNonExistRocks" -Debug) 2>&1 5>&1 | Out-String
    $ErrorActionPreference="Stop"
    Assert-True { $output -Like "*============================ HTTP RESPONSE ============================*" }
}


function Test-ExportResourceGroup
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"


	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $rglocation
                
		$r = New-AzResource -Name $rname -Location "centralus" -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
		Assert-AreEqual $r.ResourceGroupName $rgname

		$exportOutput = Export-AzResourceGroup -ResourceGroupName $rgname -Force
		Assert-NotNull $exportOutput
		Assert-True { $exportOutput.Path.Contains($rgname + ".json") }
	}

	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ExportResourceGroupWithFiltering
{
    
    $rgname = Get-ResourceGroupName
    $rname1 = Get-ResourceName
    $rname2 = Get-ResourceName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $apiversion = "2014-04-01"
    $resourceType = "Providers.Test/statefulResources"


    try
    {
        
        New-AzResourceGroup -Name $rgname -Location $rglocation

        
        $r1 = New-AzResource -Name $rname1 -Location "centralus" -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        Assert-NotNull $r1.ResourceId

        
        $r2 = New-AzResource -Name $rname2 -Location "centralus" -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
        Assert-NotNull $r2.ResourceId

        $exportOutput = Export-AzResourceGroup -ResourceGroupName $rgname -Force -Resource @($r2.ResourceId) -IncludeParameterDefaultValue -IncludeComments
        Assert-NotNull $exportOutput
        Assert-True { $exportOutput.Path.Contains($rgname + ".json") }
    }

    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ResourceGroupWithPositionalParams
{
    
    $rgname = Get-ResourceGroupName
    $location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"

    try
    {
        $ErrorActionPreference = "SilentlyContinue"
        $Error.Clear()
        
        $actual = New-AzResourceGroup $rgname $location
        $expected = Get-AzResourceGroup $rgname

        
        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName

        
        Remove-AzResourceGroup $rgname -Force
    }
    catch
    {
        Assert-True { $Error[0].Contains("Provided resource group does not exist.") }
    }
}