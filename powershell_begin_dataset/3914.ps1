




















function Test-ListMarketplaces
{
    $marketplaces = Get-AzConsumptionMarketplace -Top 10
	Assert-NotNull $marketplaces
    Assert-AreEqual 10 $marketplaces.Count
	Foreach($mkp in $marketplaces)
	{
		Assert-NotNull $mkp.BillingPeriodId
		Assert-NotNull $mkp.ConsumedQuantity
		Assert-NotNull $mkp.Currency
		Assert-NotNull $mkp.Id
		Assert-NotNull $mkp.InstanceId
		Assert-NotNull $mkp.InstanceName
		Assert-NotNull $mkp.IsEstimated
		Assert-NotNull $mkp.Name
		Assert-NotNull $mkp.OrderNumber
		Assert-NotNull $mkp.PretaxCost
		Assert-NotNull $mkp.ResourceRate
		Assert-NotNull $mkp.SubscriptionGuid
		Assert-NotNull $mkp.Type
		Assert-NotNull $mkp.UsageEnd
		Assert-NotNull $mkp.UsageStart
	}
}


function Test-ListMarketplacesWithDateFilter
{
    $marketplaces = Get-AzConsumptionMarketplace -StartDate 2018-01-03 -EndDate 2018-01-20 -Top 10
	Assert-NotNull $marketplaces
    Assert-AreEqual 10 $marketplaces.Count
	Foreach($mkp in $marketplaces)
	{
		Assert-NotNull $mkp.BillingPeriodId
		Assert-NotNull $mkp.ConsumedQuantity
		Assert-NotNull $mkp.Currency
		Assert-NotNull $mkp.Id
		Assert-NotNull $mkp.InstanceId
		Assert-NotNull $mkp.InstanceName
		Assert-NotNull $mkp.IsEstimated
		Assert-NotNull $mkp.Name
		Assert-NotNull $mkp.OrderNumber
		Assert-NotNull $mkp.PretaxCost
		Assert-NotNull $mkp.ResourceRate
		Assert-NotNull $mkp.SubscriptionGuid
		Assert-NotNull $mkp.Type
		Assert-NotNull $mkp.UsageEnd
		Assert-NotNull $mkp.UsageStart
	}
}


function Test-ListBillingPeriodMarketplaces
{
    $marketplaces = Get-AzConsumptionMarketplace -BillingPeriodName 201801-1 -Top 10
	Assert-NotNull $marketplaces
    Assert-AreEqual 10 $marketplaces.Count
	Foreach($mkp in $marketplaces)
	{
		Assert-NotNull $mkp.BillingPeriodId
		Assert-NotNull $mkp.ConsumedQuantity
		Assert-NotNull $mkp.Currency
		Assert-NotNull $mkp.Id
		Assert-NotNull $mkp.InstanceId
		Assert-NotNull $mkp.InstanceName
		Assert-NotNull $mkp.IsEstimated
		Assert-NotNull $mkp.Name
		Assert-NotNull $mkp.OrderNumber
		Assert-NotNull $mkp.PretaxCost
		Assert-NotNull $mkp.ResourceRate
		Assert-NotNull $mkp.SubscriptionGuid
		Assert-NotNull $mkp.Type
		Assert-NotNull $mkp.UsageEnd
		Assert-NotNull $mkp.UsageStart
	}
}


function Test-ListMarketplacesWithFilterOnInstanceName
{
    $marketplaces = Get-AzConsumptionMarketplace -InstanceName TestVM -Top 10
	Assert-NotNull $marketplaces
    Assert-AreEqual 10 $marketplaces.Count
	Foreach($mkp in $marketplaces)
	{
		Assert-NotNull $mkp.BillingPeriodId
		Assert-NotNull $mkp.ConsumedQuantity
		Assert-NotNull $mkp.Currency
		Assert-NotNull $mkp.Id
		Assert-NotNull $mkp.InstanceId
		Assert-NotNull $mkp.InstanceName
		Assert-NotNull $mkp.IsEstimated
		Assert-NotNull $mkp.Name
		Assert-NotNull $mkp.OrderNumber
		Assert-NotNull $mkp.PretaxCost
		Assert-NotNull $mkp.ResourceRate
		Assert-NotNull $mkp.SubscriptionGuid
		Assert-NotNull $mkp.Type
		Assert-NotNull $mkp.UsageEnd
		Assert-NotNull $mkp.UsageStart
	}
}