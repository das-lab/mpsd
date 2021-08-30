


Get-AzLocation | select Location


$location = "eastus"


$resourceGroup = "rotatekeystestrg"
New-AzResourceGroup -Name $resourceGroup -Location $location 


$storageAccountName = "contosotestkeys"
New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageAccountName `
  -Location $location `
  -SkuName Standard_LRS `


$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName).Value[0]

Write-Host "storage account key 1 = " $storageAccountKey


New-AzStorageAccountKey -ResourceGroupName $resourceGroup `
    -Name $storageAccountName `
    -KeyName key1


$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName).Value[0]
Write-Host "storage account key 1 = " $storageAccountKey
