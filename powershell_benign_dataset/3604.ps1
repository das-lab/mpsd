














function Get-AzureRmSecurityCompliance-SubscriptionScope
{
    $compliances = Get-AzSecurityCompliance
	Validate-Compliances $compliances
}


function Get-AzureRmSecurityCompliance-SubscriptionLevelResource
{
	$compliance = Get-AzSecurityCompliance | Select -First 1
    $fetchedCompliance = Get-AzSecurityCompliance -Name $compliance.Name
	Validate-Compliance $fetchedCompliance
}


function Get-AzureRmSecurityCompliance-ResourceId
{
	$compliance = Get-AzSecurityCompliance | Select -First 1

	$location = Get-AzSecurityLocation | Select -First 1

	$context = Get-AzContext
	$subscriptionId = $context.Subscription.Id
	

    $fetchedCompliance = Get-AzSecurityCompliance -ResourceId "/subscriptions/$subscriptionId/providers/Microsoft.Seucurity/locations/$location/compliances/$($compliance.Name)"
	Validate-Compliances $fetchedCompliance
}


function Validate-Compliances
{
	param($compliances)

    Assert-True { $compliances.Count -gt 0 }

	Foreach($compliance in $compliances)
	{
		Validate-Compliance $compliance
	}
}


function Validate-Compliance
{
	param($compliance)

	Assert-NotNull $compliance
}