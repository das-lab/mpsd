




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


$proxyHostname = "proxy.contoso.net"

$proxyCertificatePath = "C:\proxycert.pfx"
$proxyCertificatePassword = "certPassword"

$portalHostname = "portal.contoso.net"

$portalCertificatePath = "C:\portalcert.pfx"
$portalCertificatePassword = "certPassword"


$proxyCertUploadResult = Import-AzApiManagementHostnameCertificate -Name $apimServiceName -ResourceGroupName $resourceGroupName `
                        -HostnameType "Proxy" -PfxPath $proxyCertificatePath -PfxPassword $proxyCertificatePassword


$portalCertUploadResult = Import-AzApiManagementHostnameCertificate -Name $apimServiceName -ResourceGroupName $resourceGroupName `
                        -HostnameType "Portal" -PfxPath $portalCertificatePath -PfxPassword $portalCertificatePassword


$PortalHostnameConf = New-AzApiManagementHostnameConfiguration -Hostname $proxyHostname -CertificateThumbprint $proxyCertUploadResult.Thumbprint


$ProxyHostnameConf = New-AzApiManagementHostnameConfiguration -Hostname $portalHostname -CertificateThumbprint $portalCertUploadResult.Thumbprint


Set-AzApiManagementHostnames -Name $apimServiceName -ResourceGroupName $resourceGroupName `
        -PortalHostnameConfiguration $PortalHostnameConf -ProxyHostnameConfiguration $ProxyHostnameConf
