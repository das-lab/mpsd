














function Test-ListInvoices
{
    $billingInvoices = Get-AzBillingInvoice

    Assert-True {$billingInvoices.Count -ge 1}
	Assert-NotNull $billingInvoices[0].Name
	Assert-NotNull $billingInvoices[0].Id
	Assert-NotNull $billingInvoices[0].Type
	Assert-NotNull $billingInvoices[0].InvoicePeriodStartDate
	Assert-NotNull $billingInvoices[0].InvoicePeriodEndDate
	Assert-Null $billingInvoices[0].DownloadUrl
	Assert-Null $billingInvoices[0].DownloadUrlExpiry
}


function Test-ListInvoicesWithDownloadUrl
{
    $billingInvoices = Get-AzBillingInvoice -GenerateDownloadUrl

    Assert-True {$billingInvoices.Count -ge 1}
	Assert-NotNull $billingInvoices[0].Name
	Assert-NotNull $billingInvoices[0].Id
	Assert-NotNull $billingInvoices[0].Type
	Assert-NotNull $billingInvoices[0].InvoicePeriodStartDate
	Assert-NotNull $billingInvoices[0].InvoicePeriodEndDate
	Assert-NotNull $billingInvoices[0].DownloadUrl
	Assert-NotNull $billingInvoices[0].DownloadUrlExpiry
}


function Test-ListInvoicesWithMaxCount
{
    $billingInvoices = Get-AzBillingInvoice -GenerateDownloadUrl -MaxCount 1

    Assert-True {$billingInvoices.Count -eq 1}
	Assert-NotNull $billingInvoices[0].Name
	Assert-NotNull $billingInvoices[0].Id
	Assert-NotNull $billingInvoices[0].Type
	Assert-NotNull $billingInvoices[0].InvoicePeriodStartDate
	Assert-NotNull $billingInvoices[0].InvoicePeriodEndDate
	Assert-NotNull $billingInvoices[0].DownloadUrl
	Assert-NotNull $billingInvoices[0].DownloadUrlExpiry
}


function Test-GetLatestInvoice
{
    $invoice = Get-AzBillingInvoice -Latest

	Assert-NotNull $invoice.Name
	Assert-NotNull $invoice.Id
	Assert-NotNull $invoice.Type
	Assert-NotNull $invoice.InvoicePeriodStartDate
	Assert-NotNull $invoice.InvoicePeriodEndDate
	Assert-NotNull $invoice.DownloadUrl
	Assert-NotNull $invoice.DownloadUrlExpiry
}


function Test-GetInvoiceWithName
{
    $sampleInvoices = Get-AzBillingInvoice
    Assert-True { $sampleInvoices.Count -ge 1 }

	$invoice = Get-AzBillingInvoice -Name $sampleInvoices[0].Name

	Assert-AreEqual $invoice.Id $sampleInvoices[0].Id
}


function Test-GetInvoiceWithNames
{
	$sampleInvoices = Get-AzBillingInvoice
    Assert-True { $sampleInvoices.Count -gt 1 }

    $billingInvoices = Get-AzBillingInvoice -Name $sampleInvoices.Name

    Assert-AreEqual $sampleInvoices.Count $billingInvoices.Count
}