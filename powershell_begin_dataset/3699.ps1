














function Test-GetAgreementTerms
{
	$PublisherId = "microsoft-ads"
	$ProductId = "windows-data-science-vm"
	$PlanId = "windows2016"
    $agreementTerms = Get-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId

	Assert-NotNull $agreementTerms
	Assert-NotNull $agreementTerms.LicenseTextLink
	Assert-NotNull $agreementTerms.PrivacyPolicyLink
	Assert-NotNull $agreementTerms.Signature
}


function Test-SetAgreementTermsNotAccepted
{
	$PublisherId = "microsoft-ads"
	$ProductId = "windows-data-science-vm"
	$PlanId = "windows2016"
    $agreementTerms = Get-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId

	Assert-NotNull $agreementTerms
	Assert-NotNull $agreementTerms.LicenseTextLink
	Assert-NotNull $agreementTerms.PrivacyPolicyLink
	Assert-NotNull $agreementTerms.Signature

	$newAgreementTerms = Set-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId -Reject
	Assert-NotNull $newAgreementTerms
	Assert-NotNull $newAgreementTerms.LicenseTextLink
	Assert-NotNull $newAgreementTerms.PrivacyPolicyLink
	Assert-NotNull $newAgreementTerms.Signature
	Assert-AreEqual false $newAgreementTerms.Accepted
}


function Test-SetAgreementTermsAccepted
{
	$PublisherId = "microsoft-ads"
	$ProductId = "windows-data-science-vm"
	$PlanId = "windows2016"
    $agreementTerms = Get-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId

	Assert-NotNull $agreementTerms
	Assert-NotNull $agreementTerms.LicenseTextLink
	Assert-NotNull $agreementTerms.PrivacyPolicyLink
	Assert-NotNull $agreementTerms.Signature

	$newAgreementTerms = Set-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId -Terms $agreementTerms -Accept
	Assert-NotNull $newAgreementTerms
	Assert-NotNull $newAgreementTerms.LicenseTextLink
	Assert-NotNull $newAgreementTerms.PrivacyPolicyLink
	Assert-NotNull $newAgreementTerms.Signature
	Assert-AreEqual true $newAgreementTerms.Accepted
}


function Test-SetAgreementTermsAcceptedPipelineGet
{
	$PublisherId = "microsoft-ads"
	$ProductId = "windows-data-science-vm"
	$PlanId = "windows2016"
	$newAgreementTerms = Get-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId|Set-AzMarketplaceTerms -Accept
	Assert-NotNull $newAgreementTerms
	Assert-NotNull $newAgreementTerms.LicenseTextLink
	Assert-NotNull $newAgreementTerms.PrivacyPolicyLink
	Assert-NotNull $newAgreementTerms.Signature
	Assert-AreEqual true $newAgreementTerms.Accepted
}


function Test-SetAgreementTermsRejectedPipelineGet
{
	$PublisherId = "microsoft-ads"
	$ProductId = "windows-data-science-vm"
	$PlanId = "windows2016"
	$newAgreementTerms = Get-AzMarketplaceTerms -Publisher $PublisherId -Product $ProductId -Name $PlanId|Set-AzMarketplaceTerms -Reject
	Assert-NotNull $newAgreementTerms
	Assert-NotNull $newAgreementTerms.LicenseTextLink
	Assert-NotNull $newAgreementTerms.PrivacyPolicyLink
	Assert-NotNull $newAgreementTerms.Signature
	Assert-AreEqual false $newAgreementTerms.Accepted
}