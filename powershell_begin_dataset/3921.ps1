














function Test-ListBillingPeriods
{
    $billingPeriods = Get-AzBillingPeriod

    Assert-True {$billingPeriods.Count -ge 1}
	Assert-NotNull $billingPeriods[0].Name
	Assert-NotNull $billingPeriods[0].Id
	Assert-NotNull $billingPeriods[0].Type
	Assert-NotNull $billingPeriods[0].BillingPeriodStartDate
	Assert-NotNull $billingPeriods[0].BillingPeriodEndDate
}


function Test-ListBillingPeriodsWithMaxCount
{
    $billingPeriods = Get-AzBillingPeriod -MaxCount 1

    Assert-True {$billingPeriods.Count -eq 1}
	Assert-NotNull $billingPeriods[0].Name
	Assert-NotNull $billingPeriods[0].Id
	Assert-NotNull $billingPeriods[0].Type
	Assert-NotNull $billingPeriods[0].BillingPeriodStartDate
	Assert-NotNull $billingPeriods[0].BillingPeriodEndDate
}


function Test-GetBillingPeriodWithName
{
    $billingPeriods = Get-AzBillingPeriod | where { $_.InvoiceNames.Count -eq 1 }
    Assert-True {$billingPeriods.Count -ge 1}

	$billingPeriodName = $billingPeriods[0].Name
	$billingInvoiceName = $billingPeriods[0].InvoiceNames[0]

    $billingPeriod = Get-AzBillingPeriod -Name $billingPeriodName

	Assert-AreEqual $billingPeriodName $billingPeriod.Name
	Assert-NotNull $billingPeriod.Id
	Assert-NotNull $billingPeriod.Type
	Assert-NotNull $billingPeriod.BillingPeriodStartDate
	Assert-NotNull $billingPeriod.BillingPeriodEndDate
	Assert-NotNull $billingPeriod.InvoiceNames
	Assert-AreEqual 1 $billingPeriod.InvoiceNames.Count
	Assert-AreEqual $billingInvoiceName $billingPeriod.InvoiceNames
}


function Test-GetBillingPeriodWithNames
{
    $sampleBillingPeriods = Get-AzBillingPeriod
    Assert-True {$sampleBillingPeriods.Count -gt 1}

	$billingPeriodNames = $sampleBillingPeriods | %{ $_.Name }
    $billingPeriods = Get-AzBillingPeriod -Name $billingPeriodNames

    Assert-AreEqual $sampleBillingPeriods.Count $billingPeriods.Count
	Foreach($billingPeriod in $billingPeriods)
	{
		Assert-NotNull $billingPeriod.Id
		Assert-NotNull $billingPeriod.Type
		Assert-NotNull $billingPeriod.BillingPeriodStartDate
		Assert-NotNull $billingPeriod.BillingPeriodEndDate
	}
}