














function Enable-AzAdvisorRecommendationByNameParameterSet
{
	
	$RecommendationName = "4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"

	$queryResult = Enable-AzAdvisorRecommendation -RecommendationName $RecommendationName
	
	Assert-IsInstance $queryResult Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase
	
	for ($i = 0; $i -lt $queryResult.Count; $i++)
	{
		Assert-PropertiesCount $queryResult[$i] 14	
		Assert-IsInstance $queryResult[$i].ResourceId String
		Assert-IsInstance $queryResult[$i].Name String
		Assert-PropertiesCount $queryResult[$i].ShortDescription 2
	}
}


function Enable-AzAdvisorRecommendationByIdParameterSet
{
	
	$RecommendationId = "/subscriptions/658c8950-e79d-4704-a903-1df66ba90258/resourceGroups/testing/providers/Microsoft.Storage/storageAccounts/fontcjk/providers/Microsoft.Advisor/recommendations/4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"

	$RecommendationId = "/subscriptions/658c8950-e79d-4704-a903-1df66ba90258/resourceGroups/testing/providers/Microsoft.Storage/storageAccounts/fontcjk/providers/Microsoft.Advisor/recommendations/4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"
	$queryResult = Enable-AzAdvisorRecommendation -ResourceId $RecommendationId
	
	Assert-IsInstance $queryResult Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase
	
	for ($i = 0; $i -lt $queryResult.Count; $i++)
    {
		Assert-PropertiesCount $queryResult[$i] 14	
		Assert-IsInstance $queryResult[$i].ResourceId String
		Assert-IsInstance $queryResult[$i].Name String
		Assert-PropertiesCount $queryResult[$i].ShortDescription 2
	}
}


function Enable-AzAdvisorRecommendationPipeline
{
	
	$RecommendationId = "/subscriptions/658c8950-e79d-4704-a903-1df66ba90258/resourceGroups/testing/providers/Microsoft.Storage/storageAccounts/fontcjk"
	$queryResult = Get-AzAdvisorRecommendation -ResourceId $RecommendationId | Enable-AzAdvisorRecommendation
	
	Assert-IsInstance $queryResult Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorResourceRecommendationBase
	
	for ($i = 0; $i -lt $queryResult.Count; $i++)
    {
		Assert-PropertiesCount $queryResult[$i] 14	
		Assert-IsInstance $queryResult[$i].ResourceId String
		Assert-IsInstance $queryResult[$i].Name String
		Assert-PropertiesCount $queryResult[$i].ShortDescription 2
	}
}


