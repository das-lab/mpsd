














function Get-AzureRmSecurityContact-SubscriptionScope
{
	Set-AzSecurityContact -Name "default1" -Email "ascasc@microsoft.com" -Phone "123123123" -AlertAdmin -NotifyOnAlert

    $contacts = Get-AzSecurityContact
	Validate-Contacts $contacts
}


function Get-AzureRmSecurityContact-SubscriptionLevelResource
{
	Set-AzSecurityContact -Name "default1" -Email "ascasc@microsoft.com" -Phone "123123123" -AlertAdmin -NotifyOnAlert

    $contact = Get-AzSecurityContact -Name "default1"
	Validate-Contact $contact
}


function Get-AzureRmSecurityContact-ResourceId
{
	$contact = Set-AzSecurityContact -Name "default1" -Email "ascasc@microsoft.com" -Phone "123123123" -AlertAdmin -NotifyOnAlert

    $fetchedContact = Get-AzSecurityContact -ResourceId $contact.Id
	Validate-Contact $fetchedContact
}


function Set-AzureRmSecurityContact-SubscriptionLevelResource
{
    Set-AzSecurityContact -Name "default1" -Email "ascasc@microsoft.com" -Phone "123123123" -AlertAdmin -NotifyOnAlert
}


function Set-AzureRmSecurityContact-SubscriptionLevelResource-Secondary
{
    Set-AzSecurityContact -Name "default2" -Email "ascasc@microsoft.com"
}


function Remove-AzureRmSecurityContact-SubscriptionLevelResource
{
	Set-AzSecurityContact -Name "default1" -Email "ascasc@microsoft.com" -Phone "123123123" -AlertAdmin -NotifyOnAlert
    Remove-AzSecurityContact -Name "default1"
}


function Validate-Contacts
{
	param($contacts)

    Assert-True { $contacts.Count -gt 0 }

	Foreach($contact in $contacts)
	{
		Validate-Contact $contact
	}
}


function Validate-Contact
{
	param($contact)

	Assert-NotNull $contact
}