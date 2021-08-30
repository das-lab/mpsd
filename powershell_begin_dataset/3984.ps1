















function ServiceBusSubscriptionTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace-"
    $nameTopic = getAssetName "Topic-"
    $subName = getAssetName "Subscription-"

    Write-Debug "Create resource group"    
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
    Write-Debug "ResourceGroup name : $resourceGroupName"   
    
    Write-Debug " Create new Topic namespace"
    Write-Debug "NamespaceName : $namespaceName" 
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName     

    Write-Debug "Get the created namespace within the resource group"
    $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
   		
    Assert-AreEqual $createdNamespace.Name $namespaceName "Namespace created earlier is not found"
    Assert-AreEqual $location.Replace(' ', '') $createdNamespace.Location.Replace(' ', '')

    Write-Debug "Create Topic"	
    $result = New-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $nameTopic -EnablePartitioning $TRUE
    Assert-AreEqual $result.Name $nameTopic "In CreateTopic response Name not found"

    $resultGetTopic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $result.Name
    Assert-AreEqual $resultGetTopic.Name $result.Name "In 'Get-AzServiceBusTopic' response, Topic Name not found"
	
    $resultGetTopic.EnableExpress = $TRUE

    $resltSetTopic = Set-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $resultGetTopic.Name -InputObject $resultGetTopic
    Assert-AreEqual $resltSetTopic.Name $resultGetTopic.Name "In GetTopic response, TopicName not found"
    Assert-True { $resltSetTopic.EnableExpress } "Set-AzServiceBusTopic: "

    
    $ResulListTopic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName
    Assert-True { $ResulListTopic.Count -gt 0 } "no Topics were found in ListTopic"
	
    
    Write-Debug "Create new SB Topic-Subscription"
    Write-Debug "SB Topic-Subscription Name : $subName"
    $resltNewSub = New-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $nameTopic -Name $subName -DeadLetteringOnFilterEvaluationExceptions
    Assert-AreEqual $resltNewSub.Name $subName "Subscription created earlier is not found"

    
    $resultGetSub = Get-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $nameTopic -Name $subName
    Assert-AreEqual $resultGetSub.Name $subName "Get-Subscription: Subscription created earlier is not found"
    Assert-True { $resultGetSub.DeadLetteringOnFilterEvaluationExceptions } "New-subscription: DeadLetteringOnFilterEvaluationExceptions not updated "
	
    
    $resultSetSub = Set-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $resultGetTopic.Name -InputObject $resultGetSub		
    Assert-AreEqual $resultSetSub.Name $resultGetSub.Name "Subscription Updated earlier is not found"

    
    $ResultDeleteTopic = Remove-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $ResulListTopic[0].Name -Name $resultSetSub.Name
		
    
    
    Write-Debug " Delete the Topic"
    for ($i = 0; $i -lt $ResulListTopic.Count; $i++) {
        $delete1 = Remove-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $ResulListTopic[$i].Name		
    }

    Write-Debug "Delete NameSpace"
    Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName
	
    Write-Debug " Delete resourcegroup"
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}