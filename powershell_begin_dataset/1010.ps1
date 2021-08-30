



$random = (New-Guid).ToString().Substring(0,8)


$subscriptionId = "my-azure-subscription-id"


$apimServiceName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"


$userEmail = "user@contoso.com"
$userFirstName = "userFirstName"
$userLastName = "userLastName"
$userPassword = "userPassword"
$userNote = "fellow trying out my apim instance"
$userState = "Active"


$subscriptionName = "subscriptionName"
$subscriptionState = "Active"


Select-AzSubscription -SubscriptionId $subscriptionId


New-AzResourceGroup -Name $resourceGroupName -Location $location


New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail


$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName


$user = New-AzApiManagementUser -Context $context -FirstName $userFirstName -LastName $userLastName `
    -Password $userPassword -State $userState -Note $userNote -Email $userEmail


$product = Get-AzApiManagementProduct -Context $context -Title 'Starter' | Select-Object -First 1


New-AzApiManagementSubscription -Context $context -UserId $user.UserId `
    -ProductId $product.ProductId -Name $subscriptionName -State $subscriptionState

