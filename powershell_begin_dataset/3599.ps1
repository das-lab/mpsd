














function Get-AzureRmSecurityPricing-SubscriptionScope
{
    $pricings = Get-AzSecurityPricing
	Validate-Pricings $pricings
}


function Get-AzureRmSecurityPricing-SubscriptionLevelResource
{
    $pricings = Get-AzSecurityPricing -Name "VirtualMachines"
	Validate-Pricings $pricings
}


function Get-AzureRmSecurityPricing-ResourceId
{
	$pricing = Get-AzSecurityPricing | Select -First 1

    $fetchedPricing = Get-AzSecurityPricing -ResourceId $pricing.Id
	Validate-Pricing $fetchedPricing
}


function Set-AzureRmSecurityPricing-SubscriptionLevelResource
{
    Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard"
}


function Validate-Pricings
{
	param($pricings)

    Assert-True { $pricings.Count -gt 0 }

	Foreach($pricing in $pricings)
	{
		Validate-Pricing $pricing
	}
}


function Validate-Pricing
{
	param($pricing)

	Assert-NotNull $pricing
}