
























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


function Test-NatGatewayCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US 2";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vNatGateway = New-AzNatGateway -ResourceGroupName $rgname -Name $rname -Location $location -Sku Standard -Zone "1";
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "New-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;
        Assert-AreEqual $vNatGateway.Zones.Count 1;
        Assert-AreEqual $vNatGateway.Zones[0] "1";

        
        $vNatGateway = Get-AzNatGateway -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "Get-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;
        Assert-AreEqual $vNatGateway.Zones.Count 1;
        Assert-AreEqual $vNatGateway.Zones[0] "1";

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName $rgname;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzNatGateway -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeNatGateway = $job | Receive-Job;
        Assert-AreEqual $true $removeNatGateway;

        
        Assert-ThrowsContains { Get-AzNatGateway -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NatGatewayWithSubnet
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
	$vnetName = Get-ResourceName;
    $subnetName = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US 2";
	$sku = "Standard";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vNatGateway = New-AzNatGateway -ResourceGroupName $rgname -Name $rname -Location $location -sku $sku;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "New-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;

        
        $vNatGateway = Get-AzNatGateway -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "Get-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName $rgname;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -InputObject $vNatGateway
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname

        
        $subnet2 = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname | Get-AzVirtualNetworkSubnetConfig -Name $subnetName;

        Assert-AreEqual $vNatGateway.Id @($subnet2.NatGateway.Id)

        
        Remove-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
        Set-AzVirtualNetwork -VirtualNetwork $vnet

        
        $job = Remove-AzNatGateway -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeNatGateway = $job | Receive-Job;
        Assert-AreEqual $true $removeNatGateway;

        
        Assert-ThrowsContains { Get-AzNatGateway -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NatGatewayCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US 2";
    
    $IdleTimeoutInMinutes = 5;
    $Tag = @{tag1='test'};
    
    $IdleTimeoutInMinutesSet = 10;
    $TagSet = @{tag2='testSet'};

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vNatGateway = New-AzNatGateway -ResourceGroupName $rgname -Name $rname -Location $location -IdleTimeoutInMinutes $IdleTimeoutInMinutes -Tag $Tag -Sku Standard;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "New-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;
        Assert-AreEqual $IdleTimeoutInMinutes $vNatGateway.IdleTimeoutInMinutes;
        Assert-AreEqualObjectProperties $Tag $vNatGateway.Tag;

        
        $vNatGateway = Get-AzNatGateway -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "Get-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;
        Assert-AreEqual $IdleTimeoutInMinutes $vNatGateway.IdleTimeoutInMinutes;
        Assert-AreEqualObjectProperties $Tag $vNatGateway.Tag;

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName $rgname;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vNatGateway.Tag = $TagSet;
        $vNatGateway = Set-AzNatGateway -InputObject $vNatGateway -IdleTimeoutInMinutes $IdleTimeoutInMinutesSet;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "Set-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;
        Assert-AreEqual $IdleTimeoutInMinutesSet $vNatGateway.IdleTimeoutInMinutes;
        Assert-AreEqualObjectProperties $TagSet $vNatGateway.Tag;

        
        $vNatGateway = Get-AzNatGateway -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vNatGateway;
        Assert-True { Check-CmdletReturnType "Get-AzNatGateway" $vNatGateway };
        Assert-AreEqual $rname $vNatGateway.Name;
        Assert-AreEqual $IdleTimeoutInMinutesSet $vNatGateway.IdleTimeoutInMinutes;
        Assert-AreEqualObjectProperties $TagSet $vNatGateway.Tag;

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName $rgname;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway;
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listNatGateway = Get-AzNatGateway -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listNatGateway | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzNatGateway -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeNatGateway = $job | Receive-Job;
        Assert-AreEqual $true $removeNatGateway;

        
        Assert-ThrowsContains { Get-AzNatGateway -ResourceGroupName $rgname -Name $rname } "not found";

        
        Assert-ThrowsContains { Set-AzNatGateway -InputObject $vNatGateway } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
