















function EventHubsTests
{
	
	$location = Get-Location
	$resourceGroupName = getAssetName "RSG"
	$namespaceName = getAssetName "Eventhub-Namespace-"
	$eventHubName = getAssetName "EventHub-"
	$eventHubName2 = getAssetName "EventHub-"

	
	Write-Debug "Create resource group"    
	Write-Debug " Resource Group Name : $resourceGroupName"
	New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
	
		
	
	Write-Debug "  Create new eventhub namespace"
	Write-Debug " Namespace name : $namespaceName"
	$result = New-AzEventHubNamespace -ResourceGroup $resourceGroupName -Name $namespaceName -Location $location

	
	Assert-AreEqual $result.Name $namespaceName	"New Namespace: Namespace created earlier is not found."

	
	Write-Debug " Get the created namespace within the resource group"
	$createdNamespace = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -Name $namespaceName
	
	Assert-AreEqual $createdNamespace.Name $namespaceName "Get Namespace: Namespace created earlier is not found."
	
	
	Write-Debug " Create new eventHub "	
	$result = New-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $eventHubName
			
	Write-Debug " Get the created Eventhub "
	$createdEventHub = Get-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $result.Name

	
	Assert-AreEqual $createdEventHub.Name $eventHubName "Get Eventhub: EventHub created earlier is not found."	    

	
	Write-Debug " Get all the created EventHub "
	$createdEventHubList = Get-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName

	
	Assert-AreEqual $createdEventHubList.Count 1 "List Eventhub: EventHub created earlier is not found in list"

	$createdEventHub.MessageRetentionInDays = 3
	Set-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $createdEventHub.Name  -InputObject $createdEventHub
	
	
	Write-Debug " Update the first EventHub"
	$createdEventHub.MessageRetentionInDays = 4	
	$createdEventHub.CaptureDescription = New-Object -TypeName Microsoft.Azure.Commands.EventHub.Models.PSCaptureDescriptionAttributes
	$createdEventHub.CaptureDescription.Enabled = $true
	$createdEventHub.CaptureDescription.SkipEmptyArchives = $true
	$createdEventHub.CaptureDescription.IntervalInSeconds  = 120
	$createdEventHub.CaptureDescription.Encoding  = "Avro"
	$createdEventHub.CaptureDescription.SizeLimitInBytes = 10485763
	$createdEventHub.CaptureDescription.Destination.Name = "EventHubArchive.AzureBlockBlob"
	$createdEventHub.CaptureDescription.Destination.BlobContainer = "container01"
	$createdEventHub.CaptureDescription.Destination.ArchiveNameFormat = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
	$createdEventHub.CaptureDescription.Destination.StorageAccountResourceId = "/subscriptions/854d368f-1828-428f-8f3c-f2affa9b2f7d/resourcegroups/v-ajnavtest/providers/Microsoft.Storage/storageAccounts/testingsdkeventhub11"
		
	$result = Set-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $createdEventHub.Name  -InputObject $createdEventHub
	
	
	Assert-AreEqual $result.MessageRetentionInDays $createdEventHub.MessageRetentionInDays
	Assert-AreEqual $result.CaptureDescription.Destination.BlobContainer "container01"
	Assert-True { $result.CaptureDescription.SkipEmptyArchives }

	
	$resultNew = New-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $createdEventHub.Name  -InputObject $result

	
	Assert-AreEqual $resultNew.MessageRetentionInDays $createdEventHub.MessageRetentionInDays
	Assert-AreEqual $resultNew.CaptureDescription.Destination.BlobContainer "container01"
	
	
	
	Write-Debug " Delete the EventHub"
	for ($i = 0; $i -lt $createdEventHubList.Count; $i++)
	{
		$delete1 = Remove-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $createdEventHubList[$i].Name		
	}
	Write-Debug "Delete namespaces"
	Remove-AzEventHubNamespace -ResourceGroup $resourceGroupName -Namespace $namespaceName

	Write-Debug "Delete resourcegroup"
	
}


function EventHubsAuthTests
{
	
	$location =  Get-Location
	$resourceGroupName = getAssetName "RSG"
	$namespaceName = getAssetName "Eventhub-Namespace-"
	$eventHubName = getAssetName "EventHub-"
	$authRuleName = getAssetName "Eventhub-Namespace-AuthorizationRule"
    $authRuleName = getAssetName "authorule-"
	$authRuleNameListen = getAssetName "authorule-"
	$authRuleNameSend = getAssetName "authorule-"
	$authRuleNameAll = getAssetName "authorule-"

	
	Write-Debug " Create resource group"    
	Write-Debug "Resource group name : $resourceGroupName"
	New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
	   
	
	Write-Debug " Create new Eventhub namespace"
	Write-Debug "Namespace name : $namespaceName"
	$result = New-AzEventHubNamespace -ResourceGroup $resourceGroupName -Name $namespaceName -Location $location

	
	Assert-AreEqual $result.Name $namespaceName "New Namespace: Namespace created earlier is not found."

	
	Write-Debug " Get the created namespace within the resource group"
	$createdNamespace = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -Name $namespaceName
	
	
	Assert-AreEqual $createdNamespace.Name $namespaceName "Get Namespace: Namespace created earlier is not found."

	
	Write-Debug " Create new eventHub "    
	$msgRetentionInDays = 3
	$partionCount = 2
	$result_eventHub = New-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $eventHubName -MessageRetentionInDays $msgRetentionInDays -PartitionCount $partionCount
	
	Write-Debug "Get the created eventHub"
	$createdEventHub = Get-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $result_eventHub.Name

	
	Assert-AreEqual $createdEventHub.Name $eventHubName "Get Eventhub: EventHub created earlier is not found."
	Assert-AreEqual $createdEventHub.PartitionCount $partionCount "Get Eventhub: PartionCount dosent match with the creation value"

	
	Write-Debug "Create a EventHub Authorization Rule"
	$result = New-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -Rights @("Listen","Send")

	
	Assert-AreEqual $authRuleName $result.Name
	Assert-AreEqual 2 $result.Rights.Count
	Assert-True { $result.Rights -Contains "Listen" }
	Assert-True { $result.Rights -Contains "Send" }

	$resultListen = New-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleNameListen -Rights @("Listen")
	Assert-AreEqual $authRuleNameListen $resultListen.Name
    Assert-AreEqual 1 $resultListen.Rights.Count
    Assert-True { $resultListen.Rights -Contains "Listen" }

	$resultSend = New-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleNameSend -Rights @("Send")
	Assert-AreEqual $authRuleNameSend $resultSend.Name
    Assert-AreEqual 1 $resultSend.Rights.Count
    Assert-True { $resultSend.Rights -Contains "Send" }

	$resultall3 = New-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleNameAll -Rights @("Listen","Send","Manage")
	Assert-AreEqual $authRuleNameAll $resultall3.Name
    Assert-AreEqual 3 $resultall3.Rights.Count
    Assert-True { $resultall3.Rights -Contains "Send" }
	Assert-True { $resultall3.Rights -Contains "Listen" }
	Assert-True { $resultall3.Rights -Contains "Manage" }

	
	Write-Debug "Get created authorizationRule"
	$createdAuthRule = Get-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName

	
	Assert-AreEqual $authRuleName $createdAuthRule.Name "Get Authorizationrule: Authorizationrule name do not match"
	Assert-AreEqual 2 $createdAuthRule.Rights.Count  "Get Authorizationrule: rights count do not match"
	Assert-True { $createdAuthRule.Rights -Contains "Listen" }
	Assert-True { $createdAuthRule.Rights -Contains "Send" }

	
	Write-Debug "Get All eventHub AuthorizationRule"
	$result = Get-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName
	
	for ($i = 0; $i -lt $result.Count; $i++)
	{
		if ($result[$i].Name -eq $authRuleName)
		{			
			Assert-AreEqual 2 $result[$i].Rights.Count
			Assert-True { $result[$i].Rights -Contains "Listen" }
			Assert-True { $result[$i].Rights -Contains "Send" }         
			break
		}
	}

	Assert-True { $result.Count -ge 0 } "List Eventhub Autorizationrule: EventHub AuthorizationRule created earlier is not found."

	
	Write-Debug "Update eventHub AuthorizationRule"
	$createdAuthRule.Rights.Add("Manage")
	$updatedAuthRule = Set-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -InputObj $createdAuthRule

	
	Assert-AreEqual $authRuleName $updatedAuthRule.Name "Set Authorizationrule: Authorizationrule name do not match"
	Assert-AreEqual 3 $updatedAuthRule.Rights.Count
	Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
	Assert-True { $updatedAuthRule.Rights -Contains "Send" }
	Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	   
	
	$updatedAuthRule = Get-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName
	
	
	Assert-AreEqual $authRuleName $updatedAuthRule.Name "Get Authorization rule after Set (updated): Autho rule name dosent match"
	Assert-AreEqual 3 $updatedAuthRule.Rights.Count
	Assert-True { $updatedAuthRule.Rights -Contains "Listen" }
	Assert-True { $updatedAuthRule.Rights -Contains "Send" }
	Assert-True { $updatedAuthRule.Rights -Contains "Manage" }
	
	
	Write-Debug "Get Eventhub authorizationRules connectionStrings"
	$namespaceListKeys = Get-AzEventHubKey -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName

	Assert-True {$namespaceListKeys.PrimaryConnectionString -like "*$($updatedAuthRule.PrimaryKey)*"}
	Assert-True {$namespaceListKeys.SecondaryConnectionString -like "*$($updatedAuthRule.SecondaryKey)*"}
	
	$StartTime = Get-Date
	$EndTime = $StartTime.AddHours(2.0)
	$SasToken = New-AzEventHubAuthorizationRuleSASToken -ResourceId $updatedAuthRule.Id -KeyType Primary -ExpiryTime $EndTime -StartTime $StartTime
	
	
	$policyKey = "PrimaryKey"

	$namespaceRegenerateKeysDefault = New-AzEventHubKey -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -RegenerateKey $policyKey
	Assert-True {$namespaceRegenerateKeysDefault.PrimaryKey -ne $namespaceListKeys.PrimaryKey}

	$namespaceRegenerateKeys = New-AzEventHubKey -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -RegenerateKey $policyKey -KeyValue $namespaceListKeys.PrimaryKey
	Assert-AreEqual $namespaceRegenerateKeys.PrimaryKey $namespaceListKeys.PrimaryKey

	$policyKey1 = "SecondaryKey"

	$namespaceRegenerateKeys1 = New-AzEventHubKey -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -RegenerateKey $policyKey1 -KeyValue $namespaceListKeys.PrimaryKey
	Assert-AreEqual $namespaceRegenerateKeys1.SecondaryKey $namespaceListKeys.PrimaryKey

	$namespaceRegenerateKeys1 = New-AzEventHubKey -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -RegenerateKey $policyKey1
	Assert-True {$namespaceRegenerateKeys1.SecondaryKey -ne $namespaceListKeys.PrimaryKey}	

	
	Write-Debug "Delete the created EventHub AuthorizationRule"
	$result = Remove-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName -EventHub $eventHubName -Name $authRuleName -Force
	
	Write-Debug "Delete the Eventhub"
	Remove-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $eventHubName 
	
	Write-Debug "Delete NameSpace"
	Remove-AzEventHubNamespace -ResourceGroup $resourceGroupName -Name $namespaceName

	Write-Debug " Delete resourcegroup"
	Remove-AzResourceGroup -Name $resourceGroupName -Force
}