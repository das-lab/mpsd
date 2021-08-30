

























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


function Test-ExpressRouteCircuitCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/expressRouteCircuits" "Brazil South";
    
    $SkuTier = "Standard";
    $SkuFamily = "MeteredData";
    $ServiceProviderName = "Interxion";
    $PeeringLocation = "London";
    $BandwidthInMbps = 100;
    
    $SkuTierSet = "Premium";
    $SkuFamilySet = "UnlimitedData";
    $BandwidthInMbpsSet = 200;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vExpressRouteCircuit = New-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -Location $location -SkuTier $SkuTier -SkuFamily $SkuFamily -ServiceProviderName $ServiceProviderName -PeeringLocation $PeeringLocation -BandwidthInMbps $BandwidthInMbps;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "New-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTier $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamily $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $ServiceProviderName $vExpressRouteCircuit.ServiceProviderProperties.ServiceProviderName;
        Assert-AreEqual $PeeringLocation $vExpressRouteCircuit.ServiceProviderProperties.PeeringLocation;
        Assert-AreEqual $BandwidthInMbps $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;

        
        $vExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTier $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamily $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $ServiceProviderName $vExpressRouteCircuit.ServiceProviderProperties.ServiceProviderName;
        Assert-AreEqual $PeeringLocation $vExpressRouteCircuit.ServiceProviderProperties.PeeringLocation;
        Assert-AreEqual $BandwidthInMbps $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vExpressRouteCircuit.Sku.Tier = $SkuTierSet;
        $vExpressRouteCircuit.Sku.Family = $SkuFamilySet;
        $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps = $BandwidthInMbpsSet;
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "Set-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTierSet $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamilySet $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $BandwidthInMbpsSet $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;

        
        $vExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTierSet $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamilySet $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $BandwidthInMbpsSet $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeExpressRouteCircuit = $job | Receive-Job;
        Assert-AreEqual $true $removeExpressRouteCircuit;

        
        Assert-ThrowsContains { Get-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname } "not found";

        
        Assert-ThrowsContains { Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ExpressRouteCircuitCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/expressRouteCircuits" "Brazil South";
    
    $SkuTier = "Standard";
    $SkuFamily = "MeteredData";
    $ServiceProviderName = "Interxion";
    $PeeringLocation = "London";
    $BandwidthInMbps = 100;
    $AllowClassicOperation = $true;
    $Tag = @{tag1='test'};
    
    $SkuTierSet = "Premium";
    $SkuFamilySet = "UnlimitedData";
    $BandwidthInMbpsSet = 200;
    $AllowClassicOperationSet = $false;
    $TagSet = @{tag2='testSet'};

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vExpressRouteCircuit = New-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -Location $location -SkuTier $SkuTier -SkuFamily $SkuFamily -ServiceProviderName $ServiceProviderName -PeeringLocation $PeeringLocation -BandwidthInMbps $BandwidthInMbps -AllowClassicOperation $AllowClassicOperation -Tag $Tag;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "New-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTier $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamily $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $ServiceProviderName $vExpressRouteCircuit.ServiceProviderProperties.ServiceProviderName;
        Assert-AreEqual $PeeringLocation $vExpressRouteCircuit.ServiceProviderProperties.PeeringLocation;
        Assert-AreEqual $BandwidthInMbps $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;
        Assert-AreEqual $AllowClassicOperation $vExpressRouteCircuit.AllowClassicOperations;
        Assert-AreEqualObjectProperties $Tag $vExpressRouteCircuit.Tag;

        
        $vExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTier $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamily $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $ServiceProviderName $vExpressRouteCircuit.ServiceProviderProperties.ServiceProviderName;
        Assert-AreEqual $PeeringLocation $vExpressRouteCircuit.ServiceProviderProperties.PeeringLocation;
        Assert-AreEqual $BandwidthInMbps $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;
        Assert-AreEqual $AllowClassicOperation $vExpressRouteCircuit.AllowClassicOperations;
        Assert-AreEqualObjectProperties $Tag $vExpressRouteCircuit.Tag;

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $vExpressRouteCircuit.Sku.Tier = $SkuTierSet;
        $vExpressRouteCircuit.Sku.Family = $SkuFamilySet;
        $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps = $BandwidthInMbpsSet;
        $vExpressRouteCircuit.AllowClassicOperations = $AllowClassicOperationSet;
        $vExpressRouteCircuit.Tag = $TagSet;
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "Set-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTierSet $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamilySet $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $BandwidthInMbpsSet $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;
        Assert-AreEqual $AllowClassicOperationSet $vExpressRouteCircuit.AllowClassicOperations;
        Assert-AreEqualObjectProperties $TagSet $vExpressRouteCircuit.Tag;

        
        $vExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuit" $vExpressRouteCircuit };
        Assert-AreEqual $rname $vExpressRouteCircuit.Name;
        Assert-AreEqual $SkuTierSet $vExpressRouteCircuit.Sku.Tier;
        Assert-AreEqual $SkuFamilySet $vExpressRouteCircuit.Sku.Family;
        Assert-AreEqual $BandwidthInMbpsSet $vExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps;
        Assert-AreEqual $AllowClassicOperationSet $vExpressRouteCircuit.AllowClassicOperations;
        Assert-AreEqualObjectProperties $TagSet $vExpressRouteCircuit.Tag;

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName $rgname;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listExpressRouteCircuit = Get-AzExpressRouteCircuit -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listExpressRouteCircuit | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeExpressRouteCircuit = $job | Receive-Job;
        Assert-AreEqual $true $removeExpressRouteCircuit;

        
        Assert-ThrowsContains { Get-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname } "not found";

        
        Assert-ThrowsContains { Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ExpressRouteCircuitAuthorizationCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $rnameAdd = "${rname}Add";
    $location = Get-ProviderLocation "Microsoft.Network/expressRouteCircuits" "Brazil South";
    
    $ExpressRouteCircuitSkuTier = "Standard";
    $ExpressRouteCircuitSkuFamily = "MeteredData";
    $ExpressRouteCircuitServiceProviderName = "Interxion";
    $ExpressRouteCircuitPeeringLocation = "London";
    $ExpressRouteCircuitBandwidthInMbps = 100;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vExpressRouteCircuitAuthorization = New-AzExpressRouteCircuitAuthorization -Name $rname;
        Assert-NotNull $vExpressRouteCircuitAuthorization;
        Assert-True { Check-CmdletReturnType "New-AzExpressRouteCircuitAuthorization" $vExpressRouteCircuitAuthorization };
        $vExpressRouteCircuit = New-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -Authorization $vExpressRouteCircuitAuthorization -SkuTier $ExpressRouteCircuitSkuTier -SkuFamily $ExpressRouteCircuitSkuFamily -ServiceProviderName $ExpressRouteCircuitServiceProviderName -PeeringLocation $ExpressRouteCircuitPeeringLocation -BandwidthInMbps $ExpressRouteCircuitBandwidthInMbps -Location $location;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-AreEqual $rname $vExpressRouteCircuitAuthorization.Name;

        
        $vExpressRouteCircuitAuthorization = Get-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        Assert-NotNull $vExpressRouteCircuitAuthorization;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuitAuthorization" $vExpressRouteCircuitAuthorization };
        Assert-AreEqual $rname $vExpressRouteCircuitAuthorization.Name;

        
        $listExpressRouteCircuitAuthorization = Get-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuitAuthorization | Where-Object { $_.Name -eq $rname });

        
        $vExpressRouteCircuit = Add-AzExpressRouteCircuitAuthorization -Name $rnameAdd -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;

        
        $vExpressRouteCircuitAuthorization = Get-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit -Name $rnameAdd;
        Assert-NotNull $vExpressRouteCircuitAuthorization;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuitAuthorization" $vExpressRouteCircuitAuthorization };
        Assert-AreEqual $rnameAdd $vExpressRouteCircuitAuthorization.Name;

        
        $listExpressRouteCircuitAuthorization = Get-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuitAuthorization | Where-Object { $_.Name -eq $rnameAdd });

        
        Assert-ThrowsContains { Add-AzExpressRouteCircuitAuthorization -Name $rnameAdd -ExpressRouteCircuit $vExpressRouteCircuit } "already exists";

        
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit -Name $rnameAdd;
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;

        
        Assert-ThrowsContains { Get-AzExpressRouteCircuitAuthorization -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname } "Sequence contains no matching element";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ExpressRouteCircuitPeeringCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = "AzurePrivatePeering";
    $location = Get-ProviderLocation "Microsoft.Network/expressRouteCircuits" "Brazil South";
    
    $PeeringType = "AzurePrivatePeering";
    $PeerASN = 1;
    $PrimaryPeerAddressPrefix = "10.0.0.0/30";
    $SecondaryPeerAddressPrefix = "12.0.0.0/30";
    $VlanId = 1;
    
    $PeeringTypeSet = "AzurePrivatePeering";
    $PeerASNSet = 2;
    $PrimaryPeerAddressPrefixSet = "11.0.0.0/30";
    $SecondaryPeerAddressPrefixSet = "14.0.0.0/30";
    $VlanIdSet = 2;
    
    $ExpressRouteCircuitSkuTier = "Standard";
    $ExpressRouteCircuitSkuFamily = "MeteredData";
    $ExpressRouteCircuitServiceProviderName = "Interxion";
    $ExpressRouteCircuitPeeringLocation = "London";
    $ExpressRouteCircuitBandwidthInMbps = 100;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vExpressRouteCircuitPeering = New-AzExpressRouteCircuitPeeringConfig -Name $rname -PeeringType $PeeringType -PeerASN $PeerASN -PrimaryPeerAddressPrefix $PrimaryPeerAddressPrefix -SecondaryPeerAddressPrefix $SecondaryPeerAddressPrefix -VlanId $VlanId;
        Assert-NotNull $vExpressRouteCircuitPeering;
        Assert-True { Check-CmdletReturnType "New-AzExpressRouteCircuitPeeringConfig" $vExpressRouteCircuitPeering };
        $vExpressRouteCircuit = New-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -Peering $vExpressRouteCircuitPeering -SkuTier $ExpressRouteCircuitSkuTier -SkuFamily $ExpressRouteCircuitSkuFamily -ServiceProviderName $ExpressRouteCircuitServiceProviderName -PeeringLocation $ExpressRouteCircuitPeeringLocation -BandwidthInMbps $ExpressRouteCircuitBandwidthInMbps -Location $location;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-AreEqual $rname $vExpressRouteCircuitPeering.Name;
        Assert-AreEqual $PeeringType $vExpressRouteCircuitPeering.PeeringType;
        Assert-AreEqual $PeerASN $vExpressRouteCircuitPeering.PeerASN;
        Assert-AreEqual $PrimaryPeerAddressPrefix $vExpressRouteCircuitPeering.PrimaryPeerAddressPrefix;
        Assert-AreEqual $SecondaryPeerAddressPrefix $vExpressRouteCircuitPeering.SecondaryPeerAddressPrefix;
        Assert-AreEqual $VlanId $vExpressRouteCircuitPeering.VlanId;

        
        $vExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        Assert-NotNull $vExpressRouteCircuitPeering;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuitPeeringConfig" $vExpressRouteCircuitPeering };
        Assert-AreEqual $rname $vExpressRouteCircuitPeering.Name;
        Assert-AreEqual $PeeringType $vExpressRouteCircuitPeering.PeeringType;
        Assert-AreEqual $PeerASN $vExpressRouteCircuitPeering.PeerASN;
        Assert-AreEqual $PrimaryPeerAddressPrefix $vExpressRouteCircuitPeering.PrimaryPeerAddressPrefix;
        Assert-AreEqual $SecondaryPeerAddressPrefix $vExpressRouteCircuitPeering.SecondaryPeerAddressPrefix;
        Assert-AreEqual $VlanId $vExpressRouteCircuitPeering.VlanId;

        
        $listExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuitPeering | Where-Object { $_.Name -eq $rname });

        
        $vExpressRouteCircuit = Set-AzExpressRouteCircuitPeeringConfig -Name $rname -ExpressRouteCircuit $vExpressRouteCircuit -PeeringType $PeeringTypeSet -PeerASN $PeerASNSet -PrimaryPeerAddressPrefix $PrimaryPeerAddressPrefixSet -SecondaryPeerAddressPrefix $SecondaryPeerAddressPrefixSet -VlanId $VlanIdSet;
        Assert-NotNull $vExpressRouteCircuit;
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;

        
        $vExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        Assert-NotNull $vExpressRouteCircuitPeering;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuitPeeringConfig" $vExpressRouteCircuitPeering };
        Assert-AreEqual $rname $vExpressRouteCircuitPeering.Name;
        Assert-AreEqual $PeeringTypeSet $vExpressRouteCircuitPeering.PeeringType;
        Assert-AreEqual $PeerASNSet $vExpressRouteCircuitPeering.PeerASN;
        Assert-AreEqual $PrimaryPeerAddressPrefixSet $vExpressRouteCircuitPeering.PrimaryPeerAddressPrefix;
        Assert-AreEqual $SecondaryPeerAddressPrefixSet $vExpressRouteCircuitPeering.SecondaryPeerAddressPrefix;
        Assert-AreEqual $VlanIdSet $vExpressRouteCircuitPeering.VlanId;

        
        $listExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuitPeering | Where-Object { $_.Name -eq $rname });

        
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;

        
        Assert-ThrowsContains { Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzExpressRouteCircuitPeeringConfig -Name $rname -ExpressRouteCircuit $vExpressRouteCircuit -PeeringType $PeeringTypeSet -PeerASN $PeerASNSet -PrimaryPeerAddressPrefix $PrimaryPeerAddressPrefixSet -SecondaryPeerAddressPrefix $SecondaryPeerAddressPrefixSet -VlanId $VlanIdSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ExpressRouteCircuitPeeringCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = "AzurePrivatePeering";
    $location = Get-ProviderLocation "Microsoft.Network/expressRouteCircuits" "Brazil South";
    
    $PeeringType = "AzurePrivatePeering";
    $PeerASN = 1;
    $PrimaryPeerAddressPrefix = "10.0.0.0/30";
    $SecondaryPeerAddressPrefix = "12.0.0.0/30";
    $VlanId = 1;
    $SharedKey = "testkey";
    $PeerAddressType = "IPv4";
    
    $PeeringTypeSet = "AzurePrivatePeering";
    $PeerASNSet = 2;
    $PrimaryPeerAddressPrefixSet = "11.0.0.0/30";
    $SecondaryPeerAddressPrefixSet = "14.0.0.0/30";
    $VlanIdSet = 2;
    $SharedKeySet = "testkey2";
    $PeerAddressTypeSet = "IPv4";
    
    $ExpressRouteCircuitSkuTier = "Standard";
    $ExpressRouteCircuitSkuFamily = "MeteredData";
    $ExpressRouteCircuitServiceProviderName = "Interxion";
    $ExpressRouteCircuitPeeringLocation = "London";
    $ExpressRouteCircuitBandwidthInMbps = 100;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vExpressRouteCircuitPeering = New-AzExpressRouteCircuitPeeringConfig -Name $rname -PeeringType $PeeringType -PeerASN $PeerASN -PrimaryPeerAddressPrefix $PrimaryPeerAddressPrefix -SecondaryPeerAddressPrefix $SecondaryPeerAddressPrefix -VlanId $VlanId -SharedKey $SharedKey -PeerAddressType $PeerAddressType;
        Assert-NotNull $vExpressRouteCircuitPeering;
        Assert-True { Check-CmdletReturnType "New-AzExpressRouteCircuitPeeringConfig" $vExpressRouteCircuitPeering };
        $vExpressRouteCircuit = New-AzExpressRouteCircuit -ResourceGroupName $rgname -Name $rname -Peering $vExpressRouteCircuitPeering -SkuTier $ExpressRouteCircuitSkuTier -SkuFamily $ExpressRouteCircuitSkuFamily -ServiceProviderName $ExpressRouteCircuitServiceProviderName -PeeringLocation $ExpressRouteCircuitPeeringLocation -BandwidthInMbps $ExpressRouteCircuitBandwidthInMbps -Location $location;
        Assert-NotNull $vExpressRouteCircuit;
        Assert-AreEqual $rname $vExpressRouteCircuitPeering.Name;
        Assert-AreEqual $PeeringType $vExpressRouteCircuitPeering.PeeringType;
        Assert-AreEqual $PeerASN $vExpressRouteCircuitPeering.PeerASN;
        Assert-AreEqual $PrimaryPeerAddressPrefix $vExpressRouteCircuitPeering.PrimaryPeerAddressPrefix;
        Assert-AreEqual $SecondaryPeerAddressPrefix $vExpressRouteCircuitPeering.SecondaryPeerAddressPrefix;
        Assert-AreEqual $VlanId $vExpressRouteCircuitPeering.VlanId;

        
        $vExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        Assert-NotNull $vExpressRouteCircuitPeering;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuitPeeringConfig" $vExpressRouteCircuitPeering };
        Assert-AreEqual $rname $vExpressRouteCircuitPeering.Name;
        Assert-AreEqual $PeeringType $vExpressRouteCircuitPeering.PeeringType;
        Assert-AreEqual $PeerASN $vExpressRouteCircuitPeering.PeerASN;
        Assert-AreEqual $PrimaryPeerAddressPrefix $vExpressRouteCircuitPeering.PrimaryPeerAddressPrefix;
        Assert-AreEqual $SecondaryPeerAddressPrefix $vExpressRouteCircuitPeering.SecondaryPeerAddressPrefix;
        Assert-AreEqual $VlanId $vExpressRouteCircuitPeering.VlanId;

        
        $listExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuitPeering | Where-Object { $_.Name -eq $rname });

        
        $vExpressRouteCircuit = Set-AzExpressRouteCircuitPeeringConfig -Name $rname -ExpressRouteCircuit $vExpressRouteCircuit -PeeringType $PeeringTypeSet -PeerASN $PeerASNSet -PrimaryPeerAddressPrefix $PrimaryPeerAddressPrefixSet -SecondaryPeerAddressPrefix $SecondaryPeerAddressPrefixSet -VlanId $VlanIdSet -SharedKey $SharedKeySet -PeerAddressType $PeerAddressTypeSet;
        Assert-NotNull $vExpressRouteCircuit;
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;

        
        $vExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        Assert-NotNull $vExpressRouteCircuitPeering;
        Assert-True { Check-CmdletReturnType "Get-AzExpressRouteCircuitPeeringConfig" $vExpressRouteCircuitPeering };
        Assert-AreEqual $rname $vExpressRouteCircuitPeering.Name;
        Assert-AreEqual $PeeringTypeSet $vExpressRouteCircuitPeering.PeeringType;
        Assert-AreEqual $PeerASNSet $vExpressRouteCircuitPeering.PeerASN;
        Assert-AreEqual $PrimaryPeerAddressPrefixSet $vExpressRouteCircuitPeering.PrimaryPeerAddressPrefix;
        Assert-AreEqual $SecondaryPeerAddressPrefixSet $vExpressRouteCircuitPeering.SecondaryPeerAddressPrefix;
        Assert-AreEqual $VlanIdSet $vExpressRouteCircuitPeering.VlanId;

        
        $listExpressRouteCircuitPeering = Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull ($listExpressRouteCircuitPeering | Where-Object { $_.Name -eq $rname });

        
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        
        $vExpressRouteCircuit = Remove-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname;
        
        $vExpressRouteCircuit = Set-AzExpressRouteCircuit -ExpressRouteCircuit $vExpressRouteCircuit;
        Assert-NotNull $vExpressRouteCircuit;

        
        Assert-ThrowsContains { Get-AzExpressRouteCircuitPeeringConfig -ExpressRouteCircuit $vExpressRouteCircuit -Name $rname } "Sequence contains no matching element";

        
        Assert-ThrowsContains { Set-AzExpressRouteCircuitPeeringConfig -Name $rname -ExpressRouteCircuit $vExpressRouteCircuit -PeeringType $PeeringTypeSet -PeerASN $PeerASNSet -PrimaryPeerAddressPrefix $PrimaryPeerAddressPrefixSet -SecondaryPeerAddressPrefix $SecondaryPeerAddressPrefixSet -VlanId $VlanIdSet -SharedKey $SharedKeySet -PeerAddressType $PeerAddressTypeSet } "does not exist";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
