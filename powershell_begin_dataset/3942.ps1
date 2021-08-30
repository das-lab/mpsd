














function Test-NetworkUsage
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/Usages"
    $location = Get-ProviderLocation $resourceTypeParent "West US" -UseCanonical $true

    try 
    {
        $usage = Get-AzNetworkUsage -Location $location;
        $vnetCount = ($usage | Where-Object { $_.name.Value -eq "VirtualNetworks" }).currentValue;
        Assert-AreNotEqual 0 $usage.Length "Usage should return non-empty array";

        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation

        
        New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -DnsServer 8.8.8.8;
        $usage = Get-AzNetworkUsage -Location $location;
        $vnetCount2 = ($usage | Where-Object { $_.name.Value -eq "VirtualNetworks" }).currentValue;

        Assert-AreEqual ($vnetCount + 1) $vnetCount2 "Virtual Networks usage current value should be increased after Virtual Network was created";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
