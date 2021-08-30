








$resourceGroup = "bloblisttestrg"
$storageAccountName = "contosobloblisttest"
$containerName = "listtestblobs"


$storageAccount = Get-AzStorageAccount `
  -ResourceGroupName $resourceGroup `
  -Name $storageAccountName
$ctx = $storageAccount.Context 


$listOfBLobs = Get-AzStorageBlob -Container $ContainerName -Context $ctx 


$length = 0



$listOfBlobs | ForEach-Object {$length = $length + $_.Length}


Write-Host "List of Blobs and their size (length)"
Write-Host " " 
$listOfBlobs | select Name, Length
Write-Host " "
Write-Host "Total Length = " $length
