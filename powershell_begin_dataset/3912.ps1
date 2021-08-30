
















function Test-GetPartner
{
    
	$partnerId="5127255"
	$partner = New-AzManagementPartner -PartnerId $partnerId

    
	$partner = Get-AzManagementPartner -PartnerId $partnerId

	
	Assert-AreEqual $partnerId $partner.PartnerId
	Assert-NotNull $partner.TenantId
	Assert-NotNull $partner.ObjectId
    Assert-NotNull $partner.State

    
    Remove-AzManagementPartner -PartnerId $partnerId
}



function Test-GetPartnerNoPartnerId
{
	 
	$partnerId="5127255"
	$partner = New-AzManagementPartner -PartnerId $partnerId

    
	$partner = Get-AzManagementPartner

	
	Assert-AreEqual $partnerId $partner.PartnerId
	Assert-NotNull $partner.TenantId
	Assert-NotNull $partner.ObjectId
    Assert-NotNull $partner.State

    
    Remove-AzManagementPartner -PartnerId $partnerId
}



function Test-NewPartner
{
	$partnerId="5127255"
	$partner = New-AzManagementPartner -PartnerId $partnerId

	
	Assert-AreEqual $partnerId $partner.PartnerId
	Assert-NotNull $partner.TenantId
	Assert-NotNull $partner.ObjectId
    Assert-NotNull $partner.State

    
    Remove-AzManagementPartner -PartnerId $partnerId
}



function Test-UpdatePartner
{
	
	$partnerId="5127255"
	$partner = New-AzManagementPartner -PartnerId $partnerId

    
    $newPartnerId="5127254"
	$partner = Update-AzManagementPartner -PartnerId $newPartnerId

	
	Assert-AreEqual $newPartnerId $partner.PartnerId
	Assert-NotNull $partner.TenantId
	Assert-NotNull $partner.ObjectId
    Assert-NotNull $partner.State

    
    Remove-AzManagementPartner -PartnerId $newPartnerId
}


function Test-RemovePartner
{
	
	$partnerId="5127255"
	$partner = New-AzManagementPartner -PartnerId $partnerId
    
    
	Remove-AzManagementPartner -PartnerId $partnerId
}
