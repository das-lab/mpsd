














function Get-SubscriptionID
{
    $context = Get-AzContext
    return $context.Subscription.SubscriptionId
}


function Get-ResourceGroupName
{
    return "RGName-" + (getAssetName)
}


function New-ResourceGroup($ResourceGroupName, $Location)
{
    Write-Debug "Creating resource group name $ResourceGroupName in location $Location"
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
}


function Remove-ResourceGroup($ResourceGroupName)
{
    Write-Debug "Deleting resource group name $ResourceGroupName"
    Remove-AzResourceGroup -Name $ResourceGroupName -Force
}


function Get-EventSubscriptionName
{
    return "EventSubscription-" + (getAssetName)
}


function Get-EventSubscriptionWebhookEndpoint
{
    return "https://devexpfuncappdestination.azurewebsites.net/runtime/webhooks/EventGrid?functionName=EventGridTrigger1&code=<HIDDEN>"
}


function Get-EventSubscriptionWebhookBaseEndpoint
{
    return "https://devexpfuncappdestination.azurewebsites.net/runtime/webhooks/EventGrid"
}


function Get-LocationForEventGrid
{
    return "westcentralus"
}


function Get-EventHubNamespaceName
{
    return "PSTestEH-" + (getAssetName)
}


function Get-HybridConnNameSpaceName
{
    return "hcnamespace-" + (getAssetName)
}


function Get-HybridConnName
{
    return "hcname-" + (getAssetName)
}


function Get-HybridConnectionResourceId($ResourceGroupName, $NamespaceName, $HybridConnectionName)
{
    $subId = Get-SubscriptionID
    return "/subscriptions/$subId/resourceGroups/$ResourceGroupName/providers/Microsoft.Relay/namespaces/$NamespaceName/hybridConnections/$HybridConnectionName"
}


function New-HybridConnection($ResourceGroupName, $NamespaceName, $HybridConnectionName, $Location)
{
    Write-Debug "Creating namespace $NamespaceName in resource group $ResourceGroupName and location $Location"
    New-AzRelayNamespace -ResourceGroupName $ResourceGroupName -Name $NamespaceName -Location $Location
    Write-Debug "Creating hybridconnection $HybridConnectionName in Namespace $NamespaceName in resource group $ResourceGroupName and location $Location"
    New-AzRelayHybridConnection -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $HybridConnectionName -RequiresClientAuthorization $True
}


function Remove-HybridConnectionResources($ResourceGroupName, $NamespaceName, $HybridConnectionName)
{
    Write-Debug "Deleting hybridconnection $HybridConnectionName in Namespace $NamespaceName in resource group $ResourceGroupName and location $Location"
    Remove-AzRelayHybridConnection -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $HybridConnectionName
    Write-Debug "Deleting namespace $NamespaceName in resource group $ResourceGroupName and location $Location"
    Remove-AzRelayNamespace -ResourceGroupName $ResourceGroupName -Name $NamespaceName
}


function Get-ServiceBusNameSpaceName
{
    return "sbnamespace-" + (getAssetName)
}


function Get-ServiceBusName
{
    return "sbname-" + (getAssetName)
}


function Get-ServiceBusQueueResourceId($ResourceGroupName, $NamespaceName, $QueueName)
{
    $subId = Get-SubscriptionID
    return "/subscriptions/$subId/resourceGroups/$ResourceGroupName/providers/Microsoft.ServiceBus/namespaces/$NamespaceName/queues/$QueueName"
}


function New-ServiceBusQueue($ResourceGroupName, $NamespaceName, $QueueName, $Location)
{
    Write-Debug "Creating ServiceBus namespace $NamespaceName in resource group $ResourceGroupName and location $Location"
    New-AzServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $NamespaceName -Location $Location
    $DefaultMessageTimeToLiveTimeSpan = New-TimeSpan -Minute 1
    Write-Debug "Creating ServiceBus queue $QueueName in Namespace $NamespaceName in resource group $ResourceGroupName and location $Location"
    New-AzServiceBusQueue -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $QueueName -RequiresSession $False -EnablePartitioning $True -DefaultMessageTimeToLive $DefaultMessageTimeToLiveTimeSpan
}


function Remove-ServiceBusResources($ResourceGroupName, $NamespaceName, $QueueName)
{
    Write-Debug "Deleting ServiceBus queue $QueueName in Namespace $NamespaceName in resource group $ResourceGroupName"
    Remove-AzServiceBusQueue -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $QueueName
    Write-Debug "Deleting ServiceBus namespace $NamespaceName in resource group $ResourceGroupName"
    Remove-AzServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $NamespaceName
}


function Get-StorageAccountName
{
    
    return "storagename" + (getAssetName)
}


function Get-StorageQueueName
{
    return "storagequeuename" + (getAssetName)
}


function Get-StorageDestinationResourceId($ResourceGroupName, $StorageAccountName, $QueueName)
{
    $subId = Get-SubscriptionID
    return "/subscriptions/$subId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName/queueServices/default/queues/$QueueName"
}


function New-StorageQueue($ResourceGroupName, $StorageAccountName, $QueueName, $Location)
{
    Write-Debug "Creating Storage Account $StorageAccountName in resource group $ResourceGroupName and location $Location"
    $StorageAccount = New-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -SkuName Standard_LRS -Location $Location -Kind StorageV2 -AccessTier Hot
    $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
    $cxt = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue
    
    
    
}


function Remove-StorageResources($ResourceGroupName, $StorageAccountName, $QueueName)
{
    Write-Debug "Deleting Storage queue $QueueName in Storage Account $StorageAccountName"
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName
    $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
    $cxt = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue
    
    
    Write-Debug "Deleting storage account $StorageAccount in resource group $ResourceGroupName"
    Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Force
}


function Get-StorageBlobName
{
    return "storageblobname" + (getAssetName)
}


function Get-DeadletterResourceId($ResourceGroupName, $StorageAccountName, $ContainerName)
{
    $subId = Get-SubscriptionID
    return "/subscriptions/$subId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName/blobServices/default/containers/$ContainerName"
}


function New-StorageBlob($ResourceGroupName, $StorageAccountName, $ContainerName, $Location)
{
    Write-Debug "Creating Storage Account $StorageAccountName in resource group $ResourceGroupName and location $Location"
    $storageAccount = New-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -SkuName Standard_LRS -Location $Location
    $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
    $cxt = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKeyValue
    
    
}


function Remove-StorageContainerResources($ResourceGroupName, $StorageAccountName, $ContainerName)
{
    Write-Debug "Deleting Storage blob $ContainerName in Storage Account $StorageAccountName"
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName
    $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
    $cxt = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue
    
    
    Write-Debug "Deleting storage account $StorageAccount in resource group $ResourceGroupName"
    Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Force
}


function Get-TopicName
{
    return "PSTestTopic-" + (getAssetName)
}


function Get-DomainName
{
    return "PSTestDomain-" + (getAssetName)
}


function Get-DomainTopicName
{
    return "PSTestDomainTopic-" + (getAssetName)
}
