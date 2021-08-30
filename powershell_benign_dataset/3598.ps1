














function Get-AzureRmDiscoveredSecuritySolution-SubscriptionScope
{
    $discoveredSecuritySolutions = Get-AzDiscoveredSecuritySolution
	Validate-DiscoveredSecuritySolutions $discoveredSecuritySolutions
}


function Get-AzureRmDiscoveredSecuritySolution-ResourceGroupLevelResource
{
	$discoveredSecuritySolution = Get-AzDiscoveredSecuritySolution | Select -First 1
	$rgName = Extract-ResourceGroup -ResourceId $discoveredSecuritySolution.Id
	$location = Extract-ResourceLocation -ResourceId $discoveredSecuritySolution.Id

    $fetchedDiscoveredSecuritySolution = Get-AzDiscoveredSecuritySolution -ResourceGroupName $rgName -Location $location -Name $discoveredSecuritySolution.Name
	Validate-DiscoveredSecuritySolution $fetchedDiscoveredSecuritySolution
}


function Get-AzureRmDiscoveredSecuritySolution-ResourceId
{
	$discoveredSecuritySolution = Get-AzDiscoveredSecuritySolution | Select -First 1

    $discoveredSecuritySolutions = Get-AzDiscoveredSecuritySolution -ResourceId $discoveredSecuritySolution.Id
	Validate-DiscoveredSecuritySolutions $discoveredSecuritySolutions
}


function Validate-DiscoveredSecuritySolutions
{
	param($discoveredSecuritySolutions)

    Assert-True { $discoveredSecuritySolutions.Count -gt 0 }

	Foreach($discoveredSecuritySolution in $discoveredSecuritySolutions)
	{
		Validate-DiscoveredSecuritySolution $discoveredSecuritySolution
	}
}


function Validate-DiscoveredSecuritySolution
{
	param($discoveredSecuritySolution)

	Assert-NotNull $discoveredSecuritySolution
}