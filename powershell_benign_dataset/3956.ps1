

























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


function Test-RouteTableCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/routeTables";
    
    $RouteName = "RouteName";
    $RouteAddressPrefix = "10.0.0.0/8";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Route = New-AzRouteConfig -Name $RouteName -AddressPrefix $RouteAddressPrefix;

        
        $vRouteTable = New-AzRouteTable -ResourceGroupName $rgname -Name $rname -Location $location -Route $Route;
        Assert-NotNull $vRouteTable;
        Assert-True { Check-CmdletReturnType "New-AzRouteTable" $vRouteTable };
        Assert-NotNull $vRouteTable.Routes;
        Assert-True { $vRouteTable.Routes.Length -gt 0 };
        Assert-AreEqual $rname $vRouteTable.Name;

        
        $vRouteTable = Get-AzRouteTable -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vRouteTable;
        Assert-True { Check-CmdletReturnType "Get-AzRouteTable" $vRouteTable };
        Assert-AreEqual $rname $vRouteTable.Name;

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName $rgname;
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable;
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -Name "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzRouteTable -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeRouteTable = $job | Receive-Job;
        Assert-AreEqual $true $removeRouteTable;

        
        Assert-ThrowsContains { Get-AzRouteTable -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-RouteTableCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/routeTables";
    
    $Tag = @{tag1='test'};
    
    $TagSet = @{tag2='testSet'};
    
    $RouteName = "RouteName";
    $RouteAddressPrefix = "10.0.0.0/8";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $Route = New-AzRouteConfig -Name $RouteName -AddressPrefix $RouteAddressPrefix;

        
        $vRouteTable = New-AzRouteTable -ResourceGroupName $rgname -Name $rname -Location $location -Route $Route -Tag $Tag;
        Assert-NotNull $vRouteTable;
        Assert-True { Check-CmdletReturnType "New-AzRouteTable" $vRouteTable };
        Assert-NotNull $vRouteTable.Routes;
        Assert-True { $vRouteTable.Routes.Length -gt 0 };
        Assert-AreEqual $rname $vRouteTable.Name;
        Assert-AreEqualObjectProperties $Tag $vRouteTable.Tag;

        
        $vRouteTable = Get-AzRouteTable -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vRouteTable;
        Assert-True { Check-CmdletReturnType "Get-AzRouteTable" $vRouteTable };
        Assert-AreEqual $rname $vRouteTable.Name;
        Assert-AreEqualObjectProperties $Tag $vRouteTable.Tag;

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName $rgname;
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable;
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -Name "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vRouteTable.Tag = $TagSet;
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;
        Assert-True { Check-CmdletReturnType "Set-AzRouteTable" $vRouteTable };
        Assert-AreEqual $rname $vRouteTable.Name;
        Assert-AreEqualObjectProperties $TagSet $vRouteTable.Tag;

        
        $vRouteTable = Get-AzRouteTable -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vRouteTable;
        Assert-True { Check-CmdletReturnType "Get-AzRouteTable" $vRouteTable };
        Assert-AreEqual $rname $vRouteTable.Name;
        Assert-AreEqualObjectProperties $TagSet $vRouteTable.Tag;

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName $rgname;
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable;
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -Name "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteTable = Get-AzRouteTable -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listRouteTable | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzRouteTable -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeRouteTable = $job | Receive-Job;
        Assert-AreEqual $true $removeRouteTable;

        
        Assert-ThrowsContains { Get-AzRouteTable -ResourceGroupName $rgname -Name $rname } "not found";

        
        Assert-ThrowsContains { Set-AzRouteTable -RouteTable $vRouteTable } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-RouteCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/routeTables";
    
    $AddressPrefix = "10.0.0.0/8";
    
    $AddressPrefixSet = "11.0.0.0/8";
    
    $AddressPrefixAdd = "12.0.0.0/8";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vRoute = New-AzRouteConfig -Name $rname -AddressPrefix $AddressPrefix;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "New-AzRouteConfig" $vRoute };
        $vRouteTable = New-AzRouteTable -ResourceGroupName $rgname -Name $rname -Route $vRoute -Location $location;
        Assert-NotNull $vRouteTable;
        Assert-AreEqual $rname $vRoute.Name;
        Assert-AreEqual $AddressPrefix $vRoute.AddressPrefix;

        
        $vRoute = Get-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "Get-AzRouteConfig" $vRoute };
        Assert-AreEqual $rname $vRoute.Name;
        Assert-AreEqual $AddressPrefix $vRoute.AddressPrefix;

        
        $listRoute = Get-AzRouteConfig -RouteTable $vRouteTable;
        Assert-NotNull ($listRoute | Where-Object { $_.Name -eq $rname });

        
        $vRouteTable = Set-AzRouteConfig -Name $rname -RouteTable $vRouteTable -AddressPrefix $AddressPrefixSet;
        Assert-NotNull $vRouteTable;
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;

        
        $vRoute = Get-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "Get-AzRouteConfig" $vRoute };
        Assert-AreEqual $rname $vRoute.Name;
        Assert-AreEqual $AddressPrefixSet $vRoute.AddressPrefix;

        
        $listRoute = Get-AzRouteConfig -RouteTable $vRouteTable;
        Assert-NotNull ($listRoute | Where-Object { $_.Name -eq $rname });

        
        $vRouteTable = Add-AzRouteConfig -Name $rnameAdd -RouteTable $vRouteTable -AddressPrefix $AddressPrefixAdd;
        Assert-NotNull $vRouteTable;
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;

        
        $vRoute = Get-AzRouteConfig -RouteTable $vRouteTable -Name $rnameAdd;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "Get-AzRouteConfig" $vRoute };
        Assert-AreEqual $rnameAdd $vRoute.Name;
        Assert-AreEqual $AddressPrefixAdd $vRoute.AddressPrefix;

        
        $listRoute = Get-AzRouteConfig -RouteTable $vRouteTable;
        Assert-NotNull ($listRoute | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzRouteConfig -Name $rnameAdd -RouteTable $vRouteTable -AddressPrefix $AddressPrefixAdd } "already exists";

        
        $vRouteTable = Remove-AzRouteConfig -RouteTable $vRouteTable -Name $rnameAdd;
        $vRouteTable = Remove-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        
        $vRouteTable = Remove-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;

        
        Assert-ThrowsContains { Get-AzRouteConfig -RouteTable $vRouteTable -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzRouteConfig -Name $rname -RouteTable $vRouteTable -AddressPrefix $AddressPrefixSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-RouteCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/routeTables";
    
    $AddressPrefix = "10.0.0.0/8";
    $NextHopType = "VirtualNetworkGateway";
    
    $AddressPrefixSet = "11.0.0.0/8";
    $NextHopTypeSet = "VnetLocal";
    
    $AddressPrefixAdd = "12.0.0.0/8";
    $NextHopTypeAdd = "VnetLocal";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vRoute = New-AzRouteConfig -Name $rname -AddressPrefix $AddressPrefix -NextHopType $NextHopType;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "New-AzRouteConfig" $vRoute };
        $vRouteTable = New-AzRouteTable -ResourceGroupName $rgname -Name $rname -Route $vRoute -Location $location;
        Assert-NotNull $vRouteTable;
        Assert-AreEqual $rname $vRoute.Name;
        Assert-AreEqual $AddressPrefix $vRoute.AddressPrefix;
        Assert-AreEqual $NextHopType $vRoute.NextHopType;

        
        $vRoute = Get-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "Get-AzRouteConfig" $vRoute };
        Assert-AreEqual $rname $vRoute.Name;
        Assert-AreEqual $AddressPrefix $vRoute.AddressPrefix;
        Assert-AreEqual $NextHopType $vRoute.NextHopType;

        
        $listRoute = Get-AzRouteConfig -RouteTable $vRouteTable;
        Assert-NotNull ($listRoute | Where-Object { $_.Name -eq $rname });

        
        $vRouteTable = Set-AzRouteConfig -Name $rname -RouteTable $vRouteTable -AddressPrefix $AddressPrefixSet -NextHopType $NextHopTypeSet;
        Assert-NotNull $vRouteTable;
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;

        
        $vRoute = Get-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "Get-AzRouteConfig" $vRoute };
        Assert-AreEqual $rname $vRoute.Name;
        Assert-AreEqual $AddressPrefixSet $vRoute.AddressPrefix;
        Assert-AreEqual $NextHopTypeSet $vRoute.NextHopType;

        
        $listRoute = Get-AzRouteConfig -RouteTable $vRouteTable;
        Assert-NotNull ($listRoute | Where-Object { $_.Name -eq $rname });

        
        $vRouteTable = Add-AzRouteConfig -Name $rnameAdd -RouteTable $vRouteTable -AddressPrefix $AddressPrefixAdd -NextHopType $NextHopTypeAdd;
        Assert-NotNull $vRouteTable;
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;

        
        $vRoute = Get-AzRouteConfig -RouteTable $vRouteTable -Name $rnameAdd;
        Assert-NotNull $vRoute;
        Assert-True { Check-CmdletReturnType "Get-AzRouteConfig" $vRoute };
        Assert-AreEqual $rnameAdd $vRoute.Name;
        Assert-AreEqual $AddressPrefixAdd $vRoute.AddressPrefix;
        Assert-AreEqual $NextHopTypeAdd $vRoute.NextHopType;

        
        $listRoute = Get-AzRouteConfig -RouteTable $vRouteTable;
        Assert-NotNull ($listRoute | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzRouteConfig -Name $rnameAdd -RouteTable $vRouteTable -AddressPrefix $AddressPrefixAdd -NextHopType $NextHopTypeAdd } "already exists";

        
        $vRouteTable = Remove-AzRouteConfig -RouteTable $vRouteTable -Name $rnameAdd;
        $vRouteTable = Remove-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        
        $vRouteTable = Remove-AzRouteConfig -RouteTable $vRouteTable -Name $rname;
        
        $vRouteTable = Set-AzRouteTable -RouteTable $vRouteTable;
        Assert-NotNull $vRouteTable;

        
        Assert-ThrowsContains { Get-AzRouteConfig -RouteTable $vRouteTable -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzRouteConfig -Name $rname -RouteTable $vRouteTable -AddressPrefix $AddressPrefixSet -NextHopType $NextHopTypeSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
