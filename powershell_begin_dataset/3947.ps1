














function Test-VirtualNetworkAvailableEndpointServicesList
{
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent

    try
    {
        $results = Get-AzVirtualNetworkAvailableEndpointService -Location $location;
        Assert-NotNull $results;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
