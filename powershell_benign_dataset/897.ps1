$webappname="mywebapp$(Get-Random -Minimum 100000 -Maximum 999999)"
$storagename="$($webappname)storage"
$container="appbackup"
$location="West Europe"


New-AzResourceGroup -Name myResourceGroup -Location $location


$storage = New-AzStorageAccount -ResourceGroupName myResourceGroup `
-Name $storagename -SkuName Standard_LRS -Location $location


New-AzStorageContainer -Name $container -Context $storage.Context



$sasUrl = New-AzStorageContainerSASToken -Name $container -Permission rwdl `
-Context $storage.Context -ExpiryTime (Get-Date).AddYears(1) -FullUri


New-AzAppServicePlan -ResourceGroupName myResourceGroup -Name $webappname `
-Location $location -Tier Standard


New-AzWebApp -ResourceGroupName myResourceGroup -Name $webappname `
-Location $location -AppServicePlan $webappname


Edit-AzWebAppBackupConfiguration -ResourceGroupName myResourceGroup -Name $webappname `
-StorageAccountUrl $sasUrl -FrequencyInterval 1 -FrequencyUnit Day -KeepAtLeastOneBackup `
-StartTime (Get-Date).AddHours(1) -RetentionPeriodInDays 10


Get-AzWebAppBackupList -ResourceGroupName myResourceGroup -Name $webappname


$configuration = Get-AzWebAppBackupConfiguration -ResourceGroupName myResourceGroup `
-Name $webappname
$configuration.FrequencyInterval = 2
$configuration | Edit-AzWebAppBackupConfiguration
