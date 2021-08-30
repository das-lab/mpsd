




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


Get-AzApiManagementSsoToken -ResourceGroupName $resourceGroupName -Name $apimServiceName
