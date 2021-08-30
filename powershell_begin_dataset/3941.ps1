














function Test-VirtualNetworkCRUD
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $job = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -DnsServer 8.8.8.8 -Subnet $subnet -AsJob
        $job | Wait-Job
        $actual = $job | Receive-Job
        $expected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        
        Assert-AreEqual $expected.ResourceGroupName $rgname    
        Assert-AreEqual $expected.Name $actual.Name    
        Assert-AreEqual $expected.Location $actual.Location
        Assert-AreEqual "Succeeded" $expected.ProvisioningState
        Assert-NotNull $expected.ResourceGuid
        Assert-AreEqual "10.0.0.0/16" $expected.AddressSpace.AddressPrefixes[0]
        Assert-AreEqual 1 @($expected.DhcpOptions.DnsServers).Count
        Assert-AreEqual "8.8.8.8" $expected.DhcpOptions.DnsServers[0]
        Assert-AreEqual 1 @($expected.Subnets).Count
        Assert-AreEqual $subnetName $expected.Subnets[0].Name
        Assert-AreEqual "10.0.1.0/24" $expected.Subnets[0].AddressPrefix
        
        
        $list = Get-AzVirtualNetwork -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName    
        Assert-AreEqual $list[0].Name $actual.Name    
        Assert-AreEqual $list[0].Location $actual.Location
        Assert-AreEqual "Succeeded" $list[0].ProvisioningState
        Assert-AreEqual "10.0.0.0/16" $list[0].AddressSpace.AddressPrefixes[0]
        Assert-AreEqual 1 @($list[0].Subnets).Count
        Assert-AreEqual $subnetName $list[0].Subnets[0].Name
        Assert-AreEqual "10.0.1.0/24" $list[0].Subnets[0].AddressPrefix
        Assert-AreEqual $expected.Etag $list[0].Etag

        $listAll = Get-AzVirtualNetwork
        Assert-NotNull $listAll

        $listAll = Get-AzVirtualNetwork -ResourceGroupName "*"
        Assert-NotNull $listAll

        $listAll = Get-AzVirtualNetwork -Name "*"
        Assert-NotNull $listAll

        $listAll = Get-AzVirtualNetwork -ResourceGroupName "*" -Name "*"
        Assert-NotNull $listAll

        
        $testResponse1 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Test-AzPrivateIPAddressAvailability -IPAddress "10.0.1.10"
        Assert-AreEqual true $testResponse1.Available

        
        $testResponse2 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Test-AzPrivateIPAddressAvailability -IPAddress "10.0.1.3"
        Assert-AreEqual false $testResponse2.Available
        Assert-AreEqual 5 @($testResponse2.AvailableIpAddresses).Count

        
        $testResponse1 = Test-AzPrivateIPAddressAvailability -ResourceGroupName $rgname -VirtualNetworkName $vnetName -IPAddress "10.0.1.10"
        Assert-AreEqual true $testResponse1.Available

        
        $testResponse2 = Test-AzPrivateIPAddressAvailability -ResourceGroupName $rgname -VirtualNetworkName $vnetName -IPAddress "10.0.1.3"
        Assert-AreEqual false $testResponse2.Available
        Assert-AreEqual 5 @($testResponse2.AvailableIpAddresses).Count
        
        
        $job = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force -AsJob
        $job | Wait-Job
        $delete = $job | Receive-Job
        Assert-AreEqual true $delete
                
        $list = Get-AzVirtualNetwork -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-subnetCRUD
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $subnet2Name = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        
        
        $vnet | Add-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.2.0/24
        
        
        $vnet | Set-AzVirtualNetwork
        
        
        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname

        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual $subnetName $vnetExpected.Subnets[0].Name
        Assert-AreEqual $subnet2Name $vnetExpected.Subnets[1].Name
        Assert-AreEqual "10.0.2.0/24" $vnetExpected.Subnets[1].AddressPrefix
        
        
        $job = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Set-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.3.0/24 | Set-AzVirtualNetwork -AsJob
        $job | Wait-Job

        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual $subnetName $vnetExpected.Subnets[0].Name
        Assert-AreEqual $subnet2Name $vnetExpected.Subnets[1].Name
        Assert-AreEqual "10.0.3.0/24" $vnetExpected.Subnets[1].AddressPrefix

        
        $subnet2 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name
        $subnetAll = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig
        $subnet2ById = Get-AzVirtualNetworkSubnetConfig -ResourceId $subnet2.Id

        Assert-AreEqual 2 @($subnetAll).Count
        Assert-AreEqual $subnetName $subnetAll[0].Name
        Assert-AreEqual $subnet2Name $subnetAll[1].Name
        Assert-AreEqual $subnet2Name $subnet2.Name
        Assert-AreEqual $subnet2Name $subnet2ById.Name

        
        try
        {
            $subnetNotExists = $vnetExpected | Get-AzVirtualNetworkSubnetConfig -Name "Subnet-DoesNotExist"
        }
        catch
        {
            if ($_.Exception.GetType() -ne [System.ArgumentException])
            {
                throw;
            }
        }

        
        Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Remove-AzVirtualNetworkSubnetConfig -Name $subnet2Name | Set-AzVirtualNetwork
        
        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual 1 @($vnetExpected.Subnets).Count
        Assert-AreEqual $subnetName $vnetExpected.Subnets[0].Name        
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-bgpCommunitiesCRUD
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent "eastus2euap"

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }

        
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -BgpCommunity 12076:61234

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual "12076:61234" $vnet.BgpCommunities.VirtualNetworkCommunity

        
        $vnet.BgpCommunities.VirtualNetworkCommunity = "12076:64321"
        $vnet | Set-AzVirtualNetwork

        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual "12076:64321" $vnet.BgpCommunities.VirtualNetworkCommunity
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-subnetDelegationCRUD
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $subnet2Name = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $delegation = New-AzDelegation -Name "sqlDelegation" -ServiceName "Microsoft.Sql/managedInstances"

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -delegation $delegation
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        
        
        $vnet | Add-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.2.0/24
        
        
        $vnet | Set-AzVirtualNetwork
        
        
        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname

        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual 1 @($vnetExpected.Subnets[0].Delegations).Count
        Assert-AreEqual 0 @($vnetExpected.Subnets[1].Delegations).Count
        
        
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Set-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.2.0/24
		
		
		Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name -VirtualNetwork $vnet | Add-AzDelegation -Name "bareMetalDelegation" -ServiceName "Microsoft.Netapp/volumes"
		Set-AzVirtualNetwork -VirtualNetwork $vnet

        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual 1 @($vnetExpected.Subnets[0].Delegations).Count
		Assert-AreEqual "Microsoft.Sql/managedInstances" $vnetExpected.Subnets[0].Delegations[0].ServiceName
        Assert-AreEqual 1 @($vnetExpected.Subnets[1].Delegations).Count
		Assert-AreEqual "Microsoft.Netapp/volumes" $vnetExpected.Subnets[1].Delegations[0].ServiceName

        
        $subnet2 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name
		Assert-AreEqual 1 @($subnet2.Delegations).Count
        $subnetAll = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig

        Assert-AreEqual 2 @($subnetAll).Count

		
		Foreach ($sub in $subnetAll)
		{
			$del = Get-AzDelegation -Subnet $sub
			Assert-NotNull $del
		}

        
        $vnetToEdit = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
		$subnetWithoutDelegation = Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name -VirtualNetwork $vnet | Remove-AzDelegation -Name "bareMetalDelegation"
		$vnetToEdit.Subnets[1] = $subnetWithoutDelegation
		$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnetToEdit
        
        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual 1 @($vnetExpected.Subnets[0].Delegations).Count
		Assert-AreEqual 0 @($vnetExpected.Subnets[1].Delegations).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-multiPrefixSubnetCRUD
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $subnet2Name = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/28,10.0.2.0/28
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        
        
        $vnet | Add-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.3.0/28,10.0.4.0/28
        
        
        $vnet | Set-AzVirtualNetwork
        
        
        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname

        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual $subnetName $vnetExpected.Subnets[0].Name
        Assert-AreEqual $subnet2Name $vnetExpected.Subnets[1].Name
        Assert-AreEqual "10.0.1.0/28 10.0.2.0/28" $vnetExpected.Subnets[0].AddressPrefix
        Assert-AreEqual "10.0.3.0/28 10.0.4.0/28" $vnetExpected.Subnets[1].AddressPrefix
        
        
        $job = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Set-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.5.0/28,10.0.6.0/28 | Set-AzVirtualNetwork -AsJob
        $job | Wait-Job

        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual 2 @($vnetExpected.Subnets).Count
        Assert-AreEqual $subnetName $vnetExpected.Subnets[0].Name
        Assert-AreEqual $subnet2Name $vnetExpected.Subnets[1].Name
        Assert-AreEqual "10.0.5.0/28 10.0.6.0/28" $vnetExpected.Subnets[1].AddressPrefix

        
        $subnet2 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name
        $subnetAll = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig

        Assert-AreEqual 2 @($subnetAll).Count
        Assert-AreEqual $subnetName $subnetAll[0].Name
        Assert-AreEqual $subnet2Name $subnetAll[1].Name
        Assert-AreEqual $subnet2Name $subnet2.Name

        
        try
        {
            $subnetNotExists = $vnetExpected | Get-AzVirtualNetworkSubnetConfig -Name "Subnet-DoesNotExist"
        }
        catch
        {
            if ($_.Exception.GetType() -ne [System.ArgumentException])
            {
                throw;
            }
        }

        
        Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Remove-AzVirtualNetworkSubnetConfig -Name $subnet2Name | Set-AzVirtualNetwork
        
        $vnetExpected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual 1 @($vnetExpected.Subnets).Count
        Assert-AreEqual $subnetName $vnetExpected.Subnets[0].Name        
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkCRUDWithDDoSProtection
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $ddosProtectionPlanName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent

    try 
    {
        

        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 

        

        $ddosProtectionPlan = New-AzDdosProtectionPlan -Name $ddosProtectionPlanName -ResourceGroupName $rgname -Location $location

        

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $actual = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -DnsServer 8.8.8.8 -Subnet $subnet -EnableDdoSProtection -DdosProtectionPlanId $ddosProtectionPlan.Id
        $expected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname

        Assert-AreEqual $expected.ResourceGroupName $rgname
        Assert-AreEqual $expected.Name $actual.Name
        Assert-AreEqual $expected.Location $actual.Location
        Assert-AreEqual "Succeeded" $expected.ProvisioningState
        Assert-NotNull $expected.ResourceGuid
        Assert-AreEqual "10.0.0.0/16" $expected.AddressSpace.AddressPrefixes[0]
        Assert-AreEqual 1 @($expected.DhcpOptions.DnsServers).Count
        Assert-AreEqual "8.8.8.8" $expected.DhcpOptions.DnsServers[0]
        Assert-AreEqual 1 @($expected.Subnets).Count
        Assert-AreEqual $subnetName $expected.Subnets[0].Name
        Assert-AreEqual "10.0.1.0/24" $expected.Subnets[0].AddressPrefix
        Assert-AreEqual true $expected.EnableDDoSProtection
        Assert-AreEqual $ddosProtectionPlan.Id $expected.DdosProtectionPlan.Id
        
        $expected.EnableDDoSProtection = $false
        $expected.DdosProtectionPlan = $null
        Set-AzVirtualNetwork -VirtualNetwork $expected
        $expected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual false $expected.EnableDDoSProtection
        Assert-AreEqual $null $expected.DdosProtectionPlan
       
        $expected.DdosProtectionPlan = New-Object Microsoft.Azure.Commands.Network.Models.PSResourceId
        $expected.DdosProtectionPlan.Id = $ddosProtectionPlan.Id
        Set-AzVirtualNetwork -VirtualNetwork $expected
        $expected = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
        Assert-AreEqual false $expected.EnableDDoSProtection
        Assert-AreEqual $ddosProtectionPlan.Id $expected.DdosProtectionPlan.Id

        

        $deleteVnet = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $deleteVnet

        

        $deleteDdosProtectionPlan = Remove-AzDdosProtectionPlan -ResourceGroupName $rgname -name $ddosProtectionPlanName -PassThru
        Assert-AreEqual true $deleteDdosProtectionPlan
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkPeeringCRUD
{
    
    $rgname = Get-ResourceGroupName
    $peerName = Get-ResourceName
    $vnet1Name = Get-ResourceName
    $vnet2Name = Get-ResourceName
    $subnet1Name = Get-ResourceName
    $subnet2Name = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet1 = New-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix 10.0.0.0/24
        $vnet1 = New-AzVirtualNetwork -Name $vnet1Name -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet1


        Assert-AreEqual $vnet1.ResourceGroupName $rgname    
        Assert-AreEqual $vnet1.Name $vnet1Name    
        Assert-AreEqual $vnet1.Location $rglocation
        Assert-AreEqual "Succeeded" $vnet1.ProvisioningState        
        Assert-AreEqual $vnet1.Subnets[0].Name $subnet1.Name

        
        $subnet2 = New-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.1.1.0/24
        $vnet2 = New-AzVirtualNetwork -Name $vnet2Name -ResourceGroupName $rgname -Location $location -AddressPrefix 10.1.0.0/16 -Subnet $subnet2

        Assert-AreEqual $vnet2.ResourceGroupName $rgname    
        Assert-AreEqual $vnet2.Name $vnet2Name    
        Assert-AreEqual $vnet2.Location $rglocation
        Assert-AreEqual "Succeeded" $vnet2.ProvisioningState 

        
        $job = $vnet1 | Add-AzVirtualNetworkPeering -name $peerName -RemoteVirtualNetworkId $vnet2.Id -AllowForwardedTraffic -AsJob
        $job | Wait-Job
        $peer = $job | Receive-Job
        
        Assert-AreEqual $peer.ResourceGroupName $rgname    
        Assert-AreEqual $peer.Name $peerName    
        Assert-AreEqual $peer.VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $peer.ProvisioningState 
        Assert-AreEqual $peer.RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $peer.AllowVirtualNetworkAccess True
        Assert-AreEqual $peer.AllowForwardedTraffic True
        Assert-Null $peer.RemoteGateways
        Assert-Null $peer.$peer.RemoteVirtualNetworkAddressSpace
        
        
        $getPeer = Get-AzVirtualNetworkPeering -name $peerName -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname
        
        Assert-AreEqual $getPeer.ResourceGroupName $rgname    
        Assert-AreEqual $getPeer.Name $peerName    
        Assert-AreEqual $getPeer.VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $getPeer.ProvisioningState 
        Assert-AreEqual $getPeer.RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $getPeer.AllowVirtualNetworkAccess True
        Assert-AreEqual $getPeer.AllowForwardedTraffic True
        Assert-AreEqual $peer.AllowGatewayTransit $false
        Assert-AreEqual $peer.UseRemoteGateways $false
        Assert-Null $getPeer.RemoteGateways
        Assert-Null $getPeer.$peer.RemoteVirtualNetworkAddressSpace
        
        
        $listPeer = Get-AzVirtualNetworkPeering -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname
        
        Assert-AreEqual 1 @($listPeer).Count
        Assert-AreEqual $listPeer[0].ResourceGroupName $rgname    
        Assert-AreEqual $listPeer[0].Name $peerName    
        Assert-AreEqual $listPeer[0].VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $listPeer[0].ProvisioningState 
        Assert-AreEqual $listPeer[0].RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $listPeer[0].AllowVirtualNetworkAccess True
        Assert-AreEqual $listPeer[0].AllowForwardedTraffic True
        Assert-AreEqual $listPeer[0].AllowGatewayTransit $false
        Assert-AreEqual $listPeer[0].UseRemoteGateways $false
        Assert-Null $listPeer[0].RemoteGateways
        Assert-Null $listPeer[0].$peer.RemoteVirtualNetworkAddressSpace

        
        $listPeer = Get-AzVirtualNetworkPeering -Name "*" -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname
        
        Assert-AreEqual 1 @($listPeer).Count
        Assert-AreEqual $listPeer[0].ResourceGroupName $rgname    
        Assert-AreEqual $listPeer[0].Name $peerName    
        Assert-AreEqual $listPeer[0].VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $listPeer[0].ProvisioningState 
        Assert-AreEqual $listPeer[0].RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $listPeer[0].AllowVirtualNetworkAccess True
        Assert-AreEqual $listPeer[0].AllowForwardedTraffic True
        Assert-AreEqual $listPeer[0].AllowGatewayTransit $false
        Assert-AreEqual $listPeer[0].UseRemoteGateways $false
        Assert-Null $listPeer[0].RemoteGateways
        Assert-Null $listPeer[0].$peer.RemoteVirtualNetworkAddressSpace
        
        
        $getPeer.AllowForwardedTraffic = $false
        
        $job = $getPeer | Set-AzVirtualNetworkPeering -AsJob
        $job | Wait-Job
        $setPeer = $job | Receive-Job
        
        Assert-AreEqual $setPeer.ResourceGroupName $rgname    
        Assert-AreEqual $setPeer.Name $peerName    
        Assert-AreEqual $setPeer.VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $setPeer.ProvisioningState 
        Assert-AreEqual $setPeer.RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $setPeer.AllowVirtualNetworkAccess True
        Assert-AreEqual $setPeer.AllowForwardedTraffic $false
        Assert-AreEqual $setPeer.AllowGatewayTransit $false
        Assert-AreEqual $setPeer.UseRemoteGateways $false
        Assert-Null $setPeer.RemoteGateways
        Assert-Null $setPeer.$peer.RemoteVirtualNetworkAddressSpace
        
        
        $job = Remove-AzVirtualNetworkPeering -name $peerName -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname -Force -PassThru -AsJob
        $job | Wait-Job
        $delete = $job | Receive-Job
        Assert-AreEqual true $delete

        
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnet1Name -PassThru -Force
        Assert-AreEqual true $delete

        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnet2Name -PassThru -Force
        Assert-AreEqual true $delete
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-MultiTenantVNetPCRUD
{
    
    $rgname = Get-ResourceGroupName
    $peerName = Get-ResourceName
    $vnet1Name = Get-ResourceName
    $vnet2Id = "/subscriptions/0b1f6471-1bf0-4dda-aec3-cb9272f09590/resourceGroups/paryTestRG/providers/Microsoft.Network/virtualNetworks/myVirtualNetwork1"
    $subnet1Name = Get-ResourceName
    $subnet2Name = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "East US"
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent "East US"

	
	
	

    
    

    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet1 = New-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix 10.0.0.0/24
        $vnet1 = New-AzVirtualNetwork -Name $vnet1Name -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet2
                
        Assert-AreEqual $vnet1.ResourceGroupName $rgname    
        Assert-AreEqual $vnet1.Name $vnet1Name    
        Assert-AreEqual $vnet1.Location $rglocation
        Assert-AreEqual "Succeeded" $vnet1.ProvisioningState        
       

        
        $job = $vnet1 | Add-AzVirtualNetworkPeering -name $peerName -RemoteVirtualNetworkId $vnet2Id -AllowForwardedTraffic -AsJob
        $job | Wait-Job
        $peer = $job | Receive-Job
        
        Assert-AreEqual $peer.ResourceGroupName $rgname    
        Assert-AreEqual $peer.Name $peerName    
        Assert-AreEqual $peer.VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $peer.ProvisioningState 
        Assert-AreEqual $peer.RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $peer.AllowVirtualNetworkAccess True
        Assert-AreEqual $peer.AllowForwardedTraffic True
        Assert-Null $peer.RemoteGateways
        Assert-Null $peer.$peer.RemoteVirtualNetworkAddressSpace
        
        
        $getPeer = Get-AzVirtualNetworkPeering -name $peerName -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname
        
        Assert-AreEqual $getPeer.ResourceGroupName $rgname    
        Assert-AreEqual $getPeer.Name $peerName    
        Assert-AreEqual $getPeer.VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $getPeer.ProvisioningState 
        Assert-AreEqual $getPeer.RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $getPeer.AllowVirtualNetworkAccess True
        Assert-AreEqual $getPeer.AllowForwardedTraffic True
        Assert-AreEqual $peer.AllowGatewayTransit $false
        Assert-AreEqual $peer.UseRemoteGateways $false
        Assert-Null $getPeer.RemoteGateways
        Assert-Null $getPeer.$peer.RemoteVirtualNetworkAddressSpace
        
        
        $listPeer = Get-AzVirtualNetworkPeering -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname
        
        Assert-AreEqual 1 @($listPeer).Count
        Assert-AreEqual $listPeer[0].ResourceGroupName $rgname    
        Assert-AreEqual $listPeer[0].Name $peerName    
        Assert-AreEqual $listPeer[0].VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $listPeer[0].ProvisioningState 
        Assert-AreEqual $listPeer[0].RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $listPeer[0].AllowVirtualNetworkAccess True
        Assert-AreEqual $listPeer[0].AllowForwardedTraffic True
        Assert-AreEqual $listPeer[0].AllowGatewayTransit $false
        Assert-AreEqual $listPeer[0].UseRemoteGateways $false
        Assert-Null $listPeer[0].RemoteGateways
        Assert-Null $listPeer[0].$peer.RemoteVirtualNetworkAddressSpace
        
        
        $getPeer.AllowForwardedTraffic = $false
        
        $job = $getPeer | Set-AzVirtualNetworkPeering -AsJob
        $job | Wait-Job
        $setPeer = $job | Receive-Job
        
        Assert-AreEqual $setPeer.ResourceGroupName $rgname    
        Assert-AreEqual $setPeer.Name $peerName    
        Assert-AreEqual $setPeer.VirtualNetworkName $vnet1Name
        Assert-AreEqual "Succeeded" $setPeer.ProvisioningState 
        Assert-AreEqual $setPeer.RemoteVirtualNetwork.Id $vnet2.Id
        Assert-AreEqual $setPeer.AllowVirtualNetworkAccess True
        Assert-AreEqual $setPeer.AllowForwardedTraffic $false
        Assert-AreEqual $setPeer.AllowGatewayTransit $false
        Assert-AreEqual $setPeer.UseRemoteGateways $false
        Assert-Null $setPeer.RemoteGateways
        Assert-Null $setPeer.$peer.RemoteVirtualNetworkAddressSpace
        
        
        $job = Remove-AzVirtualNetworkPeering -name $peerName -VirtualNetworkName $vnet1Name -ResourceGroupName $rgname -Force -PassThru -AsJob
        $job | Wait-Job
        $delete = $job | Receive-Job
        Assert-AreEqual true $delete

        
        $delete = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnet1Name -PassThru -Force
        Assert-AreEqual true $delete

		
        
        
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ResourceNavigationLinksCRUD
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $cacheName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "West US"
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
                
        Assert-AreEqual $vnet.ResourceGroupName $rgname    
        Assert-AreEqual $vnet.Name $vnetName    
        Assert-AreEqual $vnet.Location $rglocation
        Assert-AreEqual "Succeeded" $vnet.ProvisioningState

        $subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig -Name $subnetName
        Assert-AreEqual 0 @($subnet.ResourceNavigationLinks).Count

        
        $cacheCreated = New-AzRedisCache -ResourceGroupName $rgname -Name $cacheName -Location $location -Size P1 -Sku Premium -SubnetId $subnet.Id

        
        for ($i = 0; $i -le 60; $i++)
        {
            Start-TestSleep 30000
            $cacheGet = Get-AzRedisCache -ResourceGroupName $rgname -Name $cacheName
            if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
            {
                break
            }
            Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
        }

        
        $cache = Get-AzRedisCache -ResourceGroupName $rgname -Name $cacheName

        
        $subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig -Name $subnetName
        Assert-AreEqual 1 @($subnet.ResourceNavigationLinks).Count
        Assert-AreEqual $cache.Id $subnet.ResourceNavigationLinks[0].Link
        Assert-AreEqual "Microsoft.Cache/redis" $subnet.ResourceNavigationLinks[0].LinkedResourceType
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkUsage
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $subnet2Name = Get-ResourceName
    $nicName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname

        Assert-NotNull $vnet;
        Assert-NotNull $vnet.Subnets;

        $subnetId = $vnet.Subnets[0].Id;

        $usage = Get-AzVirtualNetworkUsageList -ResourceGroupName $rgname -Name $vnetName;

        Assert-NotNull $usage;
        $currentUsage = $usage.CurrentValue;

        
        New-AzNetworkInterface -Location $location -Name $nicName -ResourceGroupName $rgname -SubnetId $subnetId;
        $usage = Get-AzVirtualNetworkUsageList -ResourceGroupName $rgname -Name $vnetName;
        $currentUsageNew = $usage.CurrentValue;

        Assert-AreEqual $currentUsage $($currentUsageNew - 1);
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkSubnetServiceEndpoint
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    $serviceEndpoint = "Microsoft.Storage"

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" };

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -ServiceEndpoint $serviceEndpoint;
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet;
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname;

        Assert-NotNull $vnet;
        Assert-NotNull $vnet.Subnets;

        $subnet = $vnet.Subnets[0];
        Assert-AreEqual $serviceEndpoint $subnet.serviceEndpoints[0].Service;

        Set-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix 10.0.1.0/24 -ServiceEndpoint $null;
        $vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet;
        $subnet = $vnet.Subnets[0];

        Assert-Null $subnet.serviceEndpoints;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-VirtualNetworkSubnetServiceEndpointPolicies
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent
    $serviceEndpoint = "Microsoft.Storage"
    $serviceEndpointPolicyDefinitionName = "ServiceEndpointPolicyDefinition1"
	$serviceEndpointPolicyDefinitionDescription = "New Policy"
    $serviceEndpointPolicyDefinitionDescription2 = "One more policy"
    $updatedDescription = "Updated"
    $serviceEndpointPolicyName = "ServiceEndpointPolicy1"
    $serviceEndpointPolicyDefinitionName2 = Get-ResourceName
    $serviceEndpointPolicyDefinitionResourceName = "/subscriptions/subid1/resourceGroups/storageRg/providers/Microsoft.Storage/storageAccounts/stAccount"
	$provisioningStateSucceeded = "Succeeded"

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" };

        
        $serviceEndpointDefinition = New-AzServiceEndpointPolicyDefinition -Name $serviceEndpointPolicyDefinitionName -Service $serviceEndpoint -ServiceResource $serviceEndpointPolicyDefinitionResourceName -Description $serviceEndpointPolicyDefinitionDescription;
        $serviceEndpointPolicy = New-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ServiceEndpointPolicyDefinition $serviceEndpointDefinition -ResourceGroupName $rgname -Location $rglocation;

        
        $serviceEndpointPolicy = New-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ServiceEndpointPolicyDefinition $serviceEndpointDefinition -ResourceGroupName $rgname -Location $rglocation -Force;

        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname;

        Assert-AreEqual $getserviceEndpointPolicy[0].Name $serviceEndpointPolicyName;
        Assert-AreEqual $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Service $serviceEndpoint;
        Assert-AreEqual $serviceEndpointPolicyDefinitionName $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Name;
        Assert-AreEqual $serviceEndpointPolicyDefinitionDescription $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Description;
        Assert-AreEqual $serviceEndpointPolicyDefinitionResourceName $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].ServiceResources[0];
        Assert-AreEqual $getserviceEndpointPolicy[0].ProvisioningState $provisioningStateSucceeded;

        $getserviceEndpointPolicyDefinition = Get-AzServiceEndpointPolicyDefinition -Name $serviceEndpointPolicyDefinitionName -ServiceEndpointPolicy $getserviceEndpointPolicy

        Assert-AreEqual $getserviceEndpointPolicyDefinition[0].Name $serviceEndpointPolicyDefinitionName;
        Assert-AreEqual $getserviceEndpointPolicyDefinition[0].ProvisioningState $provisioningStateSucceeded;
        Assert-AreEqual $getserviceEndpointPolicyDefinition[0].ServiceResources[0] $serviceEndpointPolicyDefinitionResourceName;
        Assert-AreEqual $getserviceEndpointPolicyDefinition[0].Service $serviceEndpoint;

        $getserviceEndpointPolicyDefinitionList = Get-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $getserviceEndpointPolicy;
        Assert-NotNull $getserviceEndpointPolicyDefinitionList;

        $getserviceEndpointPolicyList = Get-AzServiceEndpointPolicy -ResourceGroupName $rgname;
        Assert-NotNull $getserviceEndpointPolicyList;

        $getserviceEndpointPolicyListAll = Get-AzServiceEndpointPolicy;
        Assert-NotNull $getserviceEndpointPolicyListAll;

        $getserviceEndpointPolicyListAll = Get-AzServiceEndpointPolicy -ResourceGroupName "*"
        Assert-NotNull $getserviceEndpointPolicyListAll;

        $getserviceEndpointPolicyListAll = Get-AzServiceEndpointPolicy -Name "*"
        Assert-NotNull $getserviceEndpointPolicyListAll;

        $getserviceEndpointPolicyListAll = Get-AzServiceEndpointPolicy -ResourceGroupName "*" -Name "*"
        Assert-NotNull $getserviceEndpointPolicyListAll;

        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -ResourceId $serviceEndpointPolicy.Id;
        Assert-AreEqual $getserviceEndpointPolicy[0].Name $serviceEndpointPolicyName;
        Assert-AreEqual $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Service $serviceEndpoint;
        Assert-AreEqual $serviceEndpointPolicyDefinitionName $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Name;
        Assert-AreEqual $serviceEndpointPolicyDefinitionDescription $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Description;
        Assert-AreEqual $serviceEndpointPolicyDefinitionResourceName $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].ServiceResources[0];
        Assert-AreEqual $getserviceEndpointPolicy[0].ProvisioningState $provisioningStateSucceeded;

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -ServiceEndpoint $serviceEndpoint -ServiceEndpointPolicy $serviceEndpointPolicy;
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet;
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname;

        Assert-NotNull $vnet;
        Assert-NotNull $vnet.Subnets;

        $subnet = $vnet.Subnets[0];
        Assert-AreEqual $serviceEndpoint $subnet.serviceEndpoints[0].Service;
        Assert-AreEqual $getserviceEndpointPolicy[0].Id $subnet.serviceEndpointPolicies[0].Id;

        Set-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix 10.0.1.0/24 -ServiceEndpoint $null -ServiceEndpointPolicy $null;
        $vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet;
        $subnet = $vnet.Subnets[0];

        Assert-Null $subnet.serviceEndpoints;
        Assert-Null $subnet.ServiceEndpointPolicies;

        Remove-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -Name $serviceEndpointPolicyDefinitionName;
        $serviceEndpointPolicy = Set-AzServiceEndpointPolicy -ServiceEndpointPolicy $serviceEndpointPolicy
        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname;

        Assert-AreEqual 0 $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions.Count;

        Add-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -Name $serviceEndpointPolicyDefinitionName -Service $serviceEndpoint -ServiceResource $serviceEndpointPolicyDefinitionResourceName -Description $serviceEndpointPolicyDefinitionDescription2;
        Assert-ThrowsLike { Add-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -Name $serviceEndpointPolicyDefinitionName -Service $serviceEndpoint -ServiceResource $serviceEndpointPolicyDefinitionResourceName -Description $serviceEndpointPolicyDefinitionDescription2; } "*already exists*"
        $serviceEndpointPolicy = Set-AzServiceEndpointPolicy -ServiceEndpointPolicy $serviceEndpointPolicy
        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname;

        Assert-AreEqual $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Service $serviceEndpoint;
        Assert-AreEqual $serviceEndpointPolicyDefinitionName $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Name;
        Assert-AreEqual $serviceEndpointPolicyDefinitionDescription2 $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Description;
        Assert-AreEqual $serviceEndpointPolicyDefinitionResourceName $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].ServiceResources[0];

        Set-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -Name $serviceEndpointPolicyDefinitionName -Service $serviceEndpoint -ServiceResource $serviceEndpointPolicyDefinitionResourceName -Description $updatedDescription;
        Assert-ThrowsLike { Set-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -Name "fake name" -Service $serviceEndpoint -ServiceResource $serviceEndpointPolicyDefinitionResourceName -Description $serviceEndpointPolicyDefinitionDescription2; } "*does not exist*"
        $serviceEndpointPolicy = Set-AzServiceEndpointPolicy -ServiceEndpointPolicy $serviceEndpointPolicy
        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname;
        Assert-AreEqual $updatedDescription $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Description;

        Remove-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -ResourceId $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0].Id
        $serviceEndpointPolicy = Set-AzServiceEndpointPolicy -ServiceEndpointPolicy $serviceEndpointPolicy
        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname;
        Assert-AreEqual 0 $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions.Count;

        Remove-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname -Force

        Assert-ThrowsLike { Set-AzServiceEndpointPolicy -ServiceEndpointPolicy $serviceEndpointPolicy } "*not*found*"

        $serviceEndpointPolicy = New-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ServiceEndpointPolicyDefinition $serviceEndpointDefinition -ResourceGroupName $rgname -Location $rglocation;

        Remove-AzServiceEndpointPolicyDefinition -ServiceEndpointPolicy $serviceEndpointPolicy -InputObject $serviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions[0]
        $serviceEndpointPolicy = Set-AzServiceEndpointPolicy -ServiceEndpointPolicy $serviceEndpointPolicy
        $getserviceEndpointPolicy = Get-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ResourceGroupName $rgname;
        Assert-AreEqual 0 $getserviceEndpointPolicy[0].ServiceEndpointPolicyDefinitions.Count;

        $deleted = Remove-AzServiceEndpointPolicy -ResourceId $serviceEndpointPolicy.Id -Force -PassThru
        Assert-AreEqual true $deleted

        $serviceEndpointPolicy = New-AzServiceEndpointPolicy -Name $serviceEndpointPolicyName -ServiceEndpointPolicyDefinition $serviceEndpointDefinition -ResourceGroupName $rgname -Location $rglocation;
        $deleted = Remove-AzServiceEndpointPolicy -InputObject $serviceEndpointPolicy -Force -PassThru
        Assert-AreEqual true $deleted
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
