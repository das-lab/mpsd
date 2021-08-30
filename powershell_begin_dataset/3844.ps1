














function Test-Media
{
  $rgname = GetResourceGroupName
  $preferedlocation = "East US"
  $location = Get-AvailableLocation $preferedlocation
  Write-Output $location

  $resourceGroup = CreateResourceGroup $rgname $location

  $storageAccountName1 = "sto" + $rgname
  $storageAccount1 = CreateStorageAccount $rgname $storageAccountName1 $location

  $storageAccountName2 = "sto" + $rgname + "2"
  $storageAccount2 = CreateStorageAccount $rgname $storageAccountName2 $location

  
  $accountName = "med" + $rgname
  $availability = Get-AzMediaServiceNameAvailability -AccountName $accountName
  Assert-AreEqual $true $availability.nameAvailable

  
  $accountName = "med" + $rgname
  $tags = @{"tag1" = "value1"; "tag2" = "value2"}
  $storageAccount1 = GetStorageAccount -ResourceGroupName $rgname -Name $storageAccountName1
  $mediaService = New-AzMediaService -ResourceGroupName $rgname -AccountName $accountName -Location $location -StorageAccountId $storageAccount1.Id -Tag $tags
  Assert-NotNull $mediaService
  Assert-AreEqual $accountName $mediaService.AccountName
  Assert-AreEqual $rgname $mediaService.ResourceGroupName
  Assert-AreEqual $location $mediaService.Location
  Assert-Tags $tags $mediaService.Tags
  Assert-AreEqual $storageAccountName1 $mediaService.StorageAccounts[0].AccountName
  Assert-AreEqual $true $mediaService.StorageAccounts[0].IsPrimary
  Assert-AreEqual $rgname $mediaService.StorageAccounts[0].ResourceGroupName

  $availability = Get-AzMediaServiceNameAvailability -AccountName $accountName
  Assert-AreEqual $false $availability.nameAvailable

  
  $mediaServices = Get-AzMediaService -ResourceGroupName $rgname
  Assert-NotNull $mediaServices
  Assert-AreEqual 1 $mediaServices.Count
  Assert-AreEqual $accountName $mediaServices[0].AccountName
  Assert-AreEqual $rgname $mediaServices[0].ResourceGroupName
  Assert-AreEqual $location $mediaServices[0].Location
  Assert-AreEqual $storageAccountName1 $mediaServices[0].StorageAccounts[0].AccountName
  Assert-AreEqual $true $mediaService.StorageAccounts[0].IsPrimary
  Assert-AreEqual $rgname $mediaServices[0].StorageAccounts[0].ResourceGroupName

  
  $mediaService = Get-AzMediaService -ResourceGroupName $rgname -AccountName $accountName
  Assert-NotNull $mediaService
  Assert-AreEqual $accountName $mediaService.AccountName
  Assert-AreEqual $rgname $mediaService.ResourceGroupName
  Assert-AreEqual $location $mediaService.Location
  Assert-AreEqual $storageAccountName1 $mediaService.StorageAccounts[0].AccountName
  Assert-AreEqual $true $mediaService.StorageAccounts[0].IsPrimary
  Assert-AreEqual $rgname $mediaService.StorageAccounts[0].ResourceGroupName

  
  $tagsUpdated = @{"tag3" = "value3"; "tag4" = "value4"}
  $storageAccount2 = GetStorageAccount -ResourceGroupName $rgname -Name $storageAccountName2
  $primaryStorageAccount = New-AzMediaServiceStorageConfig -storageAccountId $storageAccount1.Id -IsPrimary
  $secondaryStorageAccount = New-AzMediaServiceStorageConfig -storageAccountId $storageAccount2.Id
  $storageAccounts = @($primaryStorageAccount, $secondaryStorageAccount)
  $mediaServiceUpdated = Set-AzMediaService -ResourceGroupName $rgname -AccountName $accountName -Tag $tagsUpdated -StorageAccounts $storageAccounts
  Assert-NotNull $mediaServiceUpdated
  Assert-Tags $tagsUpdated $mediaServiceUpdated.Tags
  Assert-AreEqual $storageAccountName1 $mediaServiceUpdated.StorageAccounts[0].AccountName
  Assert-AreEqual $true $mediaService.StorageAccounts[0].IsPrimary
  Assert-AreEqual $storageAccountName2 $mediaServiceUpdated.StorageAccounts[1].AccountName
  Assert-AreEqual $false $mediaServiceUpdated.StorageAccounts[1].IsPrimary

  
  $serviceKeys = Get-AzMediaServiceKeys -ResourceGroupName $rgname -AccountName $accountName
  Assert-NotNull $serviceKeys
  Assert-NotNull $serviceKeys.PrimaryAuthEndpoint
  Assert-NotNull $serviceKeys.PrimaryKey
  Assert-NotNull $serviceKeys.SecondaryAuthEndpoint
  Assert-NotNull $serviceKeys.SecondaryKey
  Assert-NotNull $serviceKeys.Scope

  
  $serviceKeysUpdated1 = Set-AzMediaServiceKey -ResourceGroupName $rgname -AccountName $accountName -KeyType Primary
  Assert-NotNull $serviceKeysUpdated1
  Assert-NotNull $serviceKeysUpdated1.Key
  Assert-AreNotEqual $serviceKeys.PrimaryKey $serviceKeysUpdated1.Key

  $serviceKeysUpdated2 = Set-AzMediaServiceKey -ResourceGroupName $rgname -AccountName $accountName -KeyType Secondary
  Assert-NotNull $serviceKeysUpdated2
  Assert-NotNull $serviceKeysUpdated2.Key
  Assert-AreNotEqual $serviceKeys.SecondaryKey $serviceKeysUpdated2.Key

  
  Remove-AzMediaService -ResourceGroupName $rgname -AccountName $accountName -Force
  $mediaServices = Get-AzMediaService -ResourceGroupName $rgname
  Assert-Null $mediaServices

  
  $tags = @{"tag1" = "value1"; "tag2" = "value2"}
  $mediaService = New-AzMediaService -ResourceGroupName $rgname -AccountName $accountName -Location $location -StorageAccounts $storageAccounts -Tag $tags
  Assert-NotNull $mediaService
  Assert-AreEqual $accountName $mediaService.AccountName
  Assert-AreEqual $rgname $mediaService.ResourceGroupName
  Assert-AreEqual $location $mediaService.Location
  Assert-Tags $tags $mediaService.Tags
  Assert-AreEqual $storageAccountName1 $mediaService.StorageAccounts[0].AccountName
  Assert-AreEqual $true $mediaService.StorageAccounts[0].IsPrimary
  Assert-AreEqual $rgname $mediaService.StorageAccounts[0].ResourceGroupName
  Assert-AreEqual $storageAccountName2 $mediaService.StorageAccounts[1].AccountName
  Assert-AreEqual $false $mediaService.StorageAccounts[1].IsPrimary
  Assert-AreEqual $rgname $mediaService.StorageAccounts[1].ResourceGroupName

  Remove-AzMediaService -ResourceGroupName $rgname -AccountName $accountName -Force
  RemoveStorageAccount $rgname $storageAccountName1
  RemoveStorageAccount $rgname $storageAccountName2
  RemoveResourceGroup $rgname
}


function Test-MediaWithPiping
{
  $rgname = GetResourceGroupName
  $preferedlocation = "East US"
  $location = Get-AvailableLocation $preferedlocation

  $resourceGroup = CreateResourceGroup $rgname $location
  Assert-NotNull $resourceGroup
  Assert-AreEqual $rgname $resourceGroup.ResourceGroupName
  Assert-AreEqual $location $resourceGroup.Location

  $storageAccountName1 = "sto" + $rgname
  $storageAccount1 = CreateStorageAccount $rgname $storageAccountName1 $location

  
  $accountName = "med" + $rgname
  $tags = @{"tag1" = "value1"; "tag2" = "value2"}
  $mediaService = GetStorageAccount -ResourceGroupName $rgname -Name $storageAccountName1 | New-AzMediaService -ResourceGroupName $rgname -AccountName $accountName -Location $location -Tag $tags
  Assert-NotNull $mediaService
  Assert-AreEqual $accountName $mediaService.AccountName
  Assert-AreEqual $rgname $mediaService.ResourceGroupName
  Assert-AreEqual $location $mediaService.Location
  Assert-Tags $tags $mediaService.Tags
  Assert-AreEqual $storageAccountName1 $mediaService.StorageAccounts[0].AccountName
  Assert-AreEqual $true $mediaService.StorageAccounts[0].IsPrimary
  Assert-AreEqual $rgname $mediaService.StorageAccounts[0].ResourceGroupName

  
  $tagsUpdated = @{"tag3" = "value3"; "tag4" = "value4"}
  $mediaServiceUpdated = Get-AzMediaService -ResourceGroupName $rgname -AccountName $accountName | Set-AzMediaService -Tag $tagsUpdated
  Assert-NotNull $mediaServiceUpdated
  Assert-Tags $tagsUpdated $mediaServiceUpdated.Tags

  
  $serviceKeys = Get-AzMediaService -ResourceGroupName $rgname -AccountName $accountName | Get-AzMediaServiceKeys
  Assert-NotNull $serviceKeys
  Assert-NotNull $serviceKeys.PrimaryAuthEndpoint
  Assert-NotNull $serviceKeys.PrimaryKey
  Assert-NotNull $serviceKeys.SecondaryAuthEndpoint
  Assert-NotNull $serviceKeys.SecondaryKey
  Assert-NotNull $serviceKeys.Scope

  
  $serviceKeysUpdated2 = Get-AzMediaService -ResourceGroupName $rgname -AccountName $accountName | Set-AzMediaServiceKey -KeyType Secondary
  Assert-NotNull $serviceKeysUpdated2
  Assert-NotNull $serviceKeysUpdated2.Key
  Assert-AreNotEqual $serviceKeys.SecondaryKey $serviceKeysUpdated2.Key

  
  Get-AzMediaService -ResourceGroupName $rgname -AccountName $accountName | Remove-AzMediaService -Force

  RemoveStorageAccount $rgname $storageAccountName
  RemoveResourceGroup $rgname
}