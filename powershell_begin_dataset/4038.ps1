














function Test-OriginGetSetWithRunningEndpoint
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku

    $endpointName = getAssetName
    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $httpPort = 80

    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName -HttpPort $httpPort

    $createdOrigin = $createdEndpoint | Get-AzCdnOrigin -OriginName $originName 
    Assert-AreEqual $originName $createdOrigin.Name
    Assert-AreEqual $originHostName $createdOrigin.HostName
    Assert-AreEqual $httpPort $createdOrigin.HttpPort
    Assert-Null $createdOrigin.HttpsPort

    $createdOrigin.HttpPort = 789
    $createdOrigin.HttpsPort = 456
    $createdOrigin.HostName = "www.azure.com"

    $updatedOrigin = $createdOrigin | Set-AzCdnOrigin

    Assert-AreEqual $originName $updatedOrigin.Name
    Assert-AreEqual "www.azure.com" $updatedOrigin.HostName
    Assert-AreEqual 456 $updatedOrigin.HttpsPort
    Assert-AreEqual 789 $updatedOrigin.HttpPort

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-OriginGetSetWithStoppedEndpoint
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku

    $endpointName = getAssetName
    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $httpPort = 80

    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName -HttpPort $httpPort
    Stop-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Confirm:$false

    $createdOrigin = Get-AzCdnOrigin -OriginName $originName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    Assert-AreEqual $originName $createdOrigin.Name
    Assert-AreEqual $originHostName $createdOrigin.HostName
    Assert-AreEqual $httpPort $createdOrigin.HttpPort
    Assert-Null $createdOrigin.HttpsPort

    $createdOrigin.HttpPort = 789
    $createdOrigin.HttpsPort = 456
    $createdOrigin.HostName = "www.azure.com"

    $updatedOrigin = Set-AzCdnOrigin -CdnOrigin $createdOrigin

    Assert-AreEqual $originName $updatedOrigin.Name
    Assert-AreEqual "www.azure.com" $updatedOrigin.HostName
    Assert-AreEqual 456 $updatedOrigin.HttpsPort
    Assert-AreEqual 789 $updatedOrigin.HttpPort

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-OriginGetSetWhenEndpointDoesnotExist
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku

    $endpointName = getAssetName
    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $httpPort = 80

    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName -HttpPort $httpPort

    $createdOrigin = Get-AzCdnOrigin -OriginName $originName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    $createdOrigin.Id = "/subscriptions/d33030b5-85cf-4f96-be7d-b99b5dd0325d/resourcegroups/notarg/providers/Microsoft.Cdn/profiles/notaprofile/endpoints/notanendpoint/origins/notanorigin"

    Assert-ThrowsContains { Get-AzCdnOrigin -OriginName "thisisnotanoriginname" -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "NotFound"
    Assert-ThrowsContains { Set-AzCdnOrigin -CdnOrigin $createdOrigin } "NotFound"

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}