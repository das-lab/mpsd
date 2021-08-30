














function Test-GetAvailableDelegationsList
{
    $location = Get-ProviderLocation ResourceManagement

    try
    {
        $results = Get-AzAvailableServiceDelegation -Location $location;
        Assert-NotNull $results;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
