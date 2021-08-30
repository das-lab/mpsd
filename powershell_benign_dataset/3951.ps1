














function Test-GetAvailableAliasList
{
    $location = Get-ProviderLocation ResourceManagement

    try
    {
        $results = Get-AzAvailableServiceAlias -Location $location;
        Assert-NotNull $results;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
