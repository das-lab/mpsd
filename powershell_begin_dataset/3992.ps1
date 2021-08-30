














function ServiceBusTopicTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace-"
    $nameTopic = getAssetName "Topic-"
 
    Write-Debug "Create resource group"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
    Write-Debug "ResourceGroup name : $resourceGroupName" 

    
    Write-Debug " Create new Topic namespace"
    Write-Debug "NamespaceName : $namespaceName" 
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName     

    Write-Debug "Get the created namespace within the resource group"
    $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
    
    Assert-AreEqual $createdNamespace.Name $namespaceName "Namespace created earlier is not found."
	
    $test = Test-AzServiceBusNameAvailability -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameTopic -Topic
    Assert-True { $test }

    Write-Debug "Create Topic"
    $result = New-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameTopic -EnablePartitioning $TRUE
    Assert-AreEqual $result.Name $nameTopic "In CreateTopic response Name not found"

    $test = Test-AzServiceBusNameAvailability -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameTopic -Topic
    Assert-False { $test }

    $resultGetTopic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $result.Name
    Assert-AreEqual $resultGetTopic.Name $result.Name "In 'Get-AzServiceBusTopic' response, Topic Name not found"

    $resultGetTopic.EnableExpress = $TRUE
    $resltSetTopic = Set-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $resultGetTopic.Name -InputObject $resultGetTopic
    Assert-AreEqual $resltSetTopic.Name $resultGetTopic.Name "In GetTopic response, TopicName not found"

    
    $ResulListTopic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName
    Assert-True { $ResulListTopic.Count -gt 0 } "no Topics were found in ListTopic"
		
    
    
    Write-Debug " Delete the Topic"
	
    Remove-AzServiceBusTopic -ResourceId $resltSetTopic.Id

    Write-Debug " Delete namespaces"
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}



function ServiceBusTopicAuthTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace-"
    $TopicName = getAssetName "Topic-"
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
    Assert-AreEqual $result.Name $namespaceName "New-AzServiceBusNamespace: Created Namespace not found"

    
    Write-Debug " Get the created namespace within the resource group"
    $getNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
 
    Assert-AreEqual $getNamespace.Name $namespaceName "Get-AzServiceBusNamespace: Namespace created earlier is not found."

    
    Write-Debug " Create new Topic "    
    $msgRetentionInDays = 3
    $partionCount = 2
    $result_Topic = New-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $TopicName -EnablePartitioning $TRUE
    Assert-AreEqual $result_Topic.Name $TopicName "New-AzServiceBusTopic: Created Namespace not found"
		
    Write-Debug "Get the created Topic"
    $getTopic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $result_Topic.Name

    
    Assert-AreEqual $getTopic.Name $TopicName "Get-AzServiceBusTopic: Created Namespace not found"

    
    Write-Debug "Create a Topic Authorization Rule"
    $result = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -Rights @("Listen", "Send")

    
    Assert-AreEqual $result.Name $authRuleName "New-AzServiceBusAuthorizationRule: Created Authorizationrule not found"
    Assert-AreEqual 2 $result.Rights.Count "New-AzServiceBusAuthorizationRule: Rights count dont match"
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }    
	    
    $resultListen = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleNameListen -Rights @("Listen")
    Assert-AreEqual $authRuleNameListen $resultListen.Name
    Assert-AreEqual 1 $resultListen.Rights.Count
    Assert-True { $resultListen.Rights -Contains "Listen" }

    $resultSend = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleNameSend -Rights @("Send")
    Assert-AreEqual $authRuleNameSend $resultSend.Name
    Assert-AreEqual 1 $resultSend.Rights.Count
    Assert-True { $resultSend.Rights -Contains "Send" }

    $resultAll3 = New-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleNameAll -Rights @("Listen", "Send", "Manage")
    Assert-AreEqual $authRuleNameAll $resultAll3.Name
    Assert-AreEqual 3 $resultAll3.Rights.Count
    Assert-True { $resultAll3.Rights -Contains "Send" }
    Assert-True { $resultAll3.Rights -Contains "Listen" }
    Assert-True { $resultAll3.Rights -Contains "Manage" }

    
    Write-Debug "Get created authorizationRule"
    $createdAuthRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName
	
    
    Assert-AreEqual $createdAuthRule.Name $authRuleName "Get-AzServiceBusAuthorizationRule: Created Authorizationrule not found"
    Assert-AreEqual 2 $createdAuthRule.Rights.Count
    Assert-True { $createdAuthRule.Rights -Contains "Listen" }
    Assert-True { $createdAuthRule.Rights -Contains "Send" }

	
    
    Write-Debug "Update Topic AuthorizationRule"
    $createdAuthRule.Rights.Add("Manage")
    $updatedAuthRule = Set-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -InputObject $createdAuthRule
    
    
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	   
    
    $updatedAuthRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName
    
    
    Assert-AreEqual $authRuleName $updatedAuthRule.Name
    Assert-AreEqual 3 $updatedAuthRule.Rights.Count
    Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
    Assert-True { $updatedAuthRule.Rights -Contains "Send" }
    Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	
    
    Write-Debug "Get Topic authorizationRules connectionStrings"
    $namespaceListKeys = Get-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName

    Assert-True { $namespaceListKeys.PrimaryConnectionString -like "*$($updatedAuthRule.PrimaryKey)*" }
    Assert-True { $namespaceListKeys.SecondaryConnectionString -like "*$($updatedAuthRule.SecondaryKey)*" }
	
    
    $policyKey = "PrimaryKey"

    $StartTime = Get-Date
    $EndTime = $StartTime.AddHours(2.0)
    $SasToken = New-AzServiceBusAuthorizationRuleSASToken -ResourceId $updatedAuthRule.Id  -KeyType Primary -ExpiryTime $EndTime -StartTime $StartTime	

    $namespaceRegenerateKeysDefault = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -RegenerateKey $policyKey
    Assert-True { $namespaceRegenerateKeysDefault.PrimaryKey -ne $namespaceListKeys.PrimaryKey }

    $namespaceRegenerateKeys = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -RegenerateKey $policyKey -KeyValue $namespaceListKeys.PrimaryKey
    Assert-AreEqual $namespaceRegenerateKeys.PrimaryKey $namespaceListKeys.PrimaryKey

    $policyKey1 = "SecondaryKey"

    $namespaceRegenerateKeys1 = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -RegenerateKey $policyKey1 -KeyValue $namespaceListKeys.PrimaryKey
    Assert-AreEqual $namespaceRegenerateKeys1.SecondaryKey $namespaceListKeys.PrimaryKey

    $namespaceRegenerateKeys1 = New-AzServiceBusKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -RegenerateKey $policyKey1
    Assert-True { $namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.PrimaryKey }
    Assert-True { $namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.SecondaryKey }

    
    Write-Debug "Delete the created Topic AuthorizationRule"
    $result = Remove-AzServiceBusAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $TopicName -Name $authRuleName -Force
    
    
    
    Write-Debug " Delete the Topic"

    Write-Debug "Get the created Topics"
    $createdTopics = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName 
    for ($i = 0; $i -lt $createdTopics.Count; $i++) {
        
        $delete1 = Remove-AzServiceBusTopic -InputObject $createdTopics[$i]	
    }

    Write-Debug "Delete NameSpace"
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName	

    Write-Debug " Delete resourcegroup"
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}

