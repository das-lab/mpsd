














function Get-AzureRmExternalSecuritySolution-SubscriptionScope
{
    $externalSecuritySolutions = Get-AzExternalSecuritySolution
	Validate-ExternalSecuritySolutions $externalSecuritySolutions
}


function Get-AzureRmExternalSecuritySolution-ResourceGroupLevelResource
{
	$externalSecuritySolutions = Get-AzExternalSecuritySolution
	$externalSecuritySolution = $externalSecuritySolutions | Select -First 1
	$rgName = Extract-ResourceGroup -ResourceId $externalSecuritySolution.Id
	$location = Extract-ResourceLocation -ResourceId $externalSecuritySolution.Id

    $fetchedExternalSecuritySolution = Get-AzExternalSecuritySolution -ResourceGroupName $rgName -Location $location -Name $externalSecuritySolution.Name
	Validate-ExternalSecuritySolution $fetchedExternalSecuritySolution
}


function Get-AzureRmExternalSecuritySolution-ResourceId
{
	$externalSecuritySolution = Get-AzExternalSecuritySolution | Select -First 1

    $fetchedExternalSecuritySolution = Get-AzExternalSecuritySolution -ResourceId $externalSecuritySolution.Id
	Validate-ExternalSecuritySolution $fetchedExternalSecuritySolution
}


function Validate-ExternalSecuritySolutions
{
	param($externalSecuritySolutions)

    Assert-True { $externalSecuritySolutions.Count -gt 0 }

	Foreach($externalSecuritySolution in $externalSecuritySolutions)
	{
		Validate-ExternalSecuritySolution $externalSecuritySolution
	}
}


function Validate-ExternalSecuritySolution
{
	param($externalSecuritySolution)

	Assert-NotNull $externalSecuritySolution
}