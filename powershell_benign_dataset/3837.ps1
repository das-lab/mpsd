














function TopicTests {
    
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $topicName2 = Get-TopicName
    $topicName3 = Get-TopicName
    $topicName4 = Get-TopicName
    $resourceGroupName = Get-ResourceGroupName
    $secondResourceGroup = Get-ResourceGroupName
    $subscriptionId = Get-SubscriptionId

    New-ResourceGroup $resourceGroupName $location

    New-ResourceGroup $secondResourceGroup $location

    try
    {
        Write-Debug "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        Write-Debug "Topic: $topicName"
        $result = New-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created topic within the resource group"
        $createdTopic = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName
        Assert-True {$createdTopic.Count -eq 1}
        Assert-True {$createdTopic.TopicName -eq $topicName} "Topic created earlier is not found."

        Write-Debug "Creating a second EventGrid topic: $topicName2 in resource group $secondResourceGroup"
        $result = New-AzEventGridTopic -ResourceGroup $secondResourceGroup -Name $topicName2 -Location $location -Tag @{ Dept = "IT"; Environment = "Test" }
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a third EventGrid topic: $topicName3 in resource group $secondResourceGroup"
        $result = New-AzEventGridTopic -ResourceGroup $secondResourceGroup -Name $topicName3 -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created topic $topicName3 within the resource group using the resourceId"
        $createdTopic = Get-AzEventGridTopic -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$secondResourceGroup/providers/Microsoft.EventGrid/topics/$topicName3"
        Assert-True {$createdTopic.Count -eq 1}
        Assert-True {$createdTopic.TopicName -eq $topicName3} "Topic created earlier is not found."

        Write-Debug "Listing all the topics created in the resourceGroup $secondResourceGroup"
        $allCreatedTopics = Get-AzEventGridTopic -ResourceGroup $secondResourceGroup
        Assert-True {$allCreatedTopics.PsTopicsList.Count -ge 0 } "Topic created earlier is not found in the list"

        Write-Debug "Listing the topics created in the resourceGroup $secondResourceGroup using Top option"
        $allCreatedTopics = Get-AzEventGridTopic -ResourceGroup $secondResourceGroup -Top 1
        
        Assert-True {$allCreatedTopics.NextLink -ne $null } "NextLink should not be null as more topics should be available under resource group.."

        Write-Debug "Listing the next topics created in the resourceGroup $secondResourceGroup using NextLink"
        $allCreatedTopics = Get-AzEventGridTopic -NextLink $allCreatedTopics.NextLink
        
        

        Write-Debug "Getting the first 1 topic created in the subscription using Top options"
        $allCreatedTopics = Get-AzEventGridTopic -Top 1
        Assert-True {$allCreatedTopics.PsTopicsList.Count -ge 0} "Topics created earlier are not found."
        Assert-True {$allCreatedTopics.NextLink -ne $null } "NextLink should not be null as more topics should be available under the azure subscription."

        Write-Debug "Listing the next topics created in the subscription using NextLink"
        $allCreatedTopics = Get-AzEventGridTopic -NextLink $allCreatedTopics.NextLink
        
        

        Write-Debug "Getting all the topics created in the subscription"
        $allCreatedTopics = Get-AzEventGridTopic
        Assert-True {$allCreatedTopics.PsTopicsList.Count -ge 0} "Topics created earlier are not found."

        Write-Debug "Deleting topic: $topicName"
        Remove-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName

        Write-Debug "Creating a new EventGrid Topic: $topicName4 in resource group $resourceGroupName"
        $result = New-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName4 -Location $location

        Write-Debug "Deleting topic: $topicName4 using the InputObject parameter set"
        Get-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName4 | Remove-AzEventGridTopic

        Write-Debug "Deleting topic: $topicName2 using the ResourceID parameter set"
        
        
        Remove-AzEventGridTopic -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$secondResourceGroup/providers/Microsoft.EventGrid/topics/$topicName2"

        Remove-AzEventGridTopic -ResourceGroup $secondResourceGroup -Name $topicName3

        
        $returnedTopics1 = Get-AzEventGridTopic -ResourceGroup $resourceGroupName
        Assert-True {$returnedTopics1.PsTopicsList.Count -eq 0}

        $returnedTopics2 = Get-AzEventGridTopic -ResourceGroup $secondResourceGroup
        Assert-True {$returnedTopics2.PsTopicsList.Count -eq 0}
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
        Remove-ResourceGroup $secondResourceGroup
    }
}


function TopicSetTests {
    
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $resourceGroupName = Get-ResourceGroupName
    $subscriptionId = Get-SubscriptionId

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        Write-Debug "Topic: $topicName"
        $result = New-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Calling Set-AzEventGridTopic on the created topic $topicName"
        $tags1 = @{test1 = "testval1"; test2 = "testval2" };
        $replacedTopic1 = Set-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName -Tag $tags1
        Assert-True {$replacedTopic1.Count -eq 1}
        Assert-True {$replacedTopic1.TopicName -eq $topicName} "Topic updated earlier is not found."

        Write-Debug "Calling Set-AzEventGridTopic on the created topic $topicName"
        $tags2 = @{test1 = "testval1"; test2 = "testval2" };
        $replacedTopic2 = Set-AzEventGridTopic -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/topics/$topicName" -Tag $tags2
        Assert-True {$replacedTopic2.Count -eq 1}
        Assert-True {$replacedTopic2.TopicName -eq $topicName} "Topic updated earlier is not found."
        $returned_tags2 = $replacedTopic2.Tags;
        Assert-AreEqual 2 $returned_tags2.Count;
        Assert-AreEqual $tags2["test1"] $returned_tags2["test1"];
        Assert-AreEqual $tags2["test2"] $returned_tags2["test2"];

        Write-Debug "Calling Set-AzEventGridTopic on the created topic $topicName"
        $tags3 = @{test1 = "testval10"; test2 = "testval20" };
        $replacedTopic3 = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName | Set-AzEventGridTopic -Tag $tags3
        Assert-True {$replacedTopic3.Count -eq 1}
        Assert-True {$replacedTopic3.TopicName -eq $topicName} "Topic updated earlier is not found."
        $returned_tags3 = $replacedTopic3.Tags;
        Assert-AreEqual 2 $returned_tags3.Count;
        Assert-AreEqual $tags3["test1"] $returned_tags3["test1"];
        Assert-AreEqual $tags3["test2"] $returned_tags3["test2"];

        Write-Debug "Deleting topic: $topicName"
        Remove-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function TopicGetKeyTests {
    
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $resourceGroupName = Get-ResourceGroupName
    $subscriptionId = Get-SubscriptionId

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        
        $sharedAccessKeys = Get-AzEventGridTopicKey -ResourceGroup $resourceGroupName -Name $topicName
        Assert-True {$sharedAccessKeys.Count -eq 1}

        
        $sharedAccessKeys = Get-AzEventGridTopicKey -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/topics/$topicName"
        Assert-True {$sharedAccessKeys.Count -eq 1}

        
        $sharedAccessKeys = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName | Get-AzEventGridTopicKey
        Assert-True {$sharedAccessKeys.Count -eq 1}

        Write-Debug "Deleting topic: $topicName"
        Remove-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function TopicNewKeyTests {
    
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $resourceGroupName = Get-ResourceGroupName
    $subscriptionId = Get-SubscriptionId

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        
        $sharedAccessKeys = New-AzEventGridTopicKey -ResourceGroup $resourceGroupName -TopicName $topicName -KeyName "key1"
        Assert-True {$sharedAccessKeys.Count -eq 1}

        
        $sharedAccessKeys = New-AzEventGridTopicKey -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/topics/$topicName" -KeyName "key2"
        Assert-True {$sharedAccessKeys.Count -eq 1}

        
        $sharedAccessKeys = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName | New-AzEventGridTopicKey -KeyName "key2"
        Assert-True {$sharedAccessKeys.Count -eq 1}

        Write-Debug "Deleting topic: $topicName"
        Remove-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}
