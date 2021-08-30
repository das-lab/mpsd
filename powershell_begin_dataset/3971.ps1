














function Test-ExpressRouteServiceProviderList
{
    $providers = Get-AzExpressRouteServiceProvider
    Assert-NotNull $providers
	Assert-AreNotEqual 0 @($providers).Count
	Assert-NotNull $providers[0].Name
	Assert-NotNull $providers[0].PeeringLocations
	Assert-NotNull $providers[0].BandwidthsOffered
	Assert-AreNotEqual 0 @($providers[0].PeeringLocations).Count
	Assert-AreNotEqual 0 @($providers[0].BandwidthsOffered).Count         
}