














function Test-MoveAzureResource
{
    $sourceResourceGroupName = "testResourceGroup321"
    $destinationResourceGroupName = "testResourceGroup432"
    $testResourceName1 = "testResource123"
    $testResourceName2 = "testResource234"
    $location = "West US"
    $apiversion = "2014-04-01"
    $providerNamespace = "Providers.Test"
    $resourceType = $providerNamespace + "/statefulResources"

    Register-AzureRmResourceProvider -ProviderNamespace $providerNamespace
    New-AzureRmResourceGroup -Name $sourceResourceGroupName -Location $location -Force
    New-AzureRmResourceGroup -Name $destinationResourceGroupName -Location $location -Force
    
    $resource1 = New-AzureRmResource -Name $testResourceName1 -Location $location -Tags @{testtag = "testval"} -ResourceGroupName $sourceResourceGroupName -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion -Force
    
    $resource2 = New-AzureRmResource -Name $testResourceName2 -Location $location -Tags @{testtag = "testval"} -ResourceGroupName $sourceResourceGroupName -ResourceType $resourceType -PropertyObject @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"} -ApiVersion $apiversion -Force

    Find-AzureRmResource -ResourceGroupName  $sourceResourceGroupName | Move-AzureRmResource -DestinationResourceGroupName $destinationResourceGroupName -Force

    $endTime = [DateTime]::UtcNow.AddMinutes(10)

    while ([DateTime]::UtcNow -lt $endTime -and (@(Find-AzureRmResource -ResourceGroupName $sourceResourceGroupName).Length -gt 0))
    {
		Start-Sleep -m 1000
    }

    Assert-True { @(Find-AzureRmResource -ResourceGroupName $sourceResourceGroupName).Length -eq 0 }
    Assert-True { @(Find-AzureRmResource -ResourceGroupName $destinationResourceGroupName).Length -eq 2 }

    Remove-AzureRmResourceGroup -Name $sourceResourceGroupName -Force
    Remove-AzureRmResourceGroup -Name $destinationResourceGroupName -Force
}
