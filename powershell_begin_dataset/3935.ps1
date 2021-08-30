

























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


function Test-NetworkInterfaceCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/networkInterfaces" "West Central US";
    
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

        
        $vNetworkInterface = New-AzNetworkInterface -ResourceGroupName $rgname -Name $rname -Location $location -Subnet $Subnet;
        Assert-NotNull $vNetworkInterface;
        Assert-True { Check-CmdletReturnType "New-AzNetworkInterface" $vNetworkInterface };
        $vIpConfiguration = $vNetworkInterface.IpConfigurations | Where-Object { $_.Name -eq "ipconfig1" };
        Assert-NotNull $vIpConfiguration;
        Assert-NotNull $vIpConfiguration.Subnet;
        Assert-AreEqual $rname $vNetworkInterface.Name;

        
        $vNetworkInterface = Get-AzNetworkInterface -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNetworkInterface;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterface" $vNetworkInterface };
        Assert-AreEqual $rname $vNetworkInterface.Name;

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName $rgname;
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface;
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -Name "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzNetworkInterface -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeNetworkInterface = $job | Receive-Job;
        Assert-AreEqual $true $removeNetworkInterface;

        
        Assert-ThrowsContains { Get-AzNetworkInterface -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NetworkInterfaceCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/networkInterfaces" "West Central US";
    
    $PrivateIPAddress = "10.0.1.42";
    $IpConfigurationName = "createipconf";
    $InternalDnsNameLabel = "internal-dns-foo";
    $EnableAcceleratedNetworking = $false;
    $EnableIPForwarding = $false;
    
    $InternalDnsNameLabelSet = "internal-dns-bar";
    $EnableAcceleratedNetworkingSet = $true;
    $EnableIPForwardingSet = $true;
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;

        
        $vNetworkInterface = New-AzNetworkInterface -ResourceGroupName $rgname -Name $rname -Location $location -Subnet $Subnet -PublicIPAddress $PublicIPAddress -PrivateIPAddress $PrivateIPAddress -IpConfigurationName $IpConfigurationName -InternalDnsNameLabel $InternalDnsNameLabel;
        Assert-NotNull $vNetworkInterface;
        Assert-True { Check-CmdletReturnType "New-AzNetworkInterface" $vNetworkInterface };
        $vIpConfiguration = $vNetworkInterface.IpConfigurations | Where-Object { $_.Name -eq $IpConfigurationName };
        Assert-NotNull $vIpConfiguration;
        Assert-NotNull $vIpConfiguration.Subnet;
        Assert-NotNull $vIpConfiguration.PublicIPAddress;
        Assert-AreEqual $rname $vNetworkInterface.Name;
        Assert-AreEqual $PrivateIPAddress $vNetworkInterface.IpConfigurations[0].PrivateIpAddress;
        Assert-AreEqual $IpConfigurationName $vNetworkInterface.IpConfigurations[0].Name;
        Assert-AreEqual $InternalDnsNameLabel $vNetworkInterface.DnsSettings.InternalDnsNameLabel;
        Assert-AreEqual $EnableAcceleratedNetworking $vNetworkInterface.EnableAcceleratedNetworking;
        Assert-AreEqual $EnableIPForwarding $vNetworkInterface.EnableIPForwarding;

        
        $vNetworkInterface = Get-AzNetworkInterface -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNetworkInterface;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterface" $vNetworkInterface };
        Assert-AreEqual $rname $vNetworkInterface.Name;
        Assert-AreEqual $PrivateIPAddress $vNetworkInterface.IpConfigurations[0].PrivateIpAddress;
        Assert-AreEqual $IpConfigurationName $vNetworkInterface.IpConfigurations[0].Name;
        Assert-AreEqual $InternalDnsNameLabel $vNetworkInterface.DnsSettings.InternalDnsNameLabel;
        Assert-AreEqual $EnableAcceleratedNetworking $vNetworkInterface.EnableAcceleratedNetworking;
        Assert-AreEqual $EnableIPForwarding $vNetworkInterface.EnableIPForwarding;

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName $rgname;
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface;
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -Name "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vNetworkInterface.DnsSettings.InternalDnsNameLabel = $InternalDnsNameLabelSet;
        $vNetworkInterface.EnableAcceleratedNetworking = $EnableAcceleratedNetworkingSet;
        $vNetworkInterface.EnableIPForwarding = $EnableIPForwardingSet;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;
        Assert-True { Check-CmdletReturnType "Set-AzNetworkInterface" $vNetworkInterface };
        Assert-AreEqual $rname $vNetworkInterface.Name;
        Assert-AreEqual $InternalDnsNameLabelSet $vNetworkInterface.DnsSettings.InternalDnsNameLabel;
        Assert-AreEqual $EnableAcceleratedNetworkingSet $vNetworkInterface.EnableAcceleratedNetworking;
        Assert-AreEqual $EnableIPForwardingSet $vNetworkInterface.EnableIPForwarding;

        
        $vNetworkInterface = Get-AzNetworkInterface -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNetworkInterface;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterface" $vNetworkInterface };
        Assert-AreEqual $rname $vNetworkInterface.Name;
        Assert-AreEqual $InternalDnsNameLabelSet $vNetworkInterface.DnsSettings.InternalDnsNameLabel;
        Assert-AreEqual $EnableAcceleratedNetworkingSet $vNetworkInterface.EnableAcceleratedNetworking;
        Assert-AreEqual $EnableIPForwardingSet $vNetworkInterface.EnableIPForwarding;

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName $rgname;
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface;
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -Name "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNetworkInterface = Get-AzNetworkInterface -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNetworkInterface | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzNetworkInterface -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeNetworkInterface = $job | Receive-Job;
        Assert-AreEqual $true $removeNetworkInterface;

        
        Assert-ThrowsContains { Get-AzNetworkInterface -ResourceGroupName $rgname -Name $rname } "not found";

        
        Assert-ThrowsContains { Set-AzNetworkInterface -NetworkInterface $vNetworkInterface } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NetworkInterfaceIpConfigurationCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/networkInterfaces" "West Central US";
    
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

        
        $vNetworkInterfaceIpConfiguration = New-AzNetworkInterfaceIpConfig -Name $rname -Subnet $Subnet;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "New-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        $vNetworkInterface = New-AzNetworkInterface -ResourceGroupName $rgname -Name $rname -IpConfiguration $vNetworkInterfaceIpConfiguration -Location $location;
        Assert-NotNull $vNetworkInterface;
        Assert-AreEqual $rname $vNetworkInterfaceIpConfiguration.Name;

        
        $vNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rname;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        Assert-AreEqual $rname $vNetworkInterfaceIpConfiguration.Name;

        
        $listNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface;
        Assert-NotNull ($listNetworkInterfaceIpConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vNetworkInterface = Set-AzNetworkInterfaceIpConfig -Name $rname -NetworkInterface $vNetworkInterface -Subnet $Subnet;
        Assert-NotNull $vNetworkInterface;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;

        
        $vNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rname;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        Assert-AreEqual $rname $vNetworkInterfaceIpConfiguration.Name;

        
        $listNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface;
        Assert-NotNull ($listNetworkInterfaceIpConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vNetworkInterface = Add-AzNetworkInterfaceIpConfig -Name $rnameAdd -NetworkInterface $vNetworkInterface -SubnetId $Subnet.Id;
        Assert-NotNull $vNetworkInterface;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;

        
        $vNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rnameAdd;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        Assert-AreEqual $rnameAdd $vNetworkInterfaceIpConfiguration.Name;

        
        $listNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface;
        Assert-NotNull ($listNetworkInterfaceIpConfiguration | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzNetworkInterfaceIpConfig -Name $rnameAdd -NetworkInterface $vNetworkInterface -SubnetId $Subnet.Id } "already exists";

        
        $vNetworkInterface = Remove-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rnameAdd;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;

        
        Assert-ThrowsContains { Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rnameAdd } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzNetworkInterfaceIpConfig -Name $rnameAdd -NetworkInterface $vNetworkInterface -Subnet $Subnet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NetworkInterfaceIpConfigurationCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/networkInterfaces" "West Central US";
    
    $PrivateIPAddress = "10.0.1.13";
    $PrivateIPAddressVersion = "IPv4";
    $Primary = $true;
    
    $PrivateIPAddressSet = "10.0.1.41";
    $PrimarySet = $true;
    
    $PrivateIPAddressAdd = "10.0.1.42";
    $PrimaryAdd = $false;
    
    $SubnetName = "SubnetName";
    $SubnetAddressPrefix = "10.0.1.0/24";
    $VirtualNetworkName = "VirtualNetworkName";
    $VirtualNetworkAddressPrefix = @("10.0.0.0/8");
    $PublicIPAddressName = "PublicIPAddressName";
    $PublicIPAddressAllocationMethod = "Static";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix;
        $VirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $VirtualNetworkName -Subnet $Subnet -AddressPrefix $VirtualNetworkAddressPrefix;
        if(-not $Subnet.Id)
        {
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork;
        }
        $PublicIPAddress = New-AzPublicIPAddress -ResourceGroupName $rgname -Location $location -Name $PublicIPAddressName -AllocationMethod $PublicIPAddressAllocationMethod;

        
        $vNetworkInterfaceIpConfiguration = New-AzNetworkInterfaceIpConfig -Name $rname -Subnet $Subnet -PublicIPAddress $PublicIPAddress -PrivateIPAddress $PrivateIPAddress -PrivateIPAddressVersion $PrivateIPAddressVersion -Primary;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "New-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        $vNetworkInterface = New-AzNetworkInterface -ResourceGroupName $rgname -Name $rname -IpConfiguration $vNetworkInterfaceIpConfiguration -Location $location;
        Assert-NotNull $vNetworkInterface;
        Assert-AreEqual $rname $vNetworkInterfaceIpConfiguration.Name;
        Assert-AreEqual $PrivateIPAddress $vNetworkInterfaceIpConfiguration.PrivateIpAddress;
        Assert-AreEqual $PrivateIPAddressVersion $vNetworkInterfaceIpConfiguration.PrivateIpAddressVersion;
        Assert-AreEqual $Primary $vNetworkInterfaceIpConfiguration.Primary;

        
        $vNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rname;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        Assert-AreEqual $rname $vNetworkInterfaceIpConfiguration.Name;
        Assert-AreEqual $PrivateIPAddress $vNetworkInterfaceIpConfiguration.PrivateIpAddress;
        Assert-AreEqual $PrivateIPAddressVersion $vNetworkInterfaceIpConfiguration.PrivateIpAddressVersion;
        Assert-AreEqual $Primary $vNetworkInterfaceIpConfiguration.Primary;

        
        $listNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface;
        Assert-NotNull ($listNetworkInterfaceIpConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vNetworkInterface = Set-AzNetworkInterfaceIpConfig -Name $rname -NetworkInterface $vNetworkInterface -Subnet $Subnet -PrivateIPAddress $PrivateIPAddressSet -Primary;
        Assert-NotNull $vNetworkInterface;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;

        
        $vNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rname;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        Assert-AreEqual $rname $vNetworkInterfaceIpConfiguration.Name;
        Assert-AreEqual $PrivateIPAddressSet $vNetworkInterfaceIpConfiguration.PrivateIpAddress;
        Assert-AreEqual $PrimarySet $vNetworkInterfaceIpConfiguration.Primary;

        
        $listNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface;
        Assert-NotNull ($listNetworkInterfaceIpConfiguration | Where-Object { $_.Name -eq $rname });

        
        $vNetworkInterface = Add-AzNetworkInterfaceIpConfig -Name $rnameAdd -NetworkInterface $vNetworkInterface -SubnetId $Subnet.Id -PublicIPAddressId $PublicIPAddress.Id -PrivateIPAddress $PrivateIPAddressAdd;
        Assert-NotNull $vNetworkInterface;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;

        
        $vNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rnameAdd;
        Assert-NotNull $vNetworkInterfaceIpConfiguration;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkInterfaceIpConfig" $vNetworkInterfaceIpConfiguration };
        Assert-AreEqual $rnameAdd $vNetworkInterfaceIpConfiguration.Name;
        Assert-AreEqual $PrivateIPAddressAdd $vNetworkInterfaceIpConfiguration.PrivateIpAddress;
        Assert-AreEqual $PrimaryAdd $vNetworkInterfaceIpConfiguration.Primary;

        
        $listNetworkInterfaceIpConfiguration = Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface;
        Assert-NotNull ($listNetworkInterfaceIpConfiguration | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzNetworkInterfaceIpConfig -Name $rnameAdd -NetworkInterface $vNetworkInterface -SubnetId $Subnet.Id -PublicIPAddressId $PublicIPAddress.Id -PrivateIPAddress $PrivateIPAddressAdd } "already exists";

        
        $vNetworkInterface = Remove-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rnameAdd;
        $vNetworkInterface = Set-AzNetworkInterface -NetworkInterface $vNetworkInterface;
        Assert-NotNull $vNetworkInterface;

        
        Assert-ThrowsContains { Get-AzNetworkInterfaceIpConfig -NetworkInterface $vNetworkInterface -Name $rnameAdd } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzNetworkInterfaceIpConfig -Name $rnameAdd -NetworkInterface $vNetworkInterface -Subnet $Subnet -PrivateIPAddress $PrivateIPAddressSet -Primary } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NetworkInterfaceGetEffectiveRouteTable
{
    param
    (
        $basedir = "./"
    )

    . ($basedir + "/ScenarioTests/Utils/Import-GeneratedTestUtils.ps1")

    
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    
    $rgName = Get-ResourceGroupName;
    $location = Get-ProviderLocation "Microsoft.Network/networkInterfaces" "West Central US";
    $virtualMachineName = Get-ResourceName;
    $storageAccountName = Get-ResourceName;
    $routeTableName = Get-ResourceName;
    $networkInterfaceName = Get-ResourceName;
    $networkSecurityGroupName = Get-ResourceName;
    $virtualNetworkName = Get-ResourceName;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $env = Get-TestDeployment -rgName $rgName `
                                  -location $location `
                                  -virtualMachineName $virtualMachineName `
                                  -storageAccountName $storageAccountName `
                                  -routeTableName $routeTableName `
                                  -networkInterfaceName $networkInterfaceName `
                                  -networkSecurityGroupName $networkSecurityGroupName `
                                  -virtualNetworkName $virtualNetworkName;

        
        $job = Get-AzEffectiveRouteTable -ResourceGroupName $rgname -NetworkInterfaceName $env.networkInterfaceName -AsJob;
        $job | Wait-Job;
        $vEffectiveRouteTable = $job | Receive-Job;
        Assert-NotNull $vEffectiveRouteTable;
        Assert-True { Check-CmdletReturnType "Get-AzEffectiveRouteTable" $vEffectiveRouteTable };

        
        $vEffectiveNetworkSecurityGroups = Get-AzEffectiveNetworkSecurityGroup -ResourceGroupName $rgname -NetworkInterfaceName $env.networkInterfaceName;
        Assert-NotNull $vEffectiveNetworkSecurityGroups;
        Assert-True { Check-CmdletReturnType "Get-AzEffectiveNetworkSecurityGroup" $vEffectiveNetworkSecurityGroups };
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
