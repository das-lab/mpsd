













$commands = 

function Test-SetAzureStorageBlobContent
{
  Assert-ThrowsContains {
    Set-AzureStorageBlobContent -File "foo.txt" -Container foo -Blob foo -BlobType Block 
  } "Could not get the storage context.  Please pass in a storage context or set the current storage context." > $null
}

function Test-UpdateStorageAccount
{
  $accounts = Get-AzureStorageAccount
  $subscription = $(Get-AzureSubscription -Current).SubscriptionName
  Set-AzureSubscription -SubscriptionName $subscription -CurrentStorageAccountName $accounts[0].StorageAccountName
  $storageAccountName = $(Get-AzureStorageContainer)[0].Context.StorageAccountName
  Assert-AreEqual $storageAccountName $accounts[0].StorageAccountName

  Set-AzureSubscription -SubscriptionName $subscription -CurrentStorageAccountName $accounts[1].StorageAccountName
  $storageAccountName = $(Get-AzureStorageContainer)[0].Context.StorageAccountName
  Assert-AreEqual $storageAccountName $accounts[1].StorageAccountName
  
}

[CmdletBinding]
function Get-IncompleteHelp
{
  Get-Help azure | where {[System.String]::IsNullOrEmpty($_.Synopsis) -or `
  [System.String]::Equals($_.Synopsis, (Get-Command $_.Name).Definition, `
  [System.StringComparison]::OrdinalIgnoreCase)} | % {Write-Output $_.Name}
}