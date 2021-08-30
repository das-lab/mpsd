














function TopicTypeTests_Operations {
    Write-Debug "Getting topic types"
    $topicTypes = Get-AzEventGridTopicType
    Assert-True {$topicTypes.Count -ge 3}

    $storage = "Microsoft.Storage.StorageAccounts"

    Write-Debug "Getting topic type info for Storage"
    $returnedTopicTypes1 = Get-AzEventGridTopicType -Name $storage
    Assert-True {$returnedTopicTypes1.Count -eq 1}
    Assert-True {$returnedTopicTypes1[0].TopicTypeName -eq $storage}
    Assert-True {$returnedTopicTypes1[0].EventTypes -eq $null}

    Write-Debug "Getting topic type info for Storage, with event types"
    $returnedTopicTypes2 = Get-AzEventGridTopicType -Name $storage -IncludeEventTypeData
    Assert-True {$returnedTopicTypes2.Count -eq 1}
    Assert-True {$returnedTopicTypes2[0].TopicTypeName -eq $storage}
    Assert-True {$returnedTopicTypes2[0].EventTypes -ne $null}
    Assert-True {$returnedTopicTypes2[0].EventTypes.Count -ge 1}
}
