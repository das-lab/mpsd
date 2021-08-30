

$Random=(New-Guid).ToString().Substring(0,8)


$ResourceGroup="MyResourceGroup$Random"
$AppName="webappwithStorage$Random"
$StorageName="webappstorage$Random"
$Location="West US"


New-AzResourceGroup -Name $ResourceGroup -Location $Location


New-AzAppservicePlan -Name WebAppwithStoragePlan -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic


New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan WebAppwithStoragePlan


New-AzStorageAccount -Name $StorageName -ResourceGroupName $ResourceGroup -Location $Location -SkuName Standard_LRS


$StorageKey=(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageName).Value[0]


Set-AzWebApp -ConnectionStrings @{ MyStorageConnStr = @{ Type="Custom"; Value="DefaultEndpointsProtocol=https;AccountName=$StorageName;AccountKey=$StorageKey;" } } -Name $AppName -ResourceGroupName $ResourceGroup
