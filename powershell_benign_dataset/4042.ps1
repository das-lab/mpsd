














function Test-CustomDomainGetRemoveWithRunningEndpoint
{
    
    $endpointName = "testAkamaiEP"
    $hostName = "testAkamai.dustydog.us"

    $customDomainName = getAssetName

    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Akamai"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku -Tag $tags

    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName

    $endpoint = Get-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    $validateResult = Test-AzCdnCustomDomain -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -CustomDomainHostName $hostName
    Assert-True{$validateResult.CustomDomainValidated}
    $validateResultbyPiping = Test-AzCdnCustomDomain -CdnEndpoint $endpoint -CustomDomainHostName $hostName
    Assert-True{$validateResultbyPiping.CustomDomainValidated}

    $createdCustomDomain = $endpoint | New-AzCdnCustomDomain -HostName $hostName -CustomDomainName $customDomainName
    Assert-AreEqual $customDomainName $createdCustomDomain.Name
    Assert-AreEqual $hostName $createdCustomDomain.HostName
    Assert-ThrowsContains { New-AzCdnCustomDomain -HostName $hostName -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "existing"

    $customDomain = $endpoint | Get-AzCdnCustomDomain -CustomDomainName $customDomainName
    Assert-AreEqual $customDomainName $customDomain.Name
    Assert-AreEqual $hostName $customDomain.HostName

    $removed = $customDomain | Remove-AzCdnCustomDomain -PassThru
    Assert-True{$removed}
    Assert-ThrowsContains { Remove-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "does not exist"

    Assert-ThrowsContains { Get-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "NotFound"

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-CustomDomainEnableDisableWithRunningEndpoint
{
    
    $endpointName = "testVerizonEP"
    $hostName = "testVerizon.dustydog.us"
    
    $customDomainName = getAssetName

    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku -Tag $tags

    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName

    $endpoint = Get-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    $validateResult = Test-AzCdnCustomDomain -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -CustomDomainHostName $hostName
    Assert-True{$validateResult.CustomDomainValidated}
    $validateResultbyPiping = Test-AzCdnCustomDomain -CdnEndpoint $endpoint -CustomDomainHostName $hostName
    Assert-True{$validateResultbyPiping.CustomDomainValidated}

    $createdCustomDomain = $endpoint | New-AzCdnCustomDomain -HostName $hostName -CustomDomainName $customDomainName 
    Assert-AreEqual $customDomainName $createdCustomDomain.Name
    Assert-AreEqual $hostName $createdCustomDomain.HostName
    
   	$customDomain = $endpoint | Get-AzCdnCustomDomain -CustomDomainName $customDomainName 
    Assert-AreEqual $customDomainName $customDomain.Name
    Assert-AreEqual $hostName $customDomain.HostName

    $enabled = $customDomain | Enable-AzCdnCustomDomainHttps -PassThru
    Assert-True{$enabled}
    Assert-ThrowsContains { Enable-AzCdnCustomDomainHttps -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "BadRequest"

    Assert-ThrowsContains { Disable-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "BadRequest"

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}



function Test-CustomDomainGetRemoveWithStoppedEndpoint
{
  
    $endpointName = "testAkamaiEP"
    $hostName = "testAkamai.dustydog.us"

    $customDomainName = getAssetName

    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Akamai"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku -Tag $tags

    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName

    $endpoint = Get-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    $validateResult = Test-AzCdnCustomDomain -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -CustomDomainHostName $hostName
    Assert-True{$validateResult.CustomDomainValidated}
    $validateResultbyPiping = Test-AzCdnCustomDomain -CdnEndpoint $endpoint -CustomDomainHostName $hostName
    Assert-True{$validateResultbyPiping.CustomDomainValidated}

    $createdCustomDomain = New-AzCdnCustomDomain -HostName $hostName -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    Assert-AreEqual $customDomainName $createdCustomDomain.Name
    Assert-AreEqual $hostName $createdCustomDomain.HostName
    Assert-ThrowsContains { New-AzCdnCustomDomain -HostName $hostName -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "existing"

    $stopped = Stop-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    $customDomain = Get-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    Assert-AreEqual $customDomainName $customDomain.Name
    Assert-AreEqual $hostName $customDomain.HostName

    $removed = Remove-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -PassThru
    Assert-True{$removed}
    Assert-ThrowsContains { Remove-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "does not exist"

    Assert-ThrowsContains { Get-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "NotFound"

    Remove-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-CustomDomainEnableHttpsWithRunningEndpoint
{
  
    $endpointName = "testVerizonEP"
    $hostName = "testVerizon.dustydog.us"

    $customDomainName = getAssetName

    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -Sku $profileSku -Tag $tags

    $originName = getAssetName
    $originHostName = "www.microsoft.com"
    $createdEndpoint = New-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceLocation -OriginName $originName -OriginHostName $originHostName

    $endpoint = Get-AzCdnEndpoint -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    $validateResult = Test-AzCdnCustomDomain -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -CustomDomainHostName $hostName
    Assert-True{$validateResult.CustomDomainValidated}
    $validateResultbyPiping = Test-AzCdnCustomDomain -CdnEndpoint $endpoint -CustomDomainHostName $hostName
    Assert-True{$validateResultbyPiping.CustomDomainValidated}

    $createdCustomDomain = New-AzCdnCustomDomain -HostName $hostName -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    Assert-AreEqual $customDomainName $createdCustomDomain.Name
    Assert-AreEqual $hostName $createdCustomDomain.HostName

    $customDomain = Get-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    Assert-AreEqual $customDomainName $customDomain.Name
    Assert-AreEqual $hostName $customDomain.HostName

    $enabled = $customDomain | Enable-AzCdnCustomDomainHttps -PassThru
    Assert-True{$enabled}

    $customDomain = Get-AzCdnCustomDomain -CustomDomainName $customDomainName -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-AreEqual $customDomain.CustomHttpsProvisioningState "Enabling"

    Assert-ThrowsContains { $customDomain | Enable-AzCdnCustomDomainHttps } "BadRequest"

    Assert-ThrowsContains {  $customDomain | Disable-AzCdnCustomDomainHttps } "BadRequest"

    Remove-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}