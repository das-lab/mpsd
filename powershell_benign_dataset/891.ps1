$webappname="mywebapp$(Get-Random -Minimum 100000 -Maximum 999999)"
$storagename="$($webappname)storage"
$container="appbackup"
$location="West Europe"
$backupname="backup1"


New-AzResourceGroup -Name myResourceGroup -Location $location


$storage = New-AzStorageAccount -ResourceGroupName myResourceGroup `
-Name $storagename -SkuName Standard_LRS -Location $location


New-AzStorageContainer -Name $container -Context $storage.Context



$sasUrl = New-AzStorageContainerSASToken -Name $container -Permission rwdl `
-Context $storage.Context -ExpiryTime (Get-Date).AddMonths(1) -FullUri


New-AzAppServicePlan -ResourceGroupName myResourceGroup -Name $webappname `
-Location $location -Tier Standard


New-AzWebApp -ResourceGroupName myResourceGroup -Name $webappname `
-Location $location -AppServicePlan $webappname


New-AzWebAppBackup -ResourceGroupName myResourceGroup -Name $webappname `
-StorageAccountUrl $sasUrl -BackupName $backupname


Get-AzWebAppBackupList -ResourceGroupName myResourceGroup -Name $webappname
