














function Test-AzureFirewallCRUD {
    
    $rgname = Get-ResourceGroupName
    $azureFirewallName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/AzureFirewalls"
    $location = Get-ProviderLocation $resourceTypeParent "eastus2euap"

    $vnetName = Get-ResourceName
    $subnetName = "AzureFirewallSubnet"
    $publicIpName = Get-ResourceName

    
    $appRcName = "appRc"
    $appRcPriority = 100
    $appRcActionType = "Allow"

    
    $appRc2Name = "appRc2"
    $appRc2Priority = 101
    $appRc2ActionType = "Deny"

    
    $appRule1Name = "appRule"
    $appRule1Desc = "desc1"
    $appRule1Fqdn1 = "*google.com"
    $appRule1Fqdn2 = "*microsoft.com"
    $appRule1Protocol1 = "http:80"
    $appRule1Port1 = 80
    $appRule1ProtocolType1 = "http"
    $appRule1Protocol2 = "https:443"
    $appRule1Port2 = 443
    $appRule1ProtocolType2 = "https"
    $appRule1SourceAddress1 = "10.0.0.0"

    
    $appRule2Name = "appRule2"
    $appRule2Fqdn1 = "*bing.com"
    $appRule2Protocol1 = "http:8080"
    $appRule2Port1 = 8080
    $appRule2ProtocolType1 = "http"

    
    $appRule3Name = "appRule3"
    $appRule3Fqdn1 = "sql1.database.windows.net"
    $appRule3Protocol1 = "mssql:1433"
    $appRule3Port1 = 1433
    $appRule3ProtocolType1 = "mssql"

    
    $networkRcName = "networkRc"
    $networkRcPriority = 200
    $networkRcActionType = "Deny"

    
    $networkRule1Name = "networkRule"
    $networkRule1Desc = "desc1"
    $networkRule1SourceAddress1 = "10.0.0.0"
    $networkRule1SourceAddress2 = "111.1.0.0/24"
    $networkRule1DestinationAddress1 = "*"
    $networkRule1Protocol1 = "UDP"
    $networkRule1Protocol2 = "TCP"
    $networkRule1Protocol3 = "ICMP"
    $networkRule1DestinationPort1 = "90"

	
    $networkRule2Name = "networkRule2"
    $networkRule2Desc = "desc2"
    $networkRule2SourceAddress1 = "10.0.0.0"
    $networkRule2SourceAddress2 = "111.1.0.0/24"
    $networkRule2DestinationFqdn1 = "www.bing.com"
    $networkRule2Protocol1 = "UDP"
    $networkRule2Protocol2 = "TCP"
    $networkRule2Protocol3 = "ICMP"
    $networkRule2DestinationPort1 = "80"

    
    $natRcName = "natRc"
    $natRcPriority = 200

    
    $natRule1Name = "natRule"
    $natRule1Desc = "desc1"
    $natRule1SourceAddress1 = "10.0.0.0"
    $natRule1SourceAddress2 = "111.1.0.0/24"
    $natRule1DestinationAddress1 = "1.2.3.4"
    $natRule1Protocol1 = "UDP"
    $natRule1Protocol2 = "TCP"
    $natRule1DestinationPort1 = "90"
    $natRule1TranslatedAddress = "10.1.2.3"
    $natRule1TranslatedPort = "91"

	
    $natRule2Name = "natRule2"
    $natRule2Desc = "desc2"
    $natRule2SourceAddress1 = "10.0.0.0"
    $natRule2SourceAddress2 = "111.1.0.0/24"
    $natRule2Protocol1 = "UDP"
    $natRule2Protocol2 = "TCP"
    $natRule2DestinationPort1 = "95"
    $natRule2TranslatedFqdn = "server1.internal.com"
    $natRule2TranslatedPort = "96"

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard

        
        $azureFirewall = New-AzFirewall –Name $azureFirewallName -ResourceGroupName $rgname -Location $location -VirtualNetworkName $vnetName -PublicIpName $publicIpName

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual (Normalize-Location $location) $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag
        Assert-AreEqual "Alert" $getAzureFirewall.ThreatIntelMode
        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual $subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual 0 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NetworkRuleCollections).Count

        
        $list = Get-AzFirewall -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $list[0].Name $getAzureFirewall.Name
        Assert-AreEqual $list[0].Location $getAzureFirewall.Location
        Assert-AreEqual $list[0].Etag $getAzureFirewall.Etag
        Assert-AreEqual @($list[0].IpConfigurations).Count @($getAzureFirewall.IpConfigurations).Count
        Assert-AreEqual @($list[0].IpConfigurations)[0].Subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual @($list[0].IpConfigurations)[0].PublicIpAddress.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual @($list[0].IpConfigurations)[0].PrivateIpAddress $getAzureFirewall.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual @($list[0].ApplicationRuleCollections).Count @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual @($list[0].NatRuleCollections).Count @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual @($list[0].NetworkRuleCollections).Count @($getAzureFirewall.NetworkRuleCollections).Count

        
        $listAll = Get-AzureRmFirewall
        Assert-NotNull $listAll

        $listAll = Get-AzureRmFirewall -Name "*"
        Assert-NotNull $listAll

        $listAll = Get-AzureRmFirewall -ResourceGroupName "*"
        Assert-NotNull $listAll

        $listAll = Get-AzureRmFirewall -ResourceGroupName "*" -Name "*"
        Assert-NotNull $listAll

        
        $appRule = New-AzFirewallApplicationRule -Name $appRule1Name -Description $appRule1Desc -Protocol $appRule1Protocol1, $appRule1Protocol2 -TargetFqdn $appRule1Fqdn1, $appRule1Fqdn2 -SourceAddress $appRule1SourceAddress1

        $appRule2 = New-AzFirewallApplicationRule -Name $appRule2Name -Protocol $appRule2Protocol1 -TargetFqdn $appRule2Fqdn1

        $appRule3 = New-AzFirewallApplicationRule -Name $appRule3Name -Protocol $appRule3Protocol1 -TargetFqdn $appRule3Fqdn1

        
        $appRc = New-AzFirewallApplicationRuleCollection -Name $appRcName -Priority $appRcPriority -Rule $appRule -ActionType $appRcActionType

        
        $appRc.AddRule($appRule2)
        $appRc.AddRule($appRule3)

        
        $appRc2 = New-AzFirewallApplicationRuleCollection -Name $appRc2Name -Priority $appRc2Priority -Rule $appRule -ActionType $appRc2ActionType

        
        $networkRule = New-AzFirewallNetworkRule -Name $networkRule1Name -Description $networkRule1Desc -Protocol $networkRule1Protocol1, $networkRule1Protocol2 -SourceAddress $networkRule1SourceAddress1, $networkRule1SourceAddress2 -DestinationAddress $networkRule1DestinationAddress1 -DestinationPort $networkRule1DestinationPort1
        $networkRule.AddProtocol($networkRule1Protocol3)

        
        Assert-ThrowsContains { $networkRule.AddProtocol() } "Cannot find an overload"
        Assert-ThrowsContains { $networkRule.AddProtocol($null) } "A protocol must be provided"
        Assert-ThrowsContains { $networkRule.AddProtocol("ABCD") } "Invalid protocol"

        
        $netRc = New-AzFirewallNetworkRuleCollection -Name $networkRcName -Priority $networkRcPriority -Rule $networkRule -ActionType $networkRcActionType

        
        $networkRule2 = New-AzFirewallNetworkRule -Name $networkRule2Name -Description $networkRule2Desc -Protocol $networkRule2Protocol1, $networkRule2Protocol2 -SourceAddress $networkRule2SourceAddress1, $networkRule2SourceAddress2 -DestinationFqdn $networkRule2DestinationFqdn1 -DestinationPort $networkRule2DestinationPort1
        $networkRule2.AddProtocol($networkRule2Protocol3)

        
        $netRc.AddRule($networkRule2)

        
        $natRule = New-AzFirewallNatRule -Name $natRule1Name -Description $natRule1Desc -Protocol $natRule1Protocol1 -SourceAddress $natRule1SourceAddress1, $natRule1SourceAddress2 -DestinationAddress $publicip.IpAddress -DestinationPort $natRule1DestinationPort1 -TranslatedAddress $natRule1TranslatedAddress -TranslatedPort $natRule1TranslatedPort
        $natRule.AddProtocol($natRule1Protocol2)

        
        Assert-ThrowsContains { $natRule.AddProtocol() } "Cannot find an overload"
        Assert-ThrowsContains { $natRule.AddProtocol($null) } "A protocol must be provided"
        Assert-ThrowsContains { $natRule.AddProtocol("ABCD") } "Invalid protocol"
        
        Assert-ThrowsContains {
            New-AzFirewallNatRule -Name $natRule1Name -Protocol $natRule1Protocol1, "ICMP" -SourceAddress $natRule1SourceAddress1 -DestinationAddress $natRule1DestinationAddress1 -DestinationPort $natRule1DestinationPort1 -TranslatedAddress $natRule1TranslatedAddress -TranslatedPort $natRule1TranslatedPort
        } "The argument `"ICMP`" does not belong to the set"
        Assert-ThrowsContains { $natRule.AddProtocol("ICMP") } "Invalid protocol"

        
        $natRule2 = New-AzFirewallNatRule -Name $natRule2Name -Description $natRule2Desc -Protocol $natRule2Protocol1 -SourceAddress $natRule2SourceAddress1, $natRule2SourceAddress2 -DestinationAddress $publicip.IpAddress -DestinationPort $natRule2DestinationPort1 -TranslatedFqdn $natRule2TranslatedFqdn -TranslatedPort $natRule2TranslatedPort
        $natRule2.AddProtocol($natRule2Protocol2)

        
        $natRc = New-AzFirewallNatRuleCollection -Name $natRcName -Priority $natRcPriority -Rule $natRule

        
        $natRc.AddRule($natRule2)

        
        $azureFirewall.AddApplicationRuleCollection($appRc)
        $azureFirewall.AddApplicationRuleCollection($appRc2)

        
        $azureFirewall.AddNatRuleCollection($natRc)

        
        $azureFirewall.AddNetworkRuleCollection($netRc)

        
        $azureFirewall.ThreatIntelMode = "Deny"

        
        Set-AzFirewall -AzureFirewall $azureFirewall

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgName
        $azureFirewallIpConfiguration = $getAzureFirewall.IpConfigurations

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag
        Assert-AreEqual "Deny" $getAzureFirewall.ThreatIntelMode

        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $azureFirewallIpConfiguration[0].Subnet.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PublicIpAddress.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PrivateIpAddress

        
        Assert-AreEqual 2 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 3 @($getAzureFirewall.ApplicationRuleCollections[0].Rules).Count
        Assert-AreEqual 1 @($getAzureFirewall.ApplicationRuleCollections[1].Rules).Count

        Assert-AreEqual 1 @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual 2 @($getAzureFirewall.NatRuleCollections[0].Rules).Count

        Assert-AreEqual 1 @($getAzureFirewall.NetworkRuleCollections).Count
        Assert-AreEqual 2 @($getAzureFirewall.NetworkRuleCollections[0].Rules).Count

        $appRc = $getAzureFirewall.GetApplicationRuleCollectionByName($appRcName)
        $appRule = $appRc.GetRuleByName($appRule1Name)
        $appRule2 = $appRc.GetRuleByName($appRule2Name)
        $appRule3 = $appRc.GetRuleByName($appRule3Name)

        
        Assert-AreEqual $appRcName $appRc.Name
        Assert-AreEqual $appRcPriority $appRc.Priority
        Assert-AreEqual $appRcActionType $appRc.Action.Type

        
        Assert-AreEqual $appRule1Name $appRule.Name
        Assert-AreEqual $appRule1Desc $appRule.Description

        Assert-AreEqual 1 $appRule.SourceAddresses.Count
        Assert-AreEqual $appRule1SourceAddress1 $appRule.SourceAddresses[0]

        Assert-AreEqual 2 $appRule.Protocols.Count 
        Assert-AreEqual $appRule1ProtocolType1 $appRule.Protocols[0].ProtocolType
        Assert-AreEqual $appRule1ProtocolType2 $appRule.Protocols[1].ProtocolType
        Assert-AreEqual $appRule1Port1 $appRule.Protocols[0].Port
        Assert-AreEqual $appRule1Port2 $appRule.Protocols[1].Port

        Assert-AreEqual 2 $appRule.TargetFqdns.Count 
        Assert-AreEqual $appRule1Fqdn1 $appRule.TargetFqdns[0]
        Assert-AreEqual $appRule1Fqdn2 $appRule.TargetFqdns[1]

        
        Assert-AreEqual $appRule2Name $appRule2.Name
        Assert-Null $appRule2.Description

        Assert-AreEqual 0 $appRule2.SourceAddresses.Count

        Assert-AreEqual 1 $appRule2.Protocols.Count 
        Assert-AreEqual $appRule2ProtocolType1 $appRule2.Protocols[0].ProtocolType
        Assert-AreEqual $appRule2Port1 $appRule2.Protocols[0].Port

        Assert-AreEqual 1 $appRule2.TargetFqdns.Count 
        Assert-AreEqual $appRule2Fqdn1 $appRule2.TargetFqdns[0]

        
        Assert-AreEqual $appRule3Name $appRule3.Name
        Assert-Null $appRule3.Description

        Assert-AreEqual 0 $appRule3.SourceAddresses.Count

        Assert-AreEqual 1 $appRule3.Protocols.Count
        Assert-AreEqual $appRule3ProtocolType1 $appRule3.Protocols[0].ProtocolType
        Assert-AreEqual $appRule3Port1 $appRule3.Protocols[0].Port

        Assert-AreEqual 1 $appRule3.TargetFqdns.Count
        Assert-AreEqual $appRule3Fqdn1 $appRule3.TargetFqdns[0]

        
        $appRc2 = $getAzureFirewall.GetApplicationRuleCollectionByName($appRc2Name)

        Assert-AreEqual $appRc2Name $appRc2.Name
        Assert-AreEqual $appRc2Priority $appRc2.Priority
        Assert-AreEqual $appRc2ActionType $appRc2.Action.Type

        
        $appRule = $appRc2.GetRuleByName($appRule1Name)

        Assert-AreEqual $appRule1Name $appRule.Name
        Assert-AreEqual $appRule1Desc $appRule.Description

        Assert-AreEqual 1 $appRule.SourceAddresses.Count
        Assert-AreEqual $appRule1SourceAddress1 $appRule.SourceAddresses[0]

        Assert-AreEqual 2 $appRule.Protocols.Count 
        Assert-AreEqual $appRule1ProtocolType1 $appRule.Protocols[0].ProtocolType
        Assert-AreEqual $appRule1ProtocolType2 $appRule.Protocols[1].ProtocolType
        Assert-AreEqual $appRule1Port1 $appRule.Protocols[0].Port
        Assert-AreEqual $appRule1Port2 $appRule.Protocols[1].Port
        
        Assert-AreEqual 2 $appRule.TargetFqdns.Count 
        Assert-AreEqual $appRule1Fqdn1 $appRule.TargetFqdns[0]
        Assert-AreEqual $appRule1Fqdn2 $appRule.TargetFqdns[1]

        
        $natRc = $getAzureFirewall.GetNatRuleCollectionByName($natRcName)
        $natRule = $natRc.GetRuleByName($natRule1Name)

        Assert-AreEqual $natRcName $natRc.Name
        Assert-AreEqual $natRcPriority $natRc.Priority

        Assert-AreEqual $natRule1Name $natRule.Name
        Assert-AreEqual $natRule1Desc $natRule.Description

        Assert-AreEqual 2 $natRule.SourceAddresses.Count 
        Assert-AreEqual $natRule1SourceAddress1 $natRule.SourceAddresses[0]
        Assert-AreEqual $natRule1SourceAddress2 $natRule.SourceAddresses[1]

        Assert-AreEqual 1 $natRule.DestinationAddresses.Count 
        Assert-AreEqual $publicip.IpAddress $natRule.DestinationAddresses[0]

        Assert-AreEqual 2 $natRule.Protocols.Count 
        Assert-AreEqual $natRule1Protocol1 $natRule.Protocols[0]
        Assert-AreEqual $natRule1Protocol2 $natRule.Protocols[1]

        Assert-AreEqual 1 $natRule.DestinationPorts.Count 
        Assert-AreEqual $natRule1DestinationPort1 $natRule.DestinationPorts[0]

        Assert-AreEqual $natRule1TranslatedAddress $natRule.TranslatedAddress
        Assert-AreEqual $natRule1TranslatedPort $natRule.TranslatedPort

        $natRule2 = $natRc.GetRuleByName($natRule2Name)

        Assert-AreEqual $natRule2Name $natRule2.Name
        Assert-AreEqual $natRule2Desc $natRule2.Description

        Assert-AreEqual 2 $natRule2.SourceAddresses.Count 
        Assert-AreEqual $natRule2SourceAddress1 $natRule2.SourceAddresses[0]
        Assert-AreEqual $natRule2SourceAddress2 $natRule2.SourceAddresses[1]

        Assert-AreEqual 1 $natRule2.DestinationAddresses.Count 
        Assert-AreEqual $publicip.IpAddress $natRule2.DestinationAddresses[0]

        Assert-AreEqual 2 $natRule2.Protocols.Count 
        Assert-AreEqual $natRule2Protocol1 $natRule2.Protocols[0]
        Assert-AreEqual $natRule2Protocol2 $natRule2.Protocols[1]

        Assert-AreEqual 1 $natRule2.DestinationPorts.Count 
        Assert-AreEqual $natRule2DestinationPort1 $natRule2.DestinationPorts[0]

        Assert-AreEqual $natRule2TranslatedFqdn $natRule2.TranslatedFqdn
        Assert-AreEqual $natRule2TranslatedPort $natRule2.TranslatedPort

        
        $networkRc = $getAzureFirewall.GetNetworkRuleCollectionByName($networkRcName)
        $networkRule = $networkRc.GetRuleByName($networkRule1Name)

        Assert-AreEqual $networkRcName $networkRc.Name
        Assert-AreEqual $networkRcPriority $networkRc.Priority
        Assert-AreEqual $networkRcActionType $networkRc.Action.Type

        Assert-AreEqual $networkRule1Name $networkRule.Name
        Assert-AreEqual $networkRule1Desc $networkRule.Description

        Assert-AreEqual 2 $networkRule.SourceAddresses.Count 
        Assert-AreEqual $networkRule1SourceAddress1 $networkRule.SourceAddresses[0]
        Assert-AreEqual $networkRule1SourceAddress2 $networkRule.SourceAddresses[1]

        Assert-AreEqual 1 $networkRule.DestinationAddresses.Count 
        Assert-AreEqual $networkRule1DestinationAddress1 $networkRule.DestinationAddresses[0]

        Assert-AreEqual 3 $networkRule.Protocols.Count
        Assert-AreEqual $networkRule1Protocol1 $networkRule.Protocols[0]
        Assert-AreEqual $networkRule1Protocol2 $networkRule.Protocols[1]
        Assert-AreEqual $networkRule1Protocol3 $networkRule.Protocols[2]

        Assert-AreEqual 1 $networkRule.DestinationPorts.Count 
        Assert-AreEqual $networkRule1DestinationPort1 $networkRule.DestinationPorts[0]

        $networkRule2 = $networkRc.GetRuleByName($networkRule2Name)

        Assert-AreEqual $networkRule2Name $networkRule2.Name
        Assert-AreEqual $networkRule2Desc $networkRule2.Description

        Assert-AreEqual 2 $networkRule2.SourceAddresses.Count 
        Assert-AreEqual $networkRule2SourceAddress1 $networkRule2.SourceAddresses[0]
        Assert-AreEqual $networkRule2SourceAddress2 $networkRule2.SourceAddresses[1]

        Assert-AreEqual 1 $networkRule2.DestinationFqdns.Count 
        Assert-AreEqual $networkRule2DestinationFqdn1 $networkRule2.DestinationFqdns[0]

        Assert-AreEqual 3 $networkRule2.Protocols.Count
        Assert-AreEqual $networkRule2Protocol1 $networkRule2.Protocols[0]
        Assert-AreEqual $networkRule2Protocol2 $networkRule2.Protocols[1]
        Assert-AreEqual $networkRule2Protocol3 $networkRule2.Protocols[2]

        Assert-AreEqual 1 $networkRule2.DestinationPorts.Count 
        Assert-AreEqual $networkRule2DestinationPort1 $networkRule2.DestinationPorts[0]

        
        $delete = Remove-AzFirewall -ResourceGroupName $rgname -name $azureFirewallName -PassThru -Force
        Assert-AreEqual true $delete

        
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

        $list = Get-AzFirewall -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AzureFirewallCRUDWithZones {
    
    $rgname = Get-ResourceGroupName
    $azureFirewallName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/AzureFirewalls"
    $location = Get-ProviderLocation $resourceTypeParent "eastus2euap"

    $vnetName = Get-ResourceName
    $subnetName = "AzureFirewallSubnet"
    $publicIpName = Get-ResourceName

    
    $appRcName = "appRc"
    $appRcPriority = 100
    $appRcActionType = "Allow"

    
    $appRc2Name = "appRc2"
    $appRc2Priority = 101
    $appRc2ActionType = "Deny"

    
    $appRule1Name = "appRule"
    $appRule1Desc = "desc1"
    $appRule1Fqdn1 = "*google.com"
    $appRule1Fqdn2 = "*microsoft.com"
    $appRule1Protocol1 = "http:80"
    $appRule1Port1 = 80
    $appRule1ProtocolType1 = "http"
    $appRule1Protocol2 = "https:443"
    $appRule1Port2 = 443
    $appRule1ProtocolType2 = "https"
    $appRule1SourceAddress1 = "10.0.0.0"

    
    $appRule2Name = "appRule2"
    $appRule2Fqdn1 = "*bing.com"
    $appRule2Protocol1 = "http:8080"
    $appRule2Port1 = 8080
    $appRule2ProtocolType1 = "http"

    
    $networkRcName = "networkRc"
    $networkRcPriority = 200
    $networkRcActionType = "Deny"

    
    $networkRule1Name = "networkRule"
    $networkRule1Desc = "desc1"
    $networkRule1SourceAddress1 = "10.0.0.0"
    $networkRule1SourceAddress2 = "111.1.0.0/24"
    $networkRule1DestinationAddress1 = "*"
    $networkRule1Protocol1 = "UDP"
    $networkRule1Protocol2 = "TCP"
    $networkRule1Protocol3 = "ICMP"
    $networkRule1DestinationPort1 = "90"

    
    $natRcName = "natRc"
    $natRcPriority = 200

    
    $natRule1Name = "natRule"
    $natRule1Desc = "desc1"
    $natRule1SourceAddress1 = "10.0.0.0"
    $natRule1SourceAddress2 = "111.1.0.0/24"
    $natRule1DestinationAddress1 = "1.2.3.4"
    $natRule1Protocol1 = "UDP"
    $natRule1Protocol2 = "TCP"
    $natRule1DestinationPort1 = "90"
    $natRule1TranslatedAddress = "10.1.2.3"
    $natRule1TranslatedPort = "91"

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard

        
        $azureFirewall = New-AzFirewall –Name $azureFirewallName -ResourceGroupName $rgname -Location $location -VirtualNetworkName $vnetName -PublicIpName $publicIpName -Zone 1, 2, 3

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual (Normalize-Location $location) $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag
        Assert-AreEqual "Alert" $getAzureFirewall.ThreatIntelMode
        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual 0 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NetworkRuleCollections).Count

        
        $list = Get-AzFirewall -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $list[0].Name $getAzureFirewall.Name
        Assert-AreEqual $list[0].Location $getAzureFirewall.Location
        Assert-AreEqual $list[0].Etag $getAzureFirewall.Etag
        Assert-AreEqual @($list[0].IpConfigurations).Count @($getAzureFirewall.IpConfigurations).Count
        Assert-AreEqual @($list[0].IpConfigurations)[0].Subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual @($list[0].IpConfigurations)[0].PublicIpAddress.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual @($list[0].IpConfigurations)[0].PrivateIpAddress $getAzureFirewall.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual @($list[0].ApplicationRuleCollections).Count @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual @($list[0].NatRuleCollections).Count @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual @($list[0].NetworkRuleCollections).Count @($getAzureFirewall.NetworkRuleCollections).Count

        
        $listAll = Get-AzFirewall
        Assert-NotNull $listAll

        $listAll = Get-AzFirewall -Name "*"
        Assert-NotNull $listAll

        $listAll = Get-AzFirewall -ResourceGroupName "*"
        Assert-NotNull $listAll

        $listAll = Get-AzFirewall -ResourceGroupName "*" -Name "*"
        Assert-NotNull $listAll

        
        $appRule = New-AzFirewallApplicationRule -Name $appRule1Name -Description $appRule1Desc -Protocol $appRule1Protocol1, $appRule1Protocol2 -TargetFqdn $appRule1Fqdn1, $appRule1Fqdn2 -SourceAddress $appRule1SourceAddress1

        $appRule2 = New-AzFirewallApplicationRule -Name $appRule2Name -Protocol $appRule2Protocol1 -TargetFqdn $appRule2Fqdn1

        
        $appRc = New-AzFirewallApplicationRuleCollection -Name $appRcName -Priority $appRcPriority -Rule $appRule -ActionType $appRcActionType

        
        $appRc.AddRule($appRule2)

        
        $appRc2 = New-AzFirewallApplicationRuleCollection -Name $appRc2Name -Priority $appRc2Priority -Rule $appRule -ActionType $appRc2ActionType

        
        $networkRule = New-AzFirewallNetworkRule -Name $networkRule1Name -Description $networkRule1Desc -Protocol $networkRule1Protocol1, $networkRule1Protocol2 -SourceAddress $networkRule1SourceAddress1, $networkRule1SourceAddress2 -DestinationAddress $networkRule1DestinationAddress1 -DestinationPort $networkRule1DestinationPort1
        $networkRule.AddProtocol($networkRule1Protocol3)

        
        Assert-ThrowsContains { $networkRule.AddProtocol() } "Cannot find an overload"
        Assert-ThrowsContains { $networkRule.AddProtocol($null) } "A protocol must be provided"
        Assert-ThrowsContains { $networkRule.AddProtocol("ABCD") } "Invalid protocol"

        
        $netRc = New-AzFirewallNetworkRuleCollection -Name $networkRcName -Priority $networkRcPriority -Rule $networkRule -ActionType $networkRcActionType

        
        $natRule = New-AzFirewallNatRule -Name $natRule1Name -Description $natRule1Desc -Protocol $natRule1Protocol1 -SourceAddress $natRule1SourceAddress1, $natRule1SourceAddress2 -DestinationAddress $publicip.IpAddress -DestinationPort $natRule1DestinationPort1 -TranslatedAddress $natRule1TranslatedAddress -TranslatedPort $natRule1TranslatedPort
        $natRule.AddProtocol($natRule1Protocol2)

        
        Assert-ThrowsContains { $natRule.AddProtocol() } "Cannot find an overload"
        Assert-ThrowsContains { $natRule.AddProtocol($null) } "A protocol must be provided"
        Assert-ThrowsContains { $natRule.AddProtocol("ABCD") } "Invalid protocol"
        
        Assert-ThrowsContains {
            New-AzFirewallNatRule -Name $natRule1Name -Protocol $natRule1Protocol1, "ICMP" -SourceAddress $natRule1SourceAddress1 -DestinationAddress $natRule1DestinationAddress1 -DestinationPort $natRule1DestinationPort1 -TranslatedAddress $natRule1TranslatedAddress -TranslatedPort $natRule1TranslatedPort
        } "The argument `"ICMP`" does not belong to the set"
        Assert-ThrowsContains { $natRule.AddProtocol("ICMP") } "Invalid protocol"

        
        $natRc = New-AzFirewallNatRuleCollection -Name $natRcName -Priority $natRcPriority -Rule $natRule

        
        $azureFirewall.AddApplicationRuleCollection($appRc)
        $azureFirewall.AddApplicationRuleCollection($appRc2)

        
        $azureFirewall.AddNatRuleCollection($natRc)

        
        $azureFirewall.AddNetworkRuleCollection($netRc)

        
        $azureFirewall.ThreatIntelMode = "Deny"

        
        Set-AzFirewall -AzureFirewall $azureFirewall

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgName
        $azureFirewallIpConfiguration = $getAzureFirewall.IpConfigurations

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag
        Assert-AreEqual "Deny" $getAzureFirewall.ThreatIntelMode

        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $azureFirewallIpConfiguration[0].Subnet.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PublicIpAddress.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PrivateIpAddress

        
        Assert-AreEqual 2 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 2 @($getAzureFirewall.ApplicationRuleCollections[0].Rules).Count
        Assert-AreEqual 1 @($getAzureFirewall.ApplicationRuleCollections[1].Rules).Count

        Assert-AreEqual 1 @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual 1 @($getAzureFirewall.NatRuleCollections[0].Rules).Count

        Assert-AreEqual 1 @($getAzureFirewall.NetworkRuleCollections).Count
        Assert-AreEqual 1 @($getAzureFirewall.NetworkRuleCollections[0].Rules).Count

        $appRc = $getAzureFirewall.GetApplicationRuleCollectionByName($appRcName)
        $appRule = $appRc.GetRuleByName($appRule1Name)
        $appRule2 = $appRc.GetRuleByName($appRule2Name)

        
        Assert-AreEqual $appRcName $appRc.Name
        Assert-AreEqual $appRcPriority $appRc.Priority
        Assert-AreEqual $appRcActionType $appRc.Action.Type

        
        Assert-AreEqual $appRule1Name $appRule.Name
        Assert-AreEqual $appRule1Desc $appRule.Description

        Assert-AreEqual 1 $appRule.SourceAddresses.Count
        Assert-AreEqual $appRule1SourceAddress1 $appRule.SourceAddresses[0]

        Assert-AreEqual 2 $appRule.Protocols.Count 
        Assert-AreEqual $appRule1ProtocolType1 $appRule.Protocols[0].ProtocolType
        Assert-AreEqual $appRule1ProtocolType2 $appRule.Protocols[1].ProtocolType
        Assert-AreEqual $appRule1Port1 $appRule.Protocols[0].Port
        Assert-AreEqual $appRule1Port2 $appRule.Protocols[1].Port

        Assert-AreEqual 2 $appRule.TargetFqdns.Count 
        Assert-AreEqual $appRule1Fqdn1 $appRule.TargetFqdns[0]
        Assert-AreEqual $appRule1Fqdn2 $appRule.TargetFqdns[1]

        
        Assert-AreEqual $appRule2Name $appRule2.Name
        Assert-Null $appRule2.Description

        Assert-AreEqual 0 $appRule2.SourceAddresses.Count

        Assert-AreEqual 1 $appRule2.Protocols.Count 
        Assert-AreEqual $appRule2ProtocolType1 $appRule2.Protocols[0].ProtocolType
        Assert-AreEqual $appRule2Port1 $appRule2.Protocols[0].Port

        Assert-AreEqual 1 $appRule2.TargetFqdns.Count 
        Assert-AreEqual $appRule2Fqdn1 $appRule2.TargetFqdns[0]

        
        $appRc2 = $getAzureFirewall.GetApplicationRuleCollectionByName($appRc2Name)

        Assert-AreEqual $appRc2Name $appRc2.Name
        Assert-AreEqual $appRc2Priority $appRc2.Priority
        Assert-AreEqual $appRc2ActionType $appRc2.Action.Type

        
        $appRule = $appRc2.GetRuleByName($appRule1Name)

        Assert-AreEqual $appRule1Name $appRule.Name
        Assert-AreEqual $appRule1Desc $appRule.Description

        Assert-AreEqual 1 $appRule.SourceAddresses.Count
        Assert-AreEqual $appRule1SourceAddress1 $appRule.SourceAddresses[0]

        Assert-AreEqual 2 $appRule.Protocols.Count 
        Assert-AreEqual $appRule1ProtocolType1 $appRule.Protocols[0].ProtocolType
        Assert-AreEqual $appRule1ProtocolType2 $appRule.Protocols[1].ProtocolType
        Assert-AreEqual $appRule1Port1 $appRule.Protocols[0].Port
        Assert-AreEqual $appRule1Port2 $appRule.Protocols[1].Port

        Assert-AreEqual 2 $appRule.TargetFqdns.Count 
        Assert-AreEqual $appRule1Fqdn1 $appRule.TargetFqdns[0]
        Assert-AreEqual $appRule1Fqdn2 $appRule.TargetFqdns[1]

        
        $natRc = $getAzureFirewall.GetNatRuleCollectionByName($natRcName)
        $natRule = $natRc.GetRuleByName($natRule1Name)

        Assert-AreEqual $natRcName $natRc.Name
        Assert-AreEqual $natRcPriority $natRc.Priority

        Assert-AreEqual $natRule1Name $natRule.Name
        Assert-AreEqual $natRule1Desc $natRule.Description

        Assert-AreEqual 2 $natRule.SourceAddresses.Count 
        Assert-AreEqual $natRule1SourceAddress1 $natRule.SourceAddresses[0]
        Assert-AreEqual $natRule1SourceAddress2 $natRule.SourceAddresses[1]

        Assert-AreEqual 1 $natRule.DestinationAddresses.Count 
        Assert-AreEqual $publicip.IpAddress $natRule.DestinationAddresses[0]

        Assert-AreEqual 2 $natRule.Protocols.Count 
        Assert-AreEqual $natRule1Protocol1 $natRule.Protocols[0]
        Assert-AreEqual $natRule1Protocol2 $natRule.Protocols[1]

        Assert-AreEqual 1 $natRule.DestinationPorts.Count 
        Assert-AreEqual $natRule1DestinationPort1 $natRule.DestinationPorts[0]

        Assert-AreEqual $natRule1TranslatedAddress $natRule.TranslatedAddress
        Assert-AreEqual $natRule1TranslatedPort $natRule.TranslatedPort

        
        $networkRc = $getAzureFirewall.GetNetworkRuleCollectionByName($networkRcName)
        $networkRule = $networkRc.GetRuleByName($networkRule1Name)

        Assert-AreEqual $networkRcName $networkRc.Name
        Assert-AreEqual $networkRcPriority $networkRc.Priority
        Assert-AreEqual $networkRcActionType $networkRc.Action.Type

        Assert-AreEqual $networkRule1Name $networkRule.Name
        Assert-AreEqual $networkRule1Desc $networkRule.Description

        Assert-AreEqual 2 $networkRule.SourceAddresses.Count 
        Assert-AreEqual $networkRule1SourceAddress1 $networkRule.SourceAddresses[0]
        Assert-AreEqual $networkRule1SourceAddress2 $networkRule.SourceAddresses[1]

        Assert-AreEqual 1 $networkRule.DestinationAddresses.Count 
        Assert-AreEqual $networkRule1DestinationAddress1 $networkRule.DestinationAddresses[0]

        Assert-AreEqual 3 $networkRule.Protocols.Count
        Assert-AreEqual $networkRule1Protocol1 $networkRule.Protocols[0]
        Assert-AreEqual $networkRule1Protocol2 $networkRule.Protocols[1]
        Assert-AreEqual $networkRule1Protocol3 $networkRule.Protocols[2]

        Assert-AreEqual 1 $networkRule.DestinationPorts.Count 
        Assert-AreEqual $networkRule1DestinationPort1 $networkRule.DestinationPorts[0]

        
        Assert-AreEqual 3 @($getAzureFirewall.Zones).Count

        
        $delete = Remove-AzFirewall -ResourceGroupName $rgname -name $azureFirewallName -PassThru -Force
        Assert-AreEqual true $delete

        
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

        $list = Get-AzFirewall -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AzureFirewallPIPAndVNETObjectTypeParams {
    
    $rgname = Get-ResourceGroupName
    $azureFirewallName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/AzureFirewalls"
    $location = Get-ProviderLocation $resourceTypeParent "eastus2euap"

    $vnetName = Get-ResourceName
    $subnetName = "AzureFirewallSubnet"
    $publicIp1Name = Get-ResourceName
    $publicIp2Name = Get-ResourceName

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

        
        $publicip1 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp1Name -location $location -AllocationMethod Static -Sku Standard
        $publicip2 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp2Name -location $location -AllocationMethod Static -Sku Standard

        
        $azureFirewall = New-AzFirewall –Name $azureFirewallName -ResourceGroupName $rgname -Location $location -VirtualNetwork $vnet -PublicIpAddress $publicip1

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual (Normalize-Location $location) $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag
        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PrivateIpAddress
        Assert-AreEqual $subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip1.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id

        
        Assert-ThrowsContains { $getAzureFirewall.AddPublicIpAddress() } "Cannot find an overload"
        Assert-ThrowsContains { $getAzureFirewall.AddPublicIpAddress($null) } "Public IP Address cannot be null"
        Assert-ThrowsContains { $getAzureFirewall.AddPublicIpAddress("ABCD") } "Cannot convert argument"
        Assert-ThrowsContains { $getAzureFirewall.AddPublicIpAddress($publicip1) } "already attached to firewall"

        
        Assert-ThrowsContains { $getAzureFirewall.RemovePublicIpAddress() } "Cannot find an overload"
        Assert-ThrowsContains { $getAzureFirewall.RemovePublicIpAddress($null) } "Public IP Address cannot be null"
        Assert-ThrowsContains { $getAzureFirewall.RemovePublicIpAddress("ABCD") } "Cannot convert argument"
        Assert-ThrowsContains { $getAzureFirewall.RemovePublicIpAddress($publicip2) } "not attached to firewall"

        
        $getAzureFirewall.AddPublicIpAddress($publicip2)

        
        Set-AzFirewall -AzureFirewall $getAzureFirewall

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgName
        $azureFirewallIpConfiguration = $getAzureFirewall.IpConfigurations

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag

        Assert-AreEqual 2 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $azureFirewallIpConfiguration[0].Subnet.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PublicIpAddress.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PrivateIpAddress
        Assert-AreEqual $subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip1.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $publicip2.Id $getAzureFirewall.IpConfigurations[1].PublicIpAddress.Id

        
        $getAzureFirewall.RemovePublicIpAddress($publicip2)

        
        Set-AzFirewall -AzureFirewall $getAzureFirewall

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgName
        $azureFirewallIpConfiguration = $getAzureFirewall.IpConfigurations

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag

        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $azureFirewallIpConfiguration[0].Subnet.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PublicIpAddress.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PrivateIpAddress
        Assert-AreEqual $subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip1.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id

        
        $delete = Remove-AzFirewall -ResourceGroupName $rgname -name $azureFirewallName -PassThru -Force
        Assert-AreEqual true $delete

        
        $azureFirewall = New-AzFirewall –Name $azureFirewallName -ResourceGroupName $rgname -Location $location -VirtualNetwork $vnet -PublicIpAddress @($publicip1, $publicip2)

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname
        $azureFirewallIpConfiguration = $getAzureFirewall.IpConfigurations

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag

        Assert-AreEqual 2 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $azureFirewallIpConfiguration[0].Subnet.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PublicIpAddress.Id
        Assert-NotNull $azureFirewallIpConfiguration[1].PublicIpAddress.Id
        Assert-NotNull $azureFirewallIpConfiguration[0].PrivateIpAddress
        Assert-AreEqual $subnet.Id $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-AreEqual $publicip1.Id $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-AreEqual $publicip2.Id $getAzureFirewall.IpConfigurations[1].PublicIpAddress.Id

        
        $delete = Remove-AzFirewall -ResourceGroupName $rgname -name $azureFirewallName -PassThru -Force
        Assert-AreEqual true $delete

        
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

        $list = Get-AzFirewall -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AzureFirewallAllocateAndDeallocate {
    
    $rgname = Get-ResourceGroupName
    $azureFirewallName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/AzureFirewalls"
    $location = Get-ProviderLocation $resourceTypeParent "eastus2euap"

    $vnetName = Get-ResourceName
    $subnetName = "AzureFirewallSubnet"
    $publicIpName = Get-ResourceName

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard

        
        $azureFirewall = New-AzFirewall –Name $azureFirewallName -ResourceGroupName $rgname -Location $location

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag
        
        Assert-AreEqual 0 @($getAzureFirewall.IpConfigurations).Count
        
        
        Assert-AreEqual 0 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NetworkRuleCollections).Count

        
        $getAzureFirewall.Allocate($vnet, $publicip)

        
        Set-AzFirewall -AzureFirewall $getAzureFirewall

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag

        
        Assert-AreEqual 1 @($getAzureFirewall.IpConfigurations).Count
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].Subnet.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PublicIpAddress.Id
        Assert-NotNull $getAzureFirewall.IpConfigurations[0].PrivateIpAddress
        
        
        Assert-AreEqual 0 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NetworkRuleCollections).Count
        
        
        $getAzureFirewall.Deallocate()
        $getAzureFirewall | Set-AzFirewall

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual $location $getAzureFirewall.Location
        Assert-NotNull $getAzureFirewall.Etag

        
        Assert-AreEqual 0 @($getAzureFirewall.IpConfigurations).Count

        
        Assert-AreEqual 0 @($getAzureFirewall.ApplicationRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NatRuleCollections).Count
        Assert-AreEqual 0 @($getAzureFirewall.NetworkRuleCollections).Count

        
        $delete = Remove-AzFirewall -ResourceGroupName $rgname -name $azureFirewallName -PassThru -Force
        Assert-AreEqual true $delete

        
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $delete

        $list = Get-AzFirewall -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AzureFirewallVirtualHubCRUD {
    
    $rgname = Get-ResourceGroupName
    $azureFirewallName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/AzureFirewalls"
    $policyLocation = "westcentralus"
    $location = Get-ProviderLocation $resourceTypeParent
    $azureFirewallPolicyName = Get-ResourceName
    $sku = "AZFW_Hub"
    $tier = "Standard"

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }
        
        
        $azureFirewallPolicy = New-AzFirewallPolicy -Name $azureFirewallPolicyName -ResourceGroupName $rgname -Location $policyLocation

        
        $getazureFirewallPolicy = Get-AzFirewallPolicy -Name $azureFirewallPolicyName -ResourceGroupName $rgname

        
        Assert-NotNull $azureFirewallPolicy
        Assert-NotNull $getazureFirewallPolicy.Id

        $azureFirewallPolicyId = $getazureFirewallPolicy.Id

        New-AzFirewall –Name $azureFirewallName -ResourceGroupName $rgname -Location $location -Sku $sku -FirewallPolicyId $azureFirewallPolicyId

        
        $getAzureFirewall = Get-AzFirewall -name $azureFirewallName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewall.ResourceGroupName
        Assert-AreEqual $azureFirewallName $getAzureFirewall.Name
        Assert-NotNull $getAzureFirewall.Location
        Assert-AreEqual (Normalize-Location $location) $getAzureFirewall.Location
        Assert-NotNull $sku $getAzureFirewall.Sku
        Assert-AreEqual $sku $getAzureFirewall.Sku.Name
        Assert-AreEqual $tier $getAzureFirewall.Sku.Tier
        Assert-NotNull $getAzureFirewall.FirewallPolicy
        Assert-AreEqual $azureFirewallPolicyId $getAzureFirewall.FirewallPolicy.Id
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-AzureFirewallThreatIntelWhitelistCRUD {
    $rgname = Get-ResourceGroupName
    $azureFirewallName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/AzureFirewalls"
    $location = Get-ProviderLocation $resourceTypeParent "eastus2euap"

    $vnetName = Get-ResourceName
    $subnetName = "AzureFirewallSubnet"
    $publicIpName = Get-ResourceName

    $threatIntelWhitelist1 = New-AzFirewallThreatIntelWhitelist -FQDN @("*.microsoft.com", "microsoft.com") -IpAddress @("8.8.8.8", "1.1.1.1")
    $threatIntelWhitelist2 = New-AzFirewallThreatIntelWhitelist -IpAddress @("  2.2.2.2  ","  3.3.3.3  ") -FQDN @("  bing.com  ",  "yammer.com  ")

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -Sku Standard

        
        $azureFirewall = New-AzFirewall -Name $azureFirewallName -ResourceGroupName $rgname -Location $location -ThreatIntelWhitelist $threatIntelWhitelist1

        
        $getAzureFirewall = Get-AzFirewall -Name $azureFirewallName -ResourceGroupName $rgname
        Assert-AreEqualArray $threatIntelWhitelist1.FQDNs $getAzureFirewall.ThreatIntelWhitelist.FQDNs
        Assert-AreEqualArray $threatIntelWhitelist1.IpAddresses $getAzureFirewall.ThreatIntelWhitelist.IpAddresses

        
        $azureFirewall.ThreatIntelWhitelist = $threatIntelWhitelist2
        Set-AzFirewall -AzureFirewall $azureFirewall
        $getAzureFirewall = Get-AzFirewall -Name $azureFirewallName -ResourceGroupName $rgname
        Assert-AreEqualArray $threatIntelWhitelist2.FQDNs $getAzureFirewall.ThreatIntelWhitelist.FQDNs
        Assert-AreEqualArray $threatIntelWhitelist2.IpAddresses $getAzureFirewall.ThreatIntelWhitelist.IpAddresses
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}
