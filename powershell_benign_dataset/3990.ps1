















function NetworkRuleSetTests {
    

    $location = Get-Location
    $resourceGroupName = getAssetName "RSG"
    $namespaceName = getAssetName "ServiceBus-Namespace-"
    $namespaceName2 = getAssetName "ServiceBus-Namespace2-"	
	
    
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force	 
	
    

    $checkNameResult = Test-AzServiceBusName -Namespace $namespaceName 
    Assert-True { $checkNameResult.NameAvailable }	
     
    Write-Debug " Create new ServiceBus namespace"
    Write-Debug "NamespaceName : $namespaceName" 
    $result = New-AzServiceBusNamespace -ResourceGroup $resourceGroupName -Name $namespaceName -Location $location -SkuName "Premium"
	
    
    Assert-AreEqual $result.ProvisioningState "Succeeded"

    Write-Debug "Get the created namespace within the resource group"
    $createdNamespace = Get-AzServiceBusNamespace -ResourceGroup $resourceGroupName -Name $namespaceName

    Assert-AreEqual $createdNamespace.Name $namespaceName "Namespace created earlier is not found."	  

    Write-Debug " Create new ServiceBus namespace"
    Write-Debug "NamespaceName : $namespaceName2" 
    $resultNS = New-AzServiceBusNamespace -ResourceGroup $resourceGroupName -Name $namespaceName2 -Location $location -SkuName "Premium"
	
    
    Assert-AreEqual $resultNS.ProvisioningState "Succeeded"

    Write-Debug "Get the created namespace within the resource group"
    $createdNamespace2 = Get-AzServiceBusNamespace -ResourceGroup $resourceGroupName -Name $namespaceName2
    Assert-AreEqual $createdNamespace2.Name $namespaceName2 "Namespace created earlier is not found."	 
    
    Write-Debug "Add a new IPRule to the default NetwrokRuleSet"
    $result = Add-AzServiceBusIPRule -ResourceGroup $resourceGroupName -Name $namespaceName -IpMask "1.1.1.1" -Action "Allow"

    Write-Debug "Add a new IPRule to the default NetwrokRuleSet"
    $result = Add-AzServiceBusIPRule -ResourceGroup $resourceGroupName -Name $namespaceName -IpMask "2.2.2.2" -Action "Allow"

    Write-Debug "Add a new IPRule to the default NetwrokRuleSet"
    $result = Add-AzServiceBusIPRule -ResourceGroup $resourceGroupName -Name $namespaceName -IpMask "3.3.3.3"

    Write-Debug "Add a new VirtualNetworkRule to the default NetwrokRuleSet"
    $result = Add-AzServiceBusVirtualNetworkRule -ResourceGroup $resourceGroupName -Name $namespaceName -SubnetId "/subscriptions/854d368f-1828-428f-8f3c-f2affa9b2f7d/resourcegroups/v-ajnavtest/providers/Microsoft.Network/virtualNetworks/sbehvnettest1/subnets/default"
    $result = Add-AzServiceBusVirtualNetworkRule -ResourceGroup $resourceGroupName -Name $namespaceName -SubnetId "/subscriptions/854d368f-1828-428f-8f3c-f2affa9b2f7d/resourcegroups/v-ajnavtest/providers/Microsoft.Network/virtualNetworks/sbehvnettest1/subnets/sbdefault"
    $result = Add-AzServiceBusVirtualNetworkRule -ResourceGroup $resourceGroupName -Name $namespaceName -SubnetId "/subscriptions/854d368f-1828-428f-8f3c-f2affa9b2f7d/resourcegroups/v-ajnavtest/providers/Microsoft.Network/virtualNetworks/sbehvnettest1/subnets/sbdefault01"

    Write-Debug "Get NetwrokRuleSet"
    $getResult1 = Get-AzServiceBusNetworkRuleSet -ResourceGroup $resourceGroupName -Name $namespaceName
	
    Assert-AreEqual $getResult1.VirtualNetworkRules.Count 3 "VirtualNetworkRules count did not matched"
    Assert-AreEqual $getResult1.IpRules.Count 3 "IPRules count did not matched"

    Write-Debug "Remove a new IPRule to the default NetwrokRuleSet"
    $result = Remove-AzServiceBusIPRule -ResourceGroup $resourceGroupName -Name $namespaceName -IpMask "3.3.3.3"	

    $getResult = Get-AzServiceBusNetworkRuleSet -ResourceGroup $resourceGroupName -Name $namespaceName

    Assert-AreEqual $getResult.IpRules.Count 2 "IPRules count did not matched after deleting one IPRule"
    Assert-AreEqual $getResult.VirtualNetworkRules.Count 3 "VirtualNetworkRules count did not matched"

    
    $setResult = Set-AzServiceBusNetworkRuleSet -ResourceGroup $resourceGroupName -Name $namespaceName2 -InputObject $getResult1
    Assert-AreEqual $setResult.VirtualNetworkRules.Count 3 "Set -VirtualNetworkRules count did not matched"
    Assert-AreEqual $setResult.IpRules.Count 3 "Set - IPRules count did not matched"

    
    $setResult1 = Set-AzServiceBusNetworkRuleSet -ResourceGroup $resourceGroupName -Name $namespaceName2 -ResourceId $getResult.Id
    Assert-AreEqual $setResult1.IpRules.Count 2 "Set1 - IPRules count did not matched after deleting one IPRule"
    Assert-AreEqual $setResult1.VirtualNetworkRules.Count 3 "Set1 - VirtualNetworkRules count did not matched"

    Write-Debug "Add a new VirtualNetworkRule to the default NetwrokRuleSet"
    $result = Remove-AzServiceBusVirtualNetworkRule -ResourceGroup $resourceGroupName -Name $namespaceName -SubnetId "/subscriptions/854d368f-1828-428f-8f3c-f2affa9b2f7d/resourcegroups/v-ajnavtest/providers/Microsoft.Network/virtualNetworks/sbehvnettest1/subnets/default"
	
    Write-Debug "Delete NetwrokRuleSet"
    $result = Remove-AzServiceBusNetworkRuleSet -ResourceGroup $resourceGroupName -Name $namespaceName   

    Write-Debug " Delete namespaces"    
    Remove-AzServiceBusNamespace -ResourceGroup $resourceGroupName -Name $namespaceName

    Write-Debug " Delete resourcegroup"
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}