
$storageName = "<your-unique-storage-name>"


$myEndpoint = "<your-endpoint-URL>"


$myResourceGroup="<resource-group-name>"


New-AzResourceGroup -Name $myResourceGroup -Location westus2


New-AzStorageAccount -ResourceGroupName $myResourceGroup `
  -Name $storageName `
  -Location westus2 `
  -SkuName Standard_LRS `
  -Kind BlobStorage `
  -AccessTier Hot


$storageId = (Get-AzStorageAccount -ResourceGroupName $myResourceGroup -AccountName $storageName).Id


New-AzEventGridSubscription `
  -EventSubscriptionName demoSubToStorage `
  -Endpoint $myEndpoint `
  -ResourceId $storageId
