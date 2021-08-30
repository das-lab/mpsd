














function Test-MoveAzureResource
{
    $sourceResourceGroupName = "testResourceGroup1"
    $destinationResourceGroupName = "testResourceGroup2"
    $testResourceName1 = "testResource1"
    $testResourceName2 = "testResource2"
    $location = "West US"
    $apiversion = "2014-04-01"
    $providerNamespace = "Providers.Test"
    $resourceType = $providerNamespace + "/statefulResources"

    Register-AzResourceProvider -ProviderNamespace $providerNamespace -Force
    New-AzResourceGroup -Name $sourceResourceGroupName -Location $location -Force
    New-AzResourceGroup -Name $destinationResourceGroupName -Location $location -Force
    
    $resource1 = New-AzResource -Name $testResourceName1 -Location $location -Tags @{testtag = "testval"} -ResourceGroupName $sourceResourceGroupName -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion -Force
    
    $resource2 = New-AzResource -Name $testResourceName2 -Location $location -Tags @{testtag = "testval"} -ResourceGroupName $sourceResourceGroupName -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion -Force

    Get-AzResource -ResourceGroupName $sourceResourceGroupName | Move-AzResource -DestinationResourceGroupName $destinationResourceGroupName -Force

    $endTime = [DateTime]::UtcNow.AddMinutes(10)

    while ([DateTime]::UtcNow -lt $endTime -and (@(Get-AzResource -ResourceGroupName $sourceResourceGroupName).Length -gt 0))
    {
		[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(1000)
    }

    Assert-True { @(Get-AzResource -ResourceGroupName $sourceResourceGroupName).Length -eq 0 }
    Assert-True { @(Get-AzResource -ResourceGroupName $destinationResourceGroupName).Length -eq 2 }
}
