














function ServiceBusPaginationTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace1-"
    $nameQueue = getAssetName "Queue-"
    $nameTopic = getAssetName "Topic-"
    $subName = getAssetName "Subscription-"
    $ruleName = getAssetName "Rule-"
    $ruleName1 = getAssetName "Rule-"
    $count = 0
	 
    Write-Debug "Create resource group"
    Write-Debug "ResourceGroup name : $resourceGroupName"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
        
    Write-Debug " Create new Topic namespace"
    Write-Debug "NamespaceName : $namespaceName" 
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName
    
    Try {
        Write-Debug "Get the created namespace within the resource group"
        $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

        Assert-AreEqual $createdNamespace.Name $namespaceName

        Assert-AreEqual $createdNamespace.Name $namespaceName "Namespace created earlier is not found."

        
        while ($count -lt 50) {
            $queueNameNew = $nameQueue + "_" + $count
            New-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $queueNameNew
            $count = $count + 1
        }
	
        $get30Queue = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -MaxCount 30
        Assert-AreEqual 30 $get30Queue.Count "Get Queue with MaxCount 30 not returned total 30"

        
        $count = 0
        $topicNameNew = $nameTopic + "_" + $count
        while ($count -lt 50) {
            $topicNameNew = $nameTopic + "_" + $count
            New-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $topicNameNew -EnablePartitioning $TRUE
            $count = $count + 1
        }
	
        $get30Topic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -MaxCount 30	
        Assert-AreEqual 30 $get30Topic.Count "Get Topic with MaxCount 30 not returned total 30"

        
        $count = 0
        $subscriptionNameNew = $subName + "_" + $count
        while ($count -lt 50) {
            $subscriptionNameNew = $subName + "_" + $count
            New-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -Name $subscriptionNameNew
            $count = $count + 1
        }
	
        $get30Sub = Get-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -MaxCount 30	
        Assert-AreEqual 30 $get30Sub.Count "Get Subscription with MaxCount 30 not returned total 30"	

        
        $count = 0
        $ruleNameNew = $ruleName + "_" + $count
        while ($count -lt 50) {
            $ruleNameNew = $ruleName + "_" + $count
            New-AzServiceBusRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -Subscription $subscriptionNameNew -Name $ruleNameNew -SqlExpression "myproperty='test'"
            $count = $count + 1
        }
	
        $get30Rule = Get-AzServiceBusRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -Subscription $subscriptionNameNew -MaxCount 25	
        Assert-AreEqual 25 $get30Rule.Count "Get Rules with MaxCount 30 not returned total 30"
    }
    Finally {
        
        

        Write-Debug "Delete NameSpace"
        Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

        Write-Debug " Delete resourcegroup"
        Remove-AzResourceGroup -Name $resourceGroupName -Force
    }

	
}