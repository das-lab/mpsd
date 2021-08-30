




$random = (New-Guid).ToString().Substring(0,8)


$subscriptionId = "my-azure-subscription-id"


$apimServiceName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"


Select-AzSubscription -SubscriptionId $subscriptionId


New-AzResourceGroup -Name $resourceGroupName -Location $location


New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail


$sku = "Premium"
$capacity = 1


$additionLocation = Get-ProviderLocations "Microsoft.ApiManagement/service" | Where-Object {$_ -ne $location} | Select-Object -First 1

Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName |
Update-AzApiManagementRegion -Sku $sku -Capacity $capacity |
Add-AzApiManagementRegion -Location $additionLocation -Sku $sku |
Update-AzApiManagementDeployment

Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName
