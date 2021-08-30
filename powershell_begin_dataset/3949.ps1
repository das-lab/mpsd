

























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


function Test-RouteFilterCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/routeFilters";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vRouteFilter = New-AzRouteFilter -ResourceGroupName $rgname -Name $rname -Location $location;
        Assert-NotNull $vRouteFilter;
        Assert-True { Check-CmdletReturnType "New-AzRouteFilter" $vRouteFilter };
        Assert-AreEqual $rname $vRouteFilter.Name;

        
        $vRouteFilter = Get-AzRouteFilter -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vRouteFilter;
        Assert-True { Check-CmdletReturnType "Get-AzRouteFilter" $vRouteFilter };
        Assert-AreEqual $rname $vRouteFilter.Name;

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName $rgname;
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter;
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -Name "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $removeRouteFilter = Remove-AzRouteFilter -ResourceGroupName $rgname -Name $rname -PassThru -Force;
        Assert-AreEqual $true $removeRouteFilter;

        
        Assert-ThrowsContains { Get-AzRouteFilter -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-RouteFilterCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/routeFilters";
    
    $Tag = @{tag1='test'};
    
    $TagSet = @{tag2='testSet'};

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vRouteFilter = New-AzRouteFilter -ResourceGroupName $rgname -Name $rname -Location $location -Tag $Tag;
        Assert-NotNull $vRouteFilter;
        Assert-True { Check-CmdletReturnType "New-AzRouteFilter" $vRouteFilter };
        Assert-AreEqual $rname $vRouteFilter.Name;
        Assert-AreEqualObjectProperties $Tag $vRouteFilter.Tag;

        
        $vRouteFilter = Get-AzRouteFilter -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vRouteFilter;
        Assert-True { Check-CmdletReturnType "Get-AzRouteFilter" $vRouteFilter };
        Assert-AreEqual $rname $vRouteFilter.Name;
        Assert-AreEqualObjectProperties $Tag $vRouteFilter.Tag;

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName $rgname;
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter;
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -Name "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vRouteFilter.Tag = $TagSet;
        $vRouteFilter = Set-AzRouteFilter -RouteFilter $vRouteFilter -Force;
        Assert-NotNull $vRouteFilter;
        Assert-True { Check-CmdletReturnType "Set-AzRouteFilter" $vRouteFilter };
        Assert-AreEqual $rname $vRouteFilter.Name;
        Assert-AreEqualObjectProperties $TagSet $vRouteFilter.Tag;

        
        $vRouteFilter = Get-AzRouteFilter -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vRouteFilter;
        Assert-True { Check-CmdletReturnType "Get-AzRouteFilter" $vRouteFilter };
        Assert-AreEqual $rname $vRouteFilter.Name;
        Assert-AreEqualObjectProperties $TagSet $vRouteFilter.Tag;

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName $rgname;
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter;
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -Name "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listRouteFilter = Get-AzRouteFilter -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listRouteFilter | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $removeRouteFilter = Remove-AzRouteFilter -ResourceGroupName $rgname -Name $rname -PassThru -Force;
        Assert-AreEqual $true $removeRouteFilter;

        
        Assert-ThrowsContains { Get-AzRouteFilter -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-RouteFilterRuleCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/routeFilters";
    
    $AccessSet = "Deny";
    $RouteFilterRuleTypeSet = "Community";
    $CommunityListSet = @("12076:5010","12076:5040");
    
    $AccessAdd = "Allow";
    $RouteFilterRuleTypeAdd = "Community";
    $CommunityListAdd = @("12076:5040");

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vRouteFilter = New-AzRouteFilter -ResourceGroupName $rgname -Name $rname -Location $location;
        Assert-NotNull $vRouteFilter;

        
        $vRouteFilter = Add-AzRouteFilterRuleConfig -Name $rnameAdd -RouteFilter $vRouteFilter -Access $AccessAdd -RouteFilterRuleType $RouteFilterRuleTypeAdd -CommunityList $CommunityListAdd -Force;
        Assert-NotNull $vRouteFilter;
        $vRouteFilter = Set-AzRouteFilter -RouteFilter $vRouteFilter -Force;
        Assert-NotNull $vRouteFilter;

        
        $vRouteFilterRule = Get-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter -Name $rnameAdd;
        Assert-NotNull $vRouteFilterRule;
        Assert-True { Check-CmdletReturnType "Get-AzRouteFilterRuleConfig" $vRouteFilterRule };
        Assert-AreEqual $rnameAdd $vRouteFilterRule.Name;
        Assert-AreEqual $AccessAdd $vRouteFilterRule.Access;
        Assert-AreEqualArray $CommunityListAdd $vRouteFilterRule.Communities;

        
        $listRouteFilterRule = Get-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter;
        Assert-NotNull ($listRouteFilterRule | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzRouteFilterRuleConfig -Name $rnameAdd -RouteFilter $vRouteFilter -Access $AccessAdd -RouteFilterRuleType $RouteFilterRuleTypeAdd -CommunityList $CommunityListAdd -Force } "already exists";

        
        $vRouteFilter = Set-AzRouteFilterRuleConfig -Name $rnameAdd -RouteFilter $vRouteFilter -Access $AccessSet -RouteFilterRuleType $RouteFilterRuleTypeSet -CommunityList $CommunityListSet -Force;
        Assert-NotNull $vRouteFilter;
        $vRouteFilter = Set-AzRouteFilter -RouteFilter $vRouteFilter -Force;
        Assert-NotNull $vRouteFilter;

        
        $vRouteFilterRule = Get-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter -Name $rnameAdd;
        Assert-NotNull $vRouteFilterRule;
        Assert-True { Check-CmdletReturnType "Get-AzRouteFilterRuleConfig" $vRouteFilterRule };
        Assert-AreEqual $rnameAdd $vRouteFilterRule.Name;
        Assert-AreEqual $AccessSet $vRouteFilterRule.Access;
        Assert-AreEqualArray $CommunityListSet $vRouteFilterRule.Communities;

        
        $listRouteFilterRule = Get-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter;
        Assert-NotNull ($listRouteFilterRule | Where-Object { $_.Name -eq $rnameAdd });

        
        $vRouteFilter = Remove-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter -Name $rnameAdd -Force;
        $vRouteFilter = Remove-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter -Name $rname -Force;
        
        $vRouteFilter = Remove-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter -Name $rname -Force;
        
        $vRouteFilter = Set-AzRouteFilter -RouteFilter $vRouteFilter -Force;
        Assert-NotNull $vRouteFilter;

        
        Assert-ThrowsContains { Get-AzRouteFilterRuleConfig -RouteFilter $vRouteFilter -Name $rnameAdd } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzRouteFilterRuleConfig -Name $rnameAdd -RouteFilter $vRouteFilter -Access $AccessSet -RouteFilterRuleType $RouteFilterRuleTypeSet -CommunityList $CommunityListSet -Force } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
