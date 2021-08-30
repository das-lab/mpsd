














function Get-AzAdvisorRecommendationNoParameter
{
	
	$propertiesCount = 14
	$shortDescriptionPropertiesCount = 2
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase"

	$queryResult = Get-AzAdvisorRecommendation 
	Assert-NotNull  $queryResult

	for ($i = 0; $i -lt $queryResult.Count; $i++)
	{
		Assert-IsInstance $queryResult[$i] $cmdletReturnType
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-IsInstance $queryResult[$i].ResourceId String
		Assert-IsInstance $queryResult[$i].Name String
		Assert-PropertiesCount $queryResult[$i].ShortDescription $shortDescriptionPropertiesCount
	}
}


function Get-AzAdvisorRecommendationByIdParameterSet
{
	
	$propertiesCount = 14
	$shortDescriptionPropertiesCount = 2
	$RecommendationId = "/subscriptions/658c8950-e79d-4704-a903-1df66ba90258/resourceGroups/testing/providers/Microsoft.Storage/storageAccounts/fontcjk"
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase"

	$queryResult = Get-AzAdvisorRecommendation -ResourceId $RecommendationId

	for ($i = 0; $i -lt $queryResult.Count; $i++){
		Assert-IsInstance $queryResult[$i] $cmdletReturnType
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-PropertiesCount $queryResult[$i].ShortDescription $shortDescriptionPropertiesCount
	}	
}


function Get-AzAdvisorRecommendationByCategory
{
	
	$propertiesCount = 14
	$shortDescriptionPropertiesCount = 2
	$Category = "Security"
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase"

	$queryResult = Get-AzAdvisorRecommendation -Category $Category

	Assert-NotNull  $queryResult
	
	for ($i = 0; $i -lt $queryResult.Count; $i++){
		Assert-IsInstance $queryResult[$i] $cmdletReturnType
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-AreEqual $queryResult[$i].category $Category
		Assert-PropertiesCount $queryResult[$i].ShortDescription $shortDescriptionPropertiesCount
	}	
}


function Get-AzAdvisorRecommendationByNameParameterSet
{
	
	$propertiesCount = 14
	$shortDescriptionPropertiesCount = 2
	$ResourceGroupName = "AzExpertStg"
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase"

	$queryResult = Get-AzAdvisorRecommendation -ResourceGroupName $ResourceGroupName
	Assert-NotNull  $queryResult

	for ($i = 0; $i -lt $queryResult.Count; $i++){
		Assert-IsInstance $queryResult[$i] $cmdletReturnType
		Assert-PropertiesCount $queryResult[$i] 14
		Assert-IsInstance $queryResult[$i].ResourceId String
		Assert-IsInstance $queryResult[$i].Name String
		Assert-PropertiesCount $queryResult[$i].ShortDescription 2 
	}
}
