














function Disable-AzAdvisorRecommendationByNameParameter
{
	
	$RecommendationId = "4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"
	$DaysParam = 30
	$propertiesCount = "5"
	$TTLValue = "30.00:00:00"
	$NameValue = "HardcodedSuppressionName"

	$queryResult = Disable-AzAdvisorRecommendation -RecommendationName $RecommendationId -Days $DaysParam 
	
	
	Assert-IsInstance $queryResult Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorSuppressionContract
	
	
	for ($i = 0; $i -lt $queryResult.Count; $i++)
    {
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-AreEqual $queryResult[$i].Ttl $TTLValue
		Assert-AreEqual $queryResult[$i].Name $NameValue
    }
}

function Disable-AzAdvisorRecommendationBadUserInput-Negative
{
	$DaysParam = -4
	$RecommendationName = "4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"

	Assert-ThrowsContains { Disable-AzAdvisorRecommendation -RecommendationName $RecommendationName -Days $DaysParam  }  "Cannot validate argument on parameter 'Days'. The -4 argument is less than the minimum allowed range of 1. Supply an argument that is greater than or equal to 1 and then try the command again."
}

function Disable-AzAdvisorRecommendationByIdParameter
{
	
	$RecommendationId = "/subscriptions/658c8950-e79d-4704-a903-1df66ba90258/resourceGroups/testing/providers/Microsoft.Storage/storageAccounts/fontcjk/providers/Microsoft.Advisor/recommendations/4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"
	$DaysParam = 30
	$propertiesCount = 5
	$TTLValue = "30.00:00:00"
	$NameValue = "HardcodedSuppressionName"

	$queryResult = Disable-AzAdvisorRecommendation -ResourceId $RecommendationId -Days $DaysParam 
	
	
	Assert-IsInstance $queryResult Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorSuppressionContract
		
	for ($i = 0; $i -lt $queryResult.Count; $i++)
    {
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-AreEqual $queryResult[$i].Ttl $TTLValue
		Assert-AreEqual $queryResult[$i].Name $NameValue
    }
}

function Disable-AzAdvisorRecommendationPipelineScenario
{
	
	$RecommendationId = "4fa2ff4f-dc90-9876-0723-1360fa9f4bd7"
	$DaysParam = 30
	$propertiesCount = 5
	$TTLValue = "30.00:00:00"
	$NameValue = "HardcodedSuppressionName"

	$queryResult = Disable-AzAdvisorRecommendation -RecommendationName $RecommendationId -Days $DaysParam 
	
	
	Assert-IsInstance $queryResult Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorSuppressionContract
	
	
	for ($i = 0; $i -lt $queryResult.Count; $i++)
    {
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-AreEqual $queryResult[$i].Ttl $TTLValue
		Assert-AreEqual $queryResult[$i].Name $NameValue
	}
}