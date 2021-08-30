




$random = (New-Guid).ToString().Substring(0,8)


$subscriptionId = "my-azure-subscription-id"


$apimServiceName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"


$certificateFilePath = "<Replace with path to the Certificate to be used for Mutual Authentication>"
$certificatePassword = '<Password used to secure the Certificate>'


Select-AzSubscription -SubscriptionId $subscriptionId


New-AzResourceGroup -Name $resourceGroupName -Location $location


New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail


$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName


$cert = New-AzApiManagementCertificate -Context $context -PfxFilePath $certificateFilePath -PfxPassword $certificatePassword


$apiPolicy = "<policies><inbound><base /><authentication-certificate thumbprint=""" + $cert.Thumbprint + """ /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>"
$echoApi = Get-AzApiManagementApi -Context $context -Name "Echo API"


Set-AzApiManagementPolicy -Context $context  -Policy $apiPolicy -ApiId $echoApi.ApiId

