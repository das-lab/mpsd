














function Get-AzAdvisorConfigurationNoParameter
{
	$propertiesCount = 4
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorConfigurationData"
	$TypeValue = "Microsoft.Advisor/Configurations"

	$queryResult = Get-AzAdvisorConfiguration 
		
	Assert-IsInstance $queryResult $cmdletReturnType
	
	Assert-NotNull  $queryResult
	for ($i = 0; $i -lt $queryResult.Count; $i++){
		Assert-PropertiesCount $queryResult[$i] $propertiesCount
		Assert-IsInstance $queryResult[$i].id String
		Assert-AreEqual $queryResult[$i].Type $TypeValue
	}	
}