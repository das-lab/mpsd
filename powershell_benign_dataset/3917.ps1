














function Test-ListUsageDetails
{
    $usageDetails = Get-AzConsumptionUsageDetail -Top 10
	Assert-NotNull $usageDetails
    Assert-AreEqual 10 $usageDetails.Count
	Foreach($usage in $usageDetails)
	{
		Assert-NotNull $usage.AccountName
		Assert-Null $usage.AdditionalProperties
		Assert-NotNull $usage.BillingPeriodId
		Assert-NotNull $usage.ConsumedService
		Assert-NotNull $usage.CostCenter
		Assert-NotNull $usage.Currency
		Assert-NotNull $usage.DepartmentName
		Assert-NotNull $usage.Id
		Assert-NotNull $usage.InstanceId
		Assert-NotNull $usage.InstanceLocation
		Assert-NotNull $usage.InstanceName
		Assert-NotNull $usage.IsEstimated
		Assert-Null $usage.MeterDetails
		Assert-NotNull $usage.MeterId
		Assert-NotNull $usage.Name
		Assert-NotNull $usage.PretaxCost
		Assert-NotNull $usage.Product
		Assert-NotNull $usage.SubscriptionGuid
		Assert-NotNull $usage.SubscriptionName	
		Assert-NotNull $usage.Type
		Assert-NotNull $usage.UsageEnd
		Assert-NotNull $usage.UsageQuantity
		Assert-NotNull $usage.UsageStart
	}
}


function Test-ListUsageDetailsWithMeterDetailsExpand
{
    $usageDetails = Get-AzConsumptionUsageDetail -Expand MeterDetails -Top 10

	Foreach($usage in $usageDetails)
	{
		Assert-NotNull $usage.AccountName
		Assert-Null $usage.AdditionalProperties
		Assert-NotNull $usage.BillingPeriodId
		Assert-NotNull $usage.ConsumedService
		Assert-NotNull $usage.CostCenter
		Assert-NotNull $usage.Currency
		Assert-NotNull $usage.DepartmentName
		Assert-NotNull $usage.Id
		Assert-NotNull $usage.InstanceId
		Assert-NotNull $usage.InstanceLocation
		Assert-NotNull $usage.InstanceName
		Assert-NotNull $usage.IsEstimated
		Assert-NotNull $usage.MeterDetails
		Assert-NotNull $usage.MeterId
		Assert-NotNull $usage.Name
		Assert-NotNull $usage.PretaxCost
		Assert-NotNull $usage.Product
		Assert-NotNull $usage.SubscriptionGuid
		Assert-NotNull $usage.SubscriptionName	
		Assert-NotNull $usage.Type
		Assert-NotNull $usage.UsageEnd
		Assert-NotNull $usage.UsageQuantity
		Assert-NotNull $usage.UsageStart
	}
}


function Test-ListUsageDetailsWithDateFilter
{
    $usageDetails = Get-AzConsumptionUsageDetail -StartDate 2017-10-02 -EndDate 2017-10-05 -Top 10

    Assert-AreEqual 10 $usageDetails.Count
	Foreach($usage in $usageDetails)
	{
		Assert-NotNull $usage.AccountName
		Assert-Null $usage.AdditionalProperties
		Assert-NotNull $usage.BillingPeriodId
		Assert-NotNull $usage.ConsumedService
		Assert-NotNull $usage.CostCenter
		Assert-NotNull $usage.Currency
		Assert-NotNull $usage.DepartmentName
		Assert-NotNull $usage.Id
		Assert-NotNull $usage.InstanceId
		Assert-NotNull $usage.InstanceLocation
		Assert-NotNull $usage.InstanceName
		Assert-NotNull $usage.IsEstimated
		Assert-Null $usage.MeterDetails
		Assert-NotNull $usage.MeterId
		Assert-NotNull $usage.Name
		Assert-NotNull $usage.PretaxCost
		Assert-NotNull $usage.Product
		Assert-NotNull $usage.SubscriptionGuid
		Assert-NotNull $usage.SubscriptionName	
		Assert-NotNull $usage.Type
		Assert-NotNull $usage.UsageEnd
		Assert-NotNull $usage.UsageQuantity
		Assert-NotNull $usage.UsageStart
	}
}


function Test-ListBillingPeriodUsageDetails
{
    $usageDetails = Get-AzConsumptionUsageDetail -BillingPeriodName 201710 -Top 10

    Assert-AreEqual 10 $usageDetails.Count
	Foreach($usage in $usageDetails)
	{
		Assert-NotNull $usage.AccountName
		Assert-Null $usage.AdditionalProperties
		Assert-NotNull $usage.BillingPeriodId
		Assert-NotNull $usage.ConsumedService
		Assert-NotNull $usage.CostCenter
		Assert-NotNull $usage.Currency
		Assert-NotNull $usage.DepartmentName
		Assert-NotNull $usage.Id
		Assert-NotNull $usage.InstanceId
		Assert-NotNull $usage.InstanceLocation
		Assert-NotNull $usage.InstanceName
		Assert-NotNull $usage.IsEstimated
		Assert-Null $usage.MeterDetails
		Assert-NotNull $usage.MeterId
		Assert-NotNull $usage.Name
		Assert-NotNull $usage.PretaxCost
		Assert-NotNull $usage.Product
		Assert-NotNull $usage.SubscriptionGuid
		Assert-NotNull $usage.SubscriptionName	
		Assert-NotNull $usage.Type
		Assert-NotNull $usage.UsageEnd
		Assert-NotNull $usage.UsageQuantity
		Assert-NotNull $usage.UsageStart
	}
}


function Test-ListBillingPeriodUsageDetailsWithFilterOnInstanceName
{
    $usageDetails = Get-AzConsumptionUsageDetail -BillingPeriodName 201710 -InstanceName 1c2052westus -Top 10

	Foreach($usage in $usageDetails)
	{
		Assert-NotNull $usage.AccountName
		Assert-Null $usage.AdditionalProperties
		Assert-NotNull $usage.BillingPeriodId
		Assert-NotNull $usage.ConsumedService
		Assert-NotNull $usage.CostCenter
		Assert-NotNull $usage.Currency
		Assert-NotNull $usage.DepartmentName
		Assert-NotNull $usage.Id
		Assert-NotNull $usage.InstanceId
		Assert-NotNull $usage.InstanceLocation
		Assert-NotNull $usage.InstanceName
		Assert-AreEqual "1c2052westus" $usage.InstanceName
		Assert-NotNull $usage.IsEstimated
		Assert-Null $usage.MeterDetails
		Assert-NotNull $usage.MeterId
		Assert-NotNull $usage.Name
		Assert-NotNull $usage.PretaxCost
		Assert-NotNull $usage.Product
		Assert-NotNull $usage.SubscriptionGuid
		Assert-NotNull $usage.SubscriptionName	
		Assert-NotNull $usage.Type
		Assert-NotNull $usage.UsageEnd
		Assert-NotNull $usage.UsageQuantity
		Assert-NotNull $usage.UsageStart
	}
}


function Test-ListBillingPeriodUsageDetailsWithDateFilter
{
    $usageDetails = Get-AzConsumptionUsageDetail -BillingPeriodName 201710 -StartDate 2017-10-19 -Top 10

    Assert-AreEqual 10 $usageDetails.Count
	Foreach($usage in $usageDetails)
	{
		Assert-NotNull $usage.AccountName
		Assert-Null $usage.AdditionalProperties
		Assert-NotNull $usage.BillingPeriodId
		Assert-NotNull $usage.ConsumedService
		Assert-NotNull $usage.CostCenter
		Assert-NotNull $usage.Currency
		Assert-NotNull $usage.DepartmentName
		Assert-NotNull $usage.Id
		Assert-NotNull $usage.InstanceId
		Assert-NotNull $usage.InstanceLocation
		Assert-NotNull $usage.InstanceName
		Assert-NotNull $usage.IsEstimated
		Assert-Null $usage.MeterDetails
		Assert-NotNull $usage.MeterId
		Assert-NotNull $usage.Name
		Assert-NotNull $usage.PretaxCost
		Assert-NotNull $usage.Product
		Assert-NotNull $usage.SubscriptionGuid
		Assert-NotNull $usage.SubscriptionName	
		Assert-NotNull $usage.Type
		Assert-NotNull $usage.UsageEnd
		Assert-NotNull $usage.UsageQuantity
		Assert-NotNull $usage.UsageStart
	}
}
