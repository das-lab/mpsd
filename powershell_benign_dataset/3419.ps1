














function Test-CreatesNewSimpleResourceGroup
{
    
    $rgname = Get-ResourceGroupName
    $location = Get-ProviderLocation ResourceManagement

    try 
    {
        
        $actual = New-AzureRmResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval"} -Force
        $expected = Get-AzureRmResourceGroup -Name $rgname

        
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
    $location = Get-ProviderLocation ResourceManagement

    try 
    {
        
        Set-AzureRmResourceGroup -Name $rgname -Tags @{testtag = "testval"} -ErrorAction SilentlyContinue
        Assert-True { $Error[0] -like "*Provided resource group does not exist." }
        $Error.Clear()
        
        $new = New-AzureRmResourceGroup -Name $rgname -Location $location
            
        $actual = Set-AzureRmResourceGroup -Name $rgname -Tags @{ testtag = "testval" } 
        $expected = Get-AzureRmResourceGroup -Name $rgname

        
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
    $rgname2 = Get-ResourceGroupName + "Second"
    $location = Get-ProviderLocation ResourceManagement

    
    New-AzureRmResourceGroup -Name $rgname1 -Location $location
    New-AzureRmResourceGroup -Name $rgname2 -Location $location

    Get-AzureRmResourceGroup | where {$_.ResourceGroupName -eq $rgname1 -or $_.ResourceGroupName -eq $rgname2} | Remove-AzureRmResourceGroup -Force

    
    Get-AzureRmResourceGroup -Name $rgname1 -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
 
    Get-AzureRmResourceGroup -Name $rgname2 -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
}


function Test-GetNonExistingResourceGroup
{
    
    $rgname = Get-ResourceGroupName + "abra-kadabra"

    Get-AzureRmResourceGroup -Name $rgname -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
}


function Test-NewResourceGroupInNonExistingLocation
{
    
    $rgname = Get-ResourceGroupName

    Assert-Throws { New-AzureRmResourceGroup -Name $rgname -Location 'non-existing' }
}


function Test-RemoveNonExistingResourceGroup
{
    
    $rgname = Get-ResourceGroupName

    Remove-AzureRmResourceGroup -Name $rgname -Force -ErrorAction SilentlyContinue
    Assert-True { $Error[0] -like "*Provided resource group does not exist." }
    $Error.Clear()
}


function Test-AzureTagsEndToEnd
{
    
    $tag1 = "tagNameOne"
    $tag2 = "tagNameTwo"

    $tagInitial = Get-AzureRmTag

    
    New-AzureRmTag $tag1

    $tag = Get-AzureRmTag $tag1
    Assert-AreEqual $tag1 $tag.Name

    
    New-AzureRmTag $tag1 value1
    New-AzureRmTag $tag1 value1
    New-AzureRmTag $tag1 value2

    $tags = Get-AzureRmTag $tag1
    Assert-AreEqual 2 $tags.Values.Count

    
    New-AzureRmTag $tag2 value1
    New-AzureRmTag $tag2 value2
    New-AzureRmTag $tag2 value3

    $tags = Get-AzureRmTag $tag2
    Assert-AreEqual 3 $tags.Values.Count

    
    $tag = Remove-AzureRmTag $tag1

    
    $tag = Remove-AzureRmTag $tag2 value1

    
    Assert-Throws { Get-AzureRmTag "non-existing" }
}


function Test-NewDeploymentAndProviderRegistration
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $location = Get-ProviderLocation ResourceManagement
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

        
        $deployment = New-AzureRmResourceGroup -Name $rgname -Location $location -GalleryTemplateIdentity $template -cacheName $rname -cacheLocation $location

        
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
        
        New-AzureRmResourceGroup -Name $rgName -Location "East US"
        $deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $rgName -Name $deploymentName -TemplateUri $templateUri
        Assert-True { Remove-AzureRmResourceGroupDeployment -ResourceGroupName $deployment.ResourceGroupName -Name $deployment.DeploymentName }
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
    $location = Get-ProviderLocation ResourceManagement
	$originalResorcrGroups = Find-AzureRmResourceGroup
	$originalCount = @($originalResorcrGroups).Count 

    try
    {
        
        $actual = New-AzureRmResourceGroup -Name $rgname -Location $location -Tag @{ testtag = "testval" }
        $actual2 = New-AzureRmResourceGroup -Name $rgname2 -Location $location -Tag @{ testtag = "testval2" }

        $expected1 = Get-AzureRmResourceGroup -Name $rgname
        
        Assert-AreEqual $expected1.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected1.Tags["testtag"] $actual.Tags["testtag"]

		$expected2 = Get-AzureRmResourceGroup -Name $rgname2
        
        Assert-AreEqual $expected2.ResourceGroupName $actual2.ResourceGroupName
        Assert-AreEqual $expected2.Tags["testtag"] $actual2.Tags["testtag"]

		$expected3 = Find-AzureRmResourceGroup
		$expectedCount = $originalCount + 2
		
		Assert-AreEqual @($expected3).Count $expectedCount

		$expected4 = Find-AzureRmResourceGroup -Tag @{ testtag = $null}
        
        Assert-AreEqual @($expected4).Count 2

		$expected5 = Find-AzureRmResourceGroup -Tag @{ testtag = "testval" }
        
        Assert-AreEqual @($expected5).Count 1

		$expected6 = Find-AzureRmResourceGroup -Tag @{ testtag2 = $null }
        
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
    $output = $(Get-AzureRmResourceGroup -Name "InvalidNonExistRocks" -Debug) 2>&1 5>&1 | Out-String
    $ErrorActionPreference="Stop"
    Assert-True { $output -Like "*============================ HTTP RESPONSE ============================*" }
}


function Test-ExportResourceGroup
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"
	$resourceType = "Providers.Test/statefulResources"

	
	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
                
		$r = New-AzureRmResource -Name $rname -Location "centralus" -Tags @{ testtag = "testval"} -ResourceGroupName $rgname -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -SkuObject @{ Name = "A0" } -ApiVersion $apiversion -Force
		Assert-AreEqual $r.ResourceGroupName $rgname

		$exportOutput = Export-AzureRmResourceGroup -ResourceGroupName $rgname -Force
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
    $location = "West US"

    try
    {
        $ErrorActionPreference = "SilentlyContinue"
        $Error.Clear()
        
        $actual = New-AzureRmResourceGroup $rgname $location
        $expected = Get-AzureRmResourceGroup $rgname

        
        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName

        
        Remove-AzureRmResourceGroup $rgname -Force
    }
    catch
    {
        Assert-True { $Error[0].Contains("Provided resource group does not exist.") }
    }
}