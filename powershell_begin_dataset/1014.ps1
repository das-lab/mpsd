




$random = (New-Guid).ToString().Substring(0,8)


$subscriptionId = "my-azure-subscription-id"


$apimServiceName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"


$swaggerUrl = "http://petstore.swagger.io/v2/swagger.json"
$apiPath = "petstore"


Select-AzSubscription -SubscriptionId $subscriptionId


New-AzResourceGroup -Name $resourceGroupName -Location $location


New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail


$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName


$api = Import-AzApiManagementApi -Context $context -SpecificationUrl $swaggerUrl -SpecificationFormat Swagger -Path $apiPath

$productName = "Pet Store Product"
$productDescription = "Product giving access to Petstore api"
$productState = "Published"


$product = New-AzApiManagementProduct -Context $context -Title $productName -Description $productDescription -State $productState -SubscriptionsLimit 10 


Add-AzApiManagementApiToProduct -Context $context -ProductId $product.ProductId -ApiId $api.ApiId
