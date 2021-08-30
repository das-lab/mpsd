














function Test-GetLocationQuotas
{
    $location = Get-BatchAccountProviderLocation
    $quotas = Get-AzBatchLocationQuotas $location

    Assert-AreEqual $location $quotas.Location
    Assert-True { $quotas.AccountQuota -gt 0 }
}
