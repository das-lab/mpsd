













function Test-NotFound
{
    $rgLocation = Get-ProviderLocation ResourceManagement

    $rgName = Get-ResourceGroupName
    $pipName = Get-ResourceName

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location $rgLocation

        
        Assert-ThrowsLike { Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $pipName } "*ResourceNotFound*was not found*"
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-InvalidName
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $location = Get-ProviderLocation "Microsoft.Network/publicIpAddresses"

    $rgName = Get-ResourceGroupName
    $invalidName = "!"

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location $rgLocation

        
        $scriptBlock = { New-AzPublicIpAddress -ResourceGroupName $rgName -Name $invalidName -Location $location -AllocationMethod Dynamic }
        Assert-ThrowsLike $scriptBlock "*InvalidResourceName*Resource name ${invalidName} is invalid*"
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-DuplicateResource
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $location = Get-ProviderLocation "Microsoft.Network/virtualNetworks"

    $rgName = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName

    $vnetAddressPrefix = "10.0.0.0/8"
    $subnetAddressPrefix = "10.0.1.0/24"

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location $rgLocation

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
        $vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet
        $vnet.Subnets.Add($subnet)

        
        Assert-ThrowsLike { Set-AzVirtualNetwork -VirtualNetwork $vnet } "*InvalidRequestFormat*Additional details*DuplicateResourceName*"
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-IntersectAddressSpace
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $location = Get-ProviderLocation "Microsoft.Network/virtualNetworks"

    $rgName = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName

    $vnetAddressPrefix = "10.0.0.0/8"
    $subnetAddressPrefix = "10.0.1.0/24"

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location $rgLocation

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
        $vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet
        Add-AzVirtualNetworkSubnetConfig -Name "${subnetName}2" -AddressPrefix $subnetAddressPrefix -VirtualNetwork $vnet
        
        
        Assert-ThrowsLike { Set-AzVirtualNetwork -VirtualNetwork $vnet } "*NetcfgInvalidSubnet*Subnet*is not valid in virtual network*"
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-ErrorResponseException
{
    $rgLocation = Get-ProviderLocation ResourceManagement

    $rgName = Get-ResourceGroupName
    $nwName = Get-ResourceName

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location $rgLocation

        
        [array]$nw = Get-AzNetworkWatcher
        if($nw.Length -gt 0)
        {
            $existingLocation = $nw[0].Location
            Assert-ThrowsLike { New-AzNetworkWatcher -Name $nwName -ResourceGroupName $rgName -Location $existingLocation } "*NetworkWatcherCountLimitReached*"
        }

        
        [array]$availableLocations = (Get-AzResourceProvider -ProviderNamespace "Microsoft.Network" | Where-Object { $_.ResourceTypes.ResourceTypeName -eq "networkWatchers" }).Locations
        if($availableLocations.Length -gt 0)
        {
            $location = Normalize-Location $availableLocations[0]
            Assert-ThrowsLike { New-AzNetworkWatcher -Name "!" -ResourceGroupName $rgName -Location $location } "*InvalidResourceName*"
        }
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}
