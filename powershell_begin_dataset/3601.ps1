














function Get-AzureRmSecurityLocation-SubscriptionScope
{
    $locations = Get-AzSecurityLocation
	Validate-Locations $locations
}


function Get-AzureRmSecurityLocation-SubscriptionLevelResource
{
	$location = Get-AzSecurityLocation | Select -First 1
    $fetchedLocation = Get-AzSecurityLocation -Name $location.Name
	Validate-Location $fetchedLocation
}


function Get-AzureRmSecurityLocation-ResourceId
{
	$location = Get-AzSecurityLocation | Select -First 1
    $fetchedLocation = Get-AzSecurityLocation -ResourceId $location.Id
	Validate-Location $fetchedLocation
}


function Validate-Locations
{
	param($locations)

    Assert-True { $locations.Count -gt 0 }

	Foreach($location in $locations)
	{
		Validate-Location $location
	}
}


function Validate-Location
{
	param($location)

	Assert-NotNull $location
}