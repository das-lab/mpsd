




















function Test-ListPriceSheets
{
    $priceSheets = Get-AzConsumptionPriceSheet -Top 5
	Assert-NotNull $priceSheets
	Assert-NotNull $priceSheets.Id
	Assert-NotNull $priceSheets.Name
	Assert-NotNull $priceSheets.Type	

	$priceSheetProperties = $priceSheets.PriceSheets
	Assert-NotNull $priceSheetProperties
	Assert-AreEqual 5 $priceSheetProperties.Count
	Foreach($psp in $priceSheetProperties)
	{
		Assert-NotNull $psp.BillingPeriodId
		Assert-NotNull $psp.CurrencyCode
		Assert-NotNull $psp.IncludedQuantity
		Assert-Null $psp.MeterDetails
		Assert-NotNull $psp.MeterId
		Assert-NotNull $psp.PartNumber
		Assert-NotNull $psp.UnitOfMeasure
		Assert-NotNull $psp.UnitPrice
	}
}


function Test-ListPriceSheetsWithMeterDetailsExpand
{
    $priceSheets = Get-AzConsumptionPriceSheet -ExpandMeterDetail -Top 5
	Assert-NotNull $priceSheets
	Assert-NotNull $priceSheets.Id
	Assert-NotNull $priceSheets.Name
	Assert-NotNull $priceSheets.Type	

	$priceSheetProperties = $priceSheets.PriceSheets
	Assert-NotNull $priceSheetProperties
	Assert-AreEqual 5 $priceSheetProperties.Count
	Foreach($psp in $priceSheetProperties)
	{
		Assert-NotNull $psp.BillingPeriodId
		Assert-NotNull $psp.CurrencyCode
		Assert-NotNull $psp.IncludedQuantity
		Assert-NotNull $psp.MeterDetails
		Assert-NotNull $psp.MeterId
		Assert-NotNull $psp.PartNumber
		Assert-NotNull $psp.UnitOfMeasure
		Assert-NotNull $psp.UnitPrice
	}
}


function Test-ListBillingPeriodPriceSheets
{
    $priceSheets = Get-AzConsumptionPriceSheet -BillingPeriodName 201712 -Top 5
	Assert-NotNull $priceSheets
	Assert-NotNull $priceSheets.Id
	Assert-NotNull $priceSheets.Name
	Assert-NotNull $priceSheets.Type	

	$priceSheetProperties = $priceSheets.PriceSheets
	Assert-NotNull $priceSheetProperties
	Assert-AreEqual 5 $priceSheetProperties.Count
	Foreach($psp in $priceSheetProperties)
	{
		Assert-NotNull $psp.BillingPeriodId
		Assert-NotNull $psp.CurrencyCode
		Assert-NotNull $psp.IncludedQuantity
		Assert-Null $psp.MeterDetails
		Assert-NotNull $psp.MeterId
		Assert-NotNull $psp.PartNumber
		Assert-NotNull $psp.UnitOfMeasure
		Assert-NotNull $psp.UnitPrice
	}
}