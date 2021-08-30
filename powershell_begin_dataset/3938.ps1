

























function Check-CmdletReturnType
{
    param($cmdletName, $cmdletReturn)

    $cmdletData = Get-Command $cmdletName;
    Assert-NotNull $cmdletData;
    [array]$cmdletReturnTypes = $cmdletData.OutputType.Name | Foreach-Object { return ($_ -replace "Microsoft.Azure.Commands.Network.Models.","") };
    [array]$cmdletReturnTypes = $cmdletReturnTypes | Foreach-Object { return ($_ -replace "System.","") };
    $realReturnType = $cmdletReturn.GetType().Name -replace "Microsoft.Azure.Commands.Network.Models.","";
    return $cmdletReturnTypes -contains $realReturnType;
}


function Test-LoadBalancerCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";
    $BackendAddressPoolName = "BackendAddressPoolName";
    $ProbeName = "ProbeName";
    $ProbePort = 2424;
    $ProbeIntervalInSeconds = 6;
    $ProbeProbeCount = 4;
    $InboundNatPoolName = "InboundNatPoolName";
    $InboundNatPoolProtocol = "Udp";
    $InboundNatPoolFrontendPortRangeStart = 555;
    $InboundNatPoolFrontendPortRangeEnd = 999;
    $InboundNatPoolBackendPort = 987;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;
        $BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName;
        $Probe = New-AzLoadBalancerProbeConfig -Name $ProbeName -Port $ProbePort -IntervalInSeconds $ProbeIntervalInSeconds -ProbeCount $ProbeProbeCount;
        $InboundNatPool = New-AzLoadBalancerInboundNatPoolConfig -Name $InboundNatPoolName -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $InboundNatPoolProtocol -FrontendPortRangeStart $InboundNatPoolFrontendPortRangeStart -FrontendPortRangeEnd $InboundNatPoolFrontendPortRangeEnd -BackendPort $InboundNatPoolBackendPort;

        
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -Location $location -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -InboundNatPool $InboundNatPool;
        Assert-NotNull $vLoadBalancer;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancer" $vLoadBalancer };
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.Probes;
        Assert-True { $vLoadBalancer.Probes.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.InboundNatPools;
        Assert-True { $vLoadBalancer.InboundNatPools.Length -gt 0 };
        Assert-AreEqual $rname $vLoadBalancer.Name;

        
        $vLoadBalancer = Get-AzLoadBalancer -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vLoadBalancer;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancer" $vLoadBalancer };
        Assert-AreEqual $rname $vLoadBalancer.Name;

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName $rgname;
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer;
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -Name "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeLoadBalancer = $job | Receive-Job;
        Assert-AreEqual $true $removeLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancer -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-LoadBalancerCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Tag = @{tag1='test'};
    $Sku = "Basic";
    
    $TagSet = @{tag2='testSet'};
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";
    $BackendAddressPoolName = "BackendAddressPoolName";
    $ProbeName = "ProbeName";
    $ProbePort = 2424;
    $ProbeIntervalInSeconds = 6;
    $ProbeProbeCount = 4;
    $InboundNatPoolName = "InboundNatPoolName";
    $InboundNatPoolProtocol = "Udp";
    $InboundNatPoolFrontendPortRangeStart = 555;
    $InboundNatPoolFrontendPortRangeEnd = 999;
    $InboundNatPoolBackendPort = 987;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;
        $BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName;
        $Probe = New-AzLoadBalancerProbeConfig -Name $ProbeName -Port $ProbePort -IntervalInSeconds $ProbeIntervalInSeconds -ProbeCount $ProbeProbeCount;
        $InboundNatPool = New-AzLoadBalancerInboundNatPoolConfig -Name $InboundNatPoolName -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $InboundNatPoolProtocol -FrontendPortRangeStart $InboundNatPoolFrontendPortRangeStart -FrontendPortRangeEnd $InboundNatPoolFrontendPortRangeEnd -BackendPort $InboundNatPoolBackendPort;

        
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -Location $location -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -InboundNatPool $InboundNatPool -Tag $Tag -Sku $Sku;
        Assert-NotNull $vLoadBalancer;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancer" $vLoadBalancer };
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.Probes;
        Assert-True { $vLoadBalancer.Probes.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.InboundNatPools;
        Assert-True { $vLoadBalancer.InboundNatPools.Length -gt 0 };
        Assert-AreEqual $rname $vLoadBalancer.Name;
        Assert-AreEqualObjectProperties $Tag $vLoadBalancer.Tag;
        Assert-AreEqual $Sku $vLoadBalancer.Sku.Name;

        
        $vLoadBalancer = Get-AzLoadBalancer -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vLoadBalancer;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancer" $vLoadBalancer };
        Assert-AreEqual $rname $vLoadBalancer.Name;
        Assert-AreEqualObjectProperties $Tag $vLoadBalancer.Tag;
        Assert-AreEqual $Sku $vLoadBalancer.Sku.Name;

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName $rgname;
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer;
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -Name "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vLoadBalancer.Tag = $TagSet;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;
        Assert-True { Check-CmdletReturnType "Set-AzLoadBalancer" $vLoadBalancer };
        Assert-AreEqual $rname $vLoadBalancer.Name;
        Assert-AreEqualObjectProperties $TagSet $vLoadBalancer.Tag;

        
        $vLoadBalancer = Get-AzLoadBalancer -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vLoadBalancer;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancer" $vLoadBalancer };
        Assert-AreEqual $rname $vLoadBalancer.Name;
        Assert-AreEqualObjectProperties $TagSet $vLoadBalancer.Tag;

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName $rgname;
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer;
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -Name "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listLoadBalancer = Get-AzLoadBalancer -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeLoadBalancer = $job | Receive-Job;
        Assert-AreEqual $true $removeLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancer -ResourceGroupName $rgname -Name $rname } "not found";

        
        Assert-ThrowsContains { Set-AzLoadBalancer -LoadBalancer $vLoadBalancer } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-FrontendIPConfigurationCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers" "East US 2";
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }

        
        $vFrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $rname -Subnet $Subnet;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -FrontendIPConfiguration $vFrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-AreEqual $rname $vFrontendIPConfiguration.Name;

        
        $vFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        Assert-AreEqual $rname $vFrontendIPConfiguration.Name;

        
        $listFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listFrontendIPConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerFrontendIpConfig -Name $rname -LoadBalancer $vLoadBalancer -Subnet $Subnet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        Assert-AreEqual $rname $vFrontendIPConfiguration.Name;

        
        $listFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listFrontendIPConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerFrontendIpConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Subnet $Subnet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        Assert-AreEqual $rnameAdd $vFrontendIPConfiguration.Name;

        
        $listFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listFrontendIPConfiguration | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerFrontendIpConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Subnet $Subnet } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerFrontendIpConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Subnet $Subnet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-FrontendIPConfigurationCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers" "East US 2";
    
    $PrivateIpAddress = "10.0.1.13";
    
    $PrivateIpAddressSet = "10.0.1.16";
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }

        
        $vFrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $rname -Subnet $Subnet -PrivateIpAddress $PrivateIpAddress;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -FrontendIPConfiguration $vFrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-AreEqual $rname $vFrontendIPConfiguration.Name;
        Assert-AreEqual $PrivateIpAddress $vFrontendIPConfiguration.PrivateIpAddress;

        
        $vFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        Assert-AreEqual $rname $vFrontendIPConfiguration.Name;
        Assert-AreEqual $PrivateIpAddress $vFrontendIPConfiguration.PrivateIpAddress;

        
        $listFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listFrontendIPConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerFrontendIpConfig -Name $rname -LoadBalancer $vLoadBalancer -Subnet $Subnet -PrivateIpAddress $PrivateIpAddressSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        Assert-AreEqual $rname $vFrontendIPConfiguration.Name;
        Assert-AreEqual $PrivateIpAddressSet $vFrontendIPConfiguration.PrivateIpAddress;

        
        $listFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listFrontendIPConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerFrontendIpConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Subnet $Subnet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vFrontendIPConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerFrontendIpConfig" $vFrontendIPConfiguration };
        Assert-AreEqual $rnameAdd $vFrontendIPConfiguration.Name;

        
        $listFrontendIPConfiguration = Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listFrontendIPConfiguration | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerFrontendIpConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Subnet $Subnet } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerFrontendIpConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerFrontendIpConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Subnet $Subnet -PrivateIpAddress $PrivateIpAddressSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-BackendAddressPoolCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;

        
        $vBackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $rname;
        Assert-NotNull $vBackendAddressPool;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerBackendAddressPoolConfig" $vBackendAddressPool };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -BackendAddressPool $vBackendAddressPool -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-AreEqual $rname $vBackendAddressPool.Name;

        
        $vBackendAddressPool = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vBackendAddressPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerBackendAddressPoolConfig" $vBackendAddressPool };
        Assert-AreEqual $rname $vBackendAddressPool.Name;

        
        $listBackendAddressPool = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listBackendAddressPool | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerBackendAddressPoolConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vBackendAddressPool = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vBackendAddressPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerBackendAddressPoolConfig" $vBackendAddressPool };
        Assert-AreEqual $rnameAdd $vBackendAddressPool.Name;

        
        $listBackendAddressPool = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listBackendAddressPool | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerBackendAddressPoolConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-LoadBalancingRuleCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    $FrontendPort = 1024;
    $BackendPort = 4096;
    
    $ProtocolSet = "Tcp";
    $FrontendPortSet = 1026;
    $BackendPortSet = 4095;
    
    $ProtocolAdd = "Tcp";
    $FrontendPortAdd = 1025;
    $BackendPortAdd = 4094;
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";
    $BackendAddressPoolName = "BackendAddressPoolName";
    $ProbeName = "ProbeName";
    $ProbePort = 2424;
    $ProbeIntervalInSeconds = 6;
    $ProbeProbeCount = 4;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -Subnet $Subnet;
        $BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName;
        $Probe = New-AzLoadBalancerProbeConfig -Name $ProbeName -Port $ProbePort -IntervalInSeconds $ProbeIntervalInSeconds -ProbeCount $ProbeProbeCount;

        
        $vLoadBalancingRule = New-AzLoadBalancerRuleConfig -Name $rname -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $Protocol -FrontendPort $FrontendPort -BackendPort $BackendPort;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -LoadBalancingRule $vLoadBalancingRule -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.Probes;
        Assert-True { $vLoadBalancer.Probes.Length -gt 0 };
        Assert-AreEqual $rname $vLoadBalancingRule.Name;
        Assert-AreEqual $Protocol $vLoadBalancingRule.Protocol;
        Assert-AreEqual $FrontendPort $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPort $vLoadBalancingRule.BackendPort;

        
        $vLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        Assert-AreEqual $rname $vLoadBalancingRule.Name;
        Assert-AreEqual $Protocol $vLoadBalancingRule.Protocol;
        Assert-AreEqual $FrontendPort $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPort $vLoadBalancingRule.BackendPort;

        
        $listLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listLoadBalancingRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolSet -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        Assert-AreEqual $rname $vLoadBalancingRule.Name;
        Assert-AreEqual $ProtocolSet $vLoadBalancingRule.Protocol;
        Assert-AreEqual $FrontendPortSet $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPortSet $vLoadBalancingRule.BackendPort;

        
        $listLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listLoadBalancingRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolAdd -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        Assert-AreEqual $rnameAdd $vLoadBalancingRule.Name;
        Assert-AreEqual $ProtocolAdd $vLoadBalancingRule.Protocol;
        Assert-AreEqual $FrontendPortAdd $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPortAdd $vLoadBalancingRule.BackendPort;

        
        $listLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listLoadBalancingRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolAdd -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolSet -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-LoadBalancingRuleCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    $LoadDistribution = "Default";
    $FrontendPort = 1024;
    $BackendPort = 4096;
    $IdleTimeoutInMinutes = 5;
    $EnableFloatingIP = $true;
    $EnableTcpReset = $false;
    
    $ProtocolSet = "Tcp";
    $LoadDistributionSet = "SourceIP";
    $FrontendPortSet = 1026;
    $BackendPortSet = 4095;
    $IdleTimeoutInMinutesSet = 29;
    $EnableFloatingIPSet = $false;
    $EnableTcpResetSet = $false;
    
    $ProtocolAdd = "Tcp";
    $LoadDistributionAdd = "SourceIPProtocol";
    $FrontendPortAdd = 1025;
    $BackendPortAdd = 4094;
    $IdleTimeoutInMinutesAdd = 7;
    $EnableFloatingIPAdd = $false;
    $EnableTcpResetAdd = $false;
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";
    $BackendAddressPoolName = "BackendAddressPoolName";
    $ProbeName = "ProbeName";
    $ProbePort = 2424;
    $ProbeIntervalInSeconds = 6;
    $ProbeProbeCount = 4;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -Subnet $Subnet;
        $BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName;
        $Probe = New-AzLoadBalancerProbeConfig -Name $ProbeName -Port $ProbePort -IntervalInSeconds $ProbeIntervalInSeconds -ProbeCount $ProbeProbeCount;

        
        $vLoadBalancingRule = New-AzLoadBalancerRuleConfig -Name $rname -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $Protocol -LoadDistribution $LoadDistribution -FrontendPort $FrontendPort -BackendPort $BackendPort -IdleTimeoutInMinutes $IdleTimeoutInMinutes -EnableFloatingIP;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -LoadBalancingRule $vLoadBalancingRule -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.Probes;
        Assert-True { $vLoadBalancer.Probes.Length -gt 0 };
        Assert-AreEqual $rname $vLoadBalancingRule.Name;
        Assert-AreEqual $Protocol $vLoadBalancingRule.Protocol;
        Assert-AreEqual $LoadDistribution $vLoadBalancingRule.LoadDistribution;
        Assert-AreEqual $FrontendPort $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPort $vLoadBalancingRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutes $vLoadBalancingRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIP $vLoadBalancingRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpReset $vLoadBalancingRule.EnableTcpReset;

        
        $vLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        Assert-AreEqual $rname $vLoadBalancingRule.Name;
        Assert-AreEqual $Protocol $vLoadBalancingRule.Protocol;
        Assert-AreEqual $LoadDistribution $vLoadBalancingRule.LoadDistribution;
        Assert-AreEqual $FrontendPort $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPort $vLoadBalancingRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutes $vLoadBalancingRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIP $vLoadBalancingRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpReset $vLoadBalancingRule.EnableTcpReset;

        
        $listLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listLoadBalancingRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolSet -LoadDistribution $LoadDistributionSet -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        Assert-AreEqual $rname $vLoadBalancingRule.Name;
        Assert-AreEqual $ProtocolSet $vLoadBalancingRule.Protocol;
        Assert-AreEqual $LoadDistributionSet $vLoadBalancingRule.LoadDistribution;
        Assert-AreEqual $FrontendPortSet $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPortSet $vLoadBalancingRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutesSet $vLoadBalancingRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIPSet $vLoadBalancingRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpResetSet $vLoadBalancingRule.EnableTcpReset;

        
        $listLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listLoadBalancingRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolAdd -LoadDistribution $LoadDistributionAdd -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vLoadBalancingRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerRuleConfig" $vLoadBalancingRule };
        Assert-AreEqual $rnameAdd $vLoadBalancingRule.Name;
        Assert-AreEqual $ProtocolAdd $vLoadBalancingRule.Protocol;
        Assert-AreEqual $LoadDistributionAdd $vLoadBalancingRule.LoadDistribution;
        Assert-AreEqual $FrontendPortAdd $vLoadBalancingRule.FrontendPort;
        Assert-AreEqual $BackendPortAdd $vLoadBalancingRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutesAdd $vLoadBalancingRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIPAdd $vLoadBalancingRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpResetAdd $vLoadBalancingRule.EnableTcpReset;

        
        $listLoadBalancingRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listLoadBalancingRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolAdd -LoadDistribution $LoadDistributionAdd -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerRuleConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Probe $Probe -Protocol $ProtocolSet -LoadDistribution $LoadDistributionSet -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ProbeCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Port = 2424;
    $IntervalInSeconds = 6;
    $ProbeCount = 4;
    
    $PortSet = 4244;
    $IntervalInSecondsSet = 14;
    $ProbeCountSet = 7;
    
    $PortAdd = 443;
    $IntervalInSecondsAdd = 11;
    $ProbeCountAdd = 5;
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;

        
        $vProbe = New-AzLoadBalancerProbeConfig -Name $rname -Port $Port -IntervalInSeconds $IntervalInSeconds -ProbeCount $ProbeCount;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerProbeConfig" $vProbe };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -Probe $vProbe -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-AreEqual $rname $vProbe.Name;
        Assert-AreEqual $Port $vProbe.Port;
        Assert-AreEqual $IntervalInSeconds $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCount $vProbe.NumberOfProbes;

        
        $vProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerProbeConfig" $vProbe };
        Assert-AreEqual $rname $vProbe.Name;
        Assert-AreEqual $Port $vProbe.Port;
        Assert-AreEqual $IntervalInSeconds $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCount $vProbe.NumberOfProbes;

        
        $listProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listProbe | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerProbeConfig -Name $rname -LoadBalancer $vLoadBalancer -Port $PortSet -IntervalInSeconds $IntervalInSecondsSet -ProbeCount $ProbeCountSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerProbeConfig" $vProbe };
        Assert-AreEqual $rname $vProbe.Name;
        Assert-AreEqual $PortSet $vProbe.Port;
        Assert-AreEqual $IntervalInSecondsSet $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCountSet $vProbe.NumberOfProbes;

        
        $listProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listProbe | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerProbeConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Port $PortAdd -IntervalInSeconds $IntervalInSecondsAdd -ProbeCount $ProbeCountAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerProbeConfig" $vProbe };
        Assert-AreEqual $rnameAdd $vProbe.Name;
        Assert-AreEqual $PortAdd $vProbe.Port;
        Assert-AreEqual $IntervalInSecondsAdd $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCountAdd $vProbe.NumberOfProbes;

        
        $listProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listProbe | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerProbeConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Port $PortAdd -IntervalInSeconds $IntervalInSecondsAdd -ProbeCount $ProbeCountAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerProbeConfig -Name $rname -LoadBalancer $vLoadBalancer -Port $PortSet -IntervalInSeconds $IntervalInSecondsSet -ProbeCount $ProbeCountSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ProbeCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Http";
    $Port = 2424;
    $IntervalInSeconds = 6;
    $ProbeCount = 4;
    $RequestPath = "/create";
    
    $ProtocolSet = "Tcp";
    $PortSet = 4244;
    $IntervalInSecondsSet = 14;
    $ProbeCountSet = 7;
    
    $PortAdd = 443;
    $IntervalInSecondsAdd = 11;
    $ProbeCountAdd = 5;
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;

        
        $vProbe = New-AzLoadBalancerProbeConfig -Name $rname -Protocol $Protocol -Port $Port -IntervalInSeconds $IntervalInSeconds -ProbeCount $ProbeCount -RequestPath $RequestPath;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerProbeConfig" $vProbe };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -Probe $vProbe -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-AreEqual $rname $vProbe.Name;
        Assert-AreEqual $Protocol $vProbe.Protocol;
        Assert-AreEqual $Port $vProbe.Port;
        Assert-AreEqual $IntervalInSeconds $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCount $vProbe.NumberOfProbes;
        Assert-AreEqual $RequestPath $vProbe.RequestPath;

        
        $vProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerProbeConfig" $vProbe };
        Assert-AreEqual $rname $vProbe.Name;
        Assert-AreEqual $Protocol $vProbe.Protocol;
        Assert-AreEqual $Port $vProbe.Port;
        Assert-AreEqual $IntervalInSeconds $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCount $vProbe.NumberOfProbes;
        Assert-AreEqual $RequestPath $vProbe.RequestPath;

        
        $listProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listProbe | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerProbeConfig -Name $rname -LoadBalancer $vLoadBalancer -Protocol $ProtocolSet -Port $PortSet -IntervalInSeconds $IntervalInSecondsSet -ProbeCount $ProbeCountSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerProbeConfig" $vProbe };
        Assert-AreEqual $rname $vProbe.Name;
        Assert-AreEqual $ProtocolSet $vProbe.Protocol;
        Assert-AreEqual $PortSet $vProbe.Port;
        Assert-AreEqual $IntervalInSecondsSet $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCountSet $vProbe.NumberOfProbes;

        
        $listProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listProbe | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerProbeConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Port $PortAdd -IntervalInSeconds $IntervalInSecondsAdd -ProbeCount $ProbeCountAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vProbe;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerProbeConfig" $vProbe };
        Assert-AreEqual $rnameAdd $vProbe.Name;
        Assert-AreEqual $PortAdd $vProbe.Port;
        Assert-AreEqual $IntervalInSecondsAdd $vProbe.IntervalInSeconds;
        Assert-AreEqual $ProbeCountAdd $vProbe.NumberOfProbes;

        
        $listProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listProbe | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerProbeConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -Port $PortAdd -IntervalInSeconds $IntervalInSecondsAdd -ProbeCount $ProbeCountAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerProbeConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerProbeConfig -Name $rname -LoadBalancer $vLoadBalancer -Protocol $ProtocolSet -Port $PortSet -IntervalInSeconds $IntervalInSecondsSet -ProbeCount $ProbeCountSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-InboundNatRuleCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $FrontendPort = 123;
    $BackendPort = 456;
    
    $FrontendPortSet = 128;
    $BackendPortSet = 500;
    
    $FrontendPortAdd = 80;
    $BackendPortAdd = 512;
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -Subnet $Subnet;

        
        $vInboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $rname -FrontendIpConfiguration $FrontendIPConfiguration -FrontendPort $FrontendPort -BackendPort $BackendPort;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -InboundNatRule $vInboundNatRule -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-AreEqual $rname $vInboundNatRule.Name;
        Assert-AreEqual $FrontendPort $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPort $vInboundNatRule.BackendPort;

        
        $vInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        Assert-AreEqual $rname $vInboundNatRule.Name;
        Assert-AreEqual $FrontendPort $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPort $vInboundNatRule.BackendPort;

        
        $listInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerInboundNatRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        Assert-AreEqual $rname $vInboundNatRule.Name;
        Assert-AreEqual $FrontendPortSet $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPortSet $vInboundNatRule.BackendPort;

        
        $listInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerInboundNatRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        Assert-AreEqual $rnameAdd $vInboundNatRule.Name;
        Assert-AreEqual $FrontendPortAdd $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPortAdd $vInboundNatRule.BackendPort;

        
        $listInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerInboundNatRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerInboundNatRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-InboundNatRuleCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    $FrontendPort = 123;
    $BackendPort = 456;
    $IdleTimeoutInMinutes = 7;
    $EnableFloatingIP = $true;
    $EnableTcpReset = $false;
    
    $ProtocolSet = "Tcp";
    $FrontendPortSet = 128;
    $BackendPortSet = 500;
    $IdleTimeoutInMinutesSet = 15;
    $EnableFloatingIPSet = $false;
    $EnableTcpResetSet = $false;
    
    $ProtocolAdd = "Tcp";
    $FrontendPortAdd = 80;
    $BackendPortAdd = 512;
    $IdleTimeoutInMinutesAdd = 17;
    $EnableFloatingIPAdd = $false;
    $EnableTcpResetAdd = $false;
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -Subnet $Subnet;

        
        $vInboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $rname -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $Protocol -FrontendPort $FrontendPort -BackendPort $BackendPort -IdleTimeoutInMinutes $IdleTimeoutInMinutes -EnableFloatingIP;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -InboundNatRule $vInboundNatRule -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-AreEqual $rname $vInboundNatRule.Name;
        Assert-AreEqual $Protocol $vInboundNatRule.Protocol;
        Assert-AreEqual $FrontendPort $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPort $vInboundNatRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutes $vInboundNatRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIP $vInboundNatRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpReset $vInboundNatRule.EnableTcpReset;

        
        $vInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        Assert-AreEqual $rname $vInboundNatRule.Name;
        Assert-AreEqual $Protocol $vInboundNatRule.Protocol;
        Assert-AreEqual $FrontendPort $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPort $vInboundNatRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutes $vInboundNatRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIP $vInboundNatRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpReset $vInboundNatRule.EnableTcpReset;

        
        $listInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerInboundNatRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolSet -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        Assert-AreEqual $rname $vInboundNatRule.Name;
        Assert-AreEqual $ProtocolSet $vInboundNatRule.Protocol;
        Assert-AreEqual $FrontendPortSet $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPortSet $vInboundNatRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutesSet $vInboundNatRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIPSet $vInboundNatRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpResetSet $vInboundNatRule.EnableTcpReset;

        
        $listInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerInboundNatRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolAdd -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vInboundNatRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatRuleConfig" $vInboundNatRule };
        Assert-AreEqual $rnameAdd $vInboundNatRule.Name;
        Assert-AreEqual $ProtocolAdd $vInboundNatRule.Protocol;
        Assert-AreEqual $FrontendPortAdd $vInboundNatRule.FrontendPort;
        Assert-AreEqual $BackendPortAdd $vInboundNatRule.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutesAdd $vInboundNatRule.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIPAdd $vInboundNatRule.EnableFloatingIP;
        Assert-AreEqual $EnableTcpResetAdd $vInboundNatRule.EnableTcpReset;

        
        $listInboundNatRule = Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerInboundNatRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolAdd -FrontendPort $FrontendPortAdd -BackendPort $BackendPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerInboundNatRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolSet -FrontendPort $FrontendPortSet -BackendPort $BackendPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-InboundNatPoolCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    $FrontendPortRangeStart = 555;
    $FrontendPortRangeEnd = 999;
    $BackendPort = 987;
    
    $ProtocolSet = "Tcp";
    $FrontendPortRangeStartSet = 777;
    $FrontendPortRangeEndSet = 888;
    $BackendPortSet = 789;
    
    $ProtocolAdd = "Tcp";
    $FrontendPortRangeStartAdd = 444;
    $FrontendPortRangeEndAdd = 445;
    $BackendPortAdd = 8080;
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;

        
        $vInboundNatPool = New-AzLoadBalancerInboundNatPoolConfig -Name $rname -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $Protocol -FrontendPortRangeStart $FrontendPortRangeStart -FrontendPortRangeEnd $FrontendPortRangeEnd -BackendPort $BackendPort;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -InboundNatPool $vInboundNatPool -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-AreEqual $rname $vInboundNatPool.Name;
        Assert-AreEqual $Protocol $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStart $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEnd $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPort $vInboundNatPool.BackendPort;

        
        $vInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        Assert-AreEqual $rname $vInboundNatPool.Name;
        Assert-AreEqual $Protocol $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStart $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEnd $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPort $vInboundNatPool.BackendPort;

        
        $listInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatPool | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerInboundNatPoolConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolSet -FrontendPortRangeStart $FrontendPortRangeStartSet -FrontendPortRangeEnd $FrontendPortRangeEndSet -BackendPort $BackendPortSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        Assert-AreEqual $rname $vInboundNatPool.Name;
        Assert-AreEqual $ProtocolSet $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStartSet $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEndSet $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPortSet $vInboundNatPool.BackendPort;

        
        $listInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatPool | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerInboundNatPoolConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolAdd -FrontendPortRangeStart $FrontendPortRangeStartAdd -FrontendPortRangeEnd $FrontendPortRangeEndAdd -BackendPort $BackendPortAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        Assert-AreEqual $rnameAdd $vInboundNatPool.Name;
        Assert-AreEqual $ProtocolAdd $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStartAdd $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEndAdd $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPortAdd $vInboundNatPool.BackendPort;

        
        $listInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatPool | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerInboundNatPoolConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolAdd -FrontendPortRangeStart $FrontendPortRangeStartAdd -FrontendPortRangeEnd $FrontendPortRangeEndAdd -BackendPort $BackendPortAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerInboundNatPoolConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolSet -FrontendPortRangeStart $FrontendPortRangeStartSet -FrontendPortRangeEnd $FrontendPortRangeEndSet -BackendPort $BackendPortSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-InboundNatPoolCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    $FrontendPortRangeStart = 555;
    $FrontendPortRangeEnd = 999;
    $BackendPort = 987;
    $IdleTimeoutInMinutes = 15;
    $EnableFloatingIP = $true;
    $EnableTcpReset = $false;
    
    $ProtocolSet = "Tcp";
    $FrontendPortRangeStartSet = 777;
    $FrontendPortRangeEndSet = 888;
    $BackendPortSet = 789;
    $IdleTimeoutInMinutesSet = 30;
    $EnableFloatingIPSet = $false;
    $EnableTcpResetSet = $false;
    
    $ProtocolAdd = "Tcp";
    $FrontendPortRangeStartAdd = 444;
    $FrontendPortRangeEndAdd = 445;
    $BackendPortAdd = 8080;
    $IdleTimeoutInMinutesAdd = 5;
    $EnableFloatingIPAdd = $false;
    $EnableTcpResetAdd = $false;
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;

        
        $vInboundNatPool = New-AzLoadBalancerInboundNatPoolConfig -Name $rname -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $Protocol -FrontendPortRangeStart $FrontendPortRangeStart -FrontendPortRangeEnd $FrontendPortRangeEnd -BackendPort $BackendPort -IdleTimeoutInMinutes $IdleTimeoutInMinutes -EnableFloatingIP;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -InboundNatPool $vInboundNatPool -FrontendIPConfiguration $FrontendIPConfiguration -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-AreEqual $rname $vInboundNatPool.Name;
        Assert-AreEqual $Protocol $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStart $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEnd $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPort $vInboundNatPool.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutes $vInboundNatPool.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIP $vInboundNatPool.EnableFloatingIP;
        Assert-AreEqual $EnableTcpReset $vInboundNatPool.EnableTcpReset;

        
        $vInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        Assert-AreEqual $rname $vInboundNatPool.Name;
        Assert-AreEqual $Protocol $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStart $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEnd $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPort $vInboundNatPool.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutes $vInboundNatPool.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIP $vInboundNatPool.EnableFloatingIP;
        Assert-AreEqual $EnableTcpReset $vInboundNatPool.EnableTcpReset;

        
        $listInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatPool | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerInboundNatPoolConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolSet -FrontendPortRangeStart $FrontendPortRangeStartSet -FrontendPortRangeEnd $FrontendPortRangeEndSet -BackendPort $BackendPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        Assert-AreEqual $rname $vInboundNatPool.Name;
        Assert-AreEqual $ProtocolSet $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStartSet $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEndSet $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPortSet $vInboundNatPool.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutesSet $vInboundNatPool.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIPSet $vInboundNatPool.EnableFloatingIP;
        Assert-AreEqual $EnableTcpResetSet $vInboundNatPool.EnableTcpReset;

        
        $listInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatPool | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerInboundNatPoolConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolAdd -FrontendPortRangeStart $FrontendPortRangeStartAdd -FrontendPortRangeEnd $FrontendPortRangeEndAdd -BackendPort $BackendPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vInboundNatPool;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerInboundNatPoolConfig" $vInboundNatPool };
        Assert-AreEqual $rnameAdd $vInboundNatPool.Name;
        Assert-AreEqual $ProtocolAdd $vInboundNatPool.Protocol;
        Assert-AreEqual $FrontendPortRangeStartAdd $vInboundNatPool.FrontendPortRangeStart;
        Assert-AreEqual $FrontendPortRangeEndAdd $vInboundNatPool.FrontendPortRangeEnd;
        Assert-AreEqual $BackendPortAdd $vInboundNatPool.BackendPort;
        Assert-AreEqual $IdleTimeoutInMinutesAdd $vInboundNatPool.IdleTimeoutInMinutes;
        Assert-AreEqual $EnableFloatingIPAdd $vInboundNatPool.EnableFloatingIP;
        Assert-AreEqual $EnableTcpResetAdd $vInboundNatPool.EnableTcpReset;

        
        $listInboundNatPool = Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listInboundNatPool | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerInboundNatPoolConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolAdd -FrontendPortRangeStart $FrontendPortRangeStartAdd -FrontendPortRangeEnd $FrontendPortRangeEndAdd -BackendPort $BackendPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerInboundNatPoolConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIpConfiguration $FrontendIPConfiguration -Protocol $ProtocolSet -FrontendPortRangeStart $FrontendPortRangeStartSet -FrontendPortRangeEnd $FrontendPortRangeEndSet -BackendPort $BackendPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-OutboundRuleCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    
    $ProtocolSet = "Tcp";
    
    $ProtocolAdd = "All";
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressNameAdd = "PublicIPAddressNameAdd";
    $PublicIPAddressAllocationMethod = "Static";
    $PublicIPAddressSku = "Standard";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";
    $FrontendIPConfigurationNameAdd = "FrontendIPConfigurationNameAdd";
    $BackendAddressPoolName = "BackendAddressPoolName";
    $BackendAddressPoolNameAdd = "BackendAddressPoolNameAdd";
    $LoadBalancerSku = "Standard";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod -Sku $PublicIPAddressSku;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;
        $BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName;
        $PublicIPAddressAdd = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressNameAdd -AllocationMethod $PublicIPAddressAllocationMethod -Sku $PublicIPAddressSku;
        $FrontendIPConfigurationAdd = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationNameAdd -PublicIpAddress $PublicIPAddressAdd;
        $BackendAddressPoolAdd = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolNameAdd;

        
        $vOutboundRule = New-AzLoadBalancerOutboundRuleConfig -Name $rname -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Protocol $Protocol;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -OutboundRule $vOutboundRule -Sku $LoadBalancerSku -FrontendIPConfiguration @($FrontendIPConfiguration, $FrontendIPConfigurationAdd) -BackendAddressPool @($BackendAddressPool, $BackendAddressPoolAdd) -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };
        Assert-AreEqual $rname $vOutboundRule.Name;
        Assert-AreEqual $Protocol $vOutboundRule.Protocol;

        
        $vOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        Assert-AreEqual $rname $vOutboundRule.Name;
        Assert-AreEqual $Protocol $vOutboundRule.Protocol;

        
        $listOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listOutboundRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerOutboundRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Protocol $ProtocolSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        Assert-AreEqual $rname $vOutboundRule.Name;
        Assert-AreEqual $ProtocolSet $vOutboundRule.Protocol;

        
        $listOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listOutboundRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerOutboundRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfigurationAdd -BackendAddressPool $BackendAddressPoolAdd -Protocol $ProtocolAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };

        
        $vOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        Assert-AreEqual $rnameAdd $vOutboundRule.Name;
        Assert-AreEqual $ProtocolAdd $vOutboundRule.Protocol;

        
        $listOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listOutboundRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerOutboundRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfigurationAdd -BackendAddressPool $BackendAddressPoolAdd -Protocol $ProtocolAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerOutboundRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Protocol $ProtocolSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-OutboundRuleCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers";
    
    $Protocol = "Udp";
    $AllocatedOutboundPort = 8;
    $EnableTcpReset = $false;
    $IdleTimeoutInMinutes = 15;
    
    $ProtocolSet = "Tcp";
    $AllocatedOutboundPortSet = 16;
    $EnableTcpResetSet = $false;
    $IdleTimeoutInMinutesSet = 20;
    
    $ProtocolAdd = "All";
    $AllocatedOutboundPortAdd = 24;
    $EnableTcpResetAdd = $false;
    $IdleTimeoutInMinutesAdd = 30;
    
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressNameAdd = "PublicIPAddressNameAdd";
    $PublicIPAddressAllocationMethod = "Static";
    $PublicIPAddressSku = "Standard";
    $FrontendIPConfigurationName = "FrontendIPConfigurationName";
    $FrontendIPConfigurationNameAdd = "FrontendIPConfigurationNameAdd";
    $BackendAddressPoolName = "BackendAddressPoolName";
    $BackendAddressPoolNameAdd = "BackendAddressPoolNameAdd";
    $LoadBalancerSku = "Standard";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod -Sku $PublicIPAddressSku;
        $FrontendIPConfiguration = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationName -PublicIpAddress $PublicIPAddress;
        $BackendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName;
        $PublicIPAddressAdd = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressNameAdd -AllocationMethod $PublicIPAddressAllocationMethod -Sku $PublicIPAddressSku;
        $FrontendIPConfigurationAdd = New-AzLoadBalancerFrontendIpConfig -Name $FrontendIPConfigurationNameAdd -PublicIpAddress $PublicIPAddressAdd;
        $BackendAddressPoolAdd = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolNameAdd;

        
        $vOutboundRule = New-AzLoadBalancerOutboundRuleConfig -Name $rname -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Protocol $Protocol -AllocatedOutboundPort $AllocatedOutboundPort -IdleTimeoutInMinutes $IdleTimeoutInMinutes;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "New-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        $vLoadBalancer = New-AzLoadBalancer -ResourceGroupName $rgname -Name $rname -OutboundRule $vOutboundRule -Sku $LoadBalancerSku -FrontendIPConfiguration @($FrontendIPConfiguration, $FrontendIPConfigurationAdd) -BackendAddressPool @($BackendAddressPool, $BackendAddressPoolAdd) -Location $location;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };
        Assert-AreEqual $rname $vOutboundRule.Name;
        Assert-AreEqual $Protocol $vOutboundRule.Protocol;
        Assert-AreEqual $AllocatedOutboundPort $vOutboundRule.AllocatedOutboundPorts;
        Assert-AreEqual $EnableTcpReset $vOutboundRule.EnableTcpReset;
        Assert-AreEqual $IdleTimeoutInMinutes $vOutboundRule.IdleTimeoutInMinutes;

        
        $vOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        Assert-AreEqual $rname $vOutboundRule.Name;
        Assert-AreEqual $Protocol $vOutboundRule.Protocol;
        Assert-AreEqual $AllocatedOutboundPort $vOutboundRule.AllocatedOutboundPorts;
        Assert-AreEqual $EnableTcpReset $vOutboundRule.EnableTcpReset;
        Assert-AreEqual $IdleTimeoutInMinutes $vOutboundRule.IdleTimeoutInMinutes;

        
        $listOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listOutboundRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Set-AzLoadBalancerOutboundRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Protocol $ProtocolSet -AllocatedOutboundPort $AllocatedOutboundPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        $vOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        Assert-AreEqual $rname $vOutboundRule.Name;
        Assert-AreEqual $ProtocolSet $vOutboundRule.Protocol;
        Assert-AreEqual $AllocatedOutboundPortSet $vOutboundRule.AllocatedOutboundPorts;
        Assert-AreEqual $EnableTcpResetSet $vOutboundRule.EnableTcpReset;
        Assert-AreEqual $IdleTimeoutInMinutesSet $vOutboundRule.IdleTimeoutInMinutes;

        
        $listOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listOutboundRule | Where-Object { $_.Name -eq $rname });

        
        $vLoadBalancer = Add-AzLoadBalancerOutboundRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfigurationAdd -BackendAddressPool $BackendAddressPoolAdd -Protocol $ProtocolAdd -AllocatedOutboundPort $AllocatedOutboundPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd;
        Assert-NotNull $vLoadBalancer;
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;
        Assert-NotNull $vLoadBalancer.FrontendIpConfigurations;
        Assert-True { $vLoadBalancer.FrontendIpConfigurations.Length -gt 0 };
        Assert-NotNull $vLoadBalancer.BackendAddressPools;
        Assert-True { $vLoadBalancer.BackendAddressPools.Length -gt 0 };

        
        $vOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        Assert-NotNull $vOutboundRule;
        Assert-True { Check-CmdletReturnType "Get-AzLoadBalancerOutboundRuleConfig" $vOutboundRule };
        Assert-AreEqual $rnameAdd $vOutboundRule.Name;
        Assert-AreEqual $ProtocolAdd $vOutboundRule.Protocol;
        Assert-AreEqual $AllocatedOutboundPortAdd $vOutboundRule.AllocatedOutboundPorts;
        Assert-AreEqual $EnableTcpResetAdd $vOutboundRule.EnableTcpReset;
        Assert-AreEqual $IdleTimeoutInMinutesAdd $vOutboundRule.IdleTimeoutInMinutes;

        
        $listOutboundRule = Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer;
        Assert-NotNull ($listOutboundRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzLoadBalancerOutboundRuleConfig -Name $rnameAdd -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfigurationAdd -BackendAddressPool $BackendAddressPoolAdd -Protocol $ProtocolAdd -AllocatedOutboundPort $AllocatedOutboundPortAdd -IdleTimeoutInMinutes $IdleTimeoutInMinutesAdd } "already exists";

        
        $vLoadBalancer = Remove-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rnameAdd;
        $vLoadBalancer = Remove-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Remove-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname;
        
        $vLoadBalancer = Set-AzLoadBalancer -LoadBalancer $vLoadBalancer;
        Assert-NotNull $vLoadBalancer;

        
        Assert-ThrowsContains { Get-AzLoadBalancerOutboundRuleConfig -LoadBalancer $vLoadBalancer -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzLoadBalancerOutboundRuleConfig -Name $rname -LoadBalancer $vLoadBalancer -FrontendIPConfiguration $FrontendIPConfiguration -BackendAddressPool $BackendAddressPool -Protocol $ProtocolSet -AllocatedOutboundPort $AllocatedOutboundPortSet -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
