














function Test-AzureProviderFeature
{
    $defaultProviderFeatures = Get-AzureRmProviderFeature

    $allProviderFeatures = Get-AzureRmProviderFeature -ListAvailable

    Assert-True { $allProviderFeatures.Length -gt $defaultProviderFeatures.Length }

    $batchFeatures = Get-AzureRmProviderFeature -ProviderName "Microsoft.Batch"

    Assert-True { $batchFeatures.Length -eq 0 }

    $batchFeatures = Get-AzureRmProviderFeature -ProviderName "Microsoft.Batch" -ListAvailable

    Assert-True { $batchFeatures.Length -gt 0 }

    Register-AzureRmProviderFeature -ProviderName "Microsoft.Cache" -FeatureName "betaAccess3"

    $cacheRegisteredFeatures = Get-AzureRmProviderFeature -ProviderName "Microsoft.Cache"

    Assert-True { $cacheRegisteredFeatures.Length -gt 0 }
}
