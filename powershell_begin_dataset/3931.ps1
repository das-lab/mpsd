














function Test-NetworkServiceTagsList
{
    $location = Get-ProviderLocation ResourceManagement;

    try
    {
        $results = Get-AzNetworkServiceTag -Location $location;
        Assert-NotNull $results;

        Assert-AreEqual $results.Type "Microsoft.Network/serviceTags";
        Assert-NotNull $results.Name;
        Assert-NotNull $results.Id;
        Assert-NotNull $results.ChangeNumber;
        Assert-NotNull $results.Cloud;
        Assert-NotNull $results.Values;
        Assert-True { $results.Values.Count -gt 1 };

        $serviceTagInformation = $results.Values[0];

        Assert-NotNull $serviceTagInformation.Name;
        Assert-NotNull $serviceTagInformation.Id;
        Assert-NotNull $serviceTagInformation.Properties.ChangeNumber;
        Assert-NotNull $serviceTagInformation.Properties.Region;
        Assert-NotNull $serviceTagInformation.Properties.SystemService;
        Assert-True { $serviceTagInformation.Properties.AddressPrefixes.Count -gt 1 };
    }
    finally {}
}
