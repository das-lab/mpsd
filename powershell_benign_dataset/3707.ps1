














function Set-AzAdvisorConfigurationWithLowCpu
{
	$propertiesCount = 4
	$lowCpuThresholdParameter = 20
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorConfigurationData"
	$TypeValue = "Microsoft.Advisor/Configurations"

	$queryResult = Set-AzAdvisorConfiguration -LowCpuThreshold $lowCpuThresholdParameter 
			
	Assert-NotNull  $queryResult
	Assert-IsInstance $queryResult $cmdletReturnType

	for ($i = 0; $i -lt $queryResult.Count; $i++)
	{
		Assert-PropertiesCount $queryResult[$i] $propertiesCount	
		Assert-IsInstance $queryResult[$i].id String
		Assert-NotNull $queryResult[$i].Properties.exclude String
		Assert-NotNull $queryResult[$i].Properties.lowCpuThreshold String
		Assert-AreEqual $queryResult[$i].Properties.lowCpuThreshold 	$lowCpuThresholdParameter
		Assert-AreEqual $queryResult[$i].Type $TypeValue
	}
	
}


function Set-AzAdvisorConfigurationBadUserInputLowCpu-Negative
{
	$lowCpuThresholdParameter = 25
	Assert-ThrowsContains { Set-AzAdvisorConfiguration -LowCpuThreshold $lowCpuThresholdParameter }  "Cannot validate argument on parameter 'LowCpuThreshold'. The argument "25" does not belong to the set "0,5,10,15,20" specified by the ValidateSet attribute"
}

function Set-AzAdvisorConfigurationByLowCpuExclude
{
	try{
		$propertiesCount = 4
		$lowCpuThresholdParameter = 20
		$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorConfigurationData"
		$TypeValue = "Microsoft.Advisor/Configurations"

		$queryResult = Set-AzAdvisorConfiguration -LowCpuThreshold $lowCpuThresholdParameter -Exclude
		
		Assert-IsInstance $queryResult $cmdletReturnType
	
		Assert-NotNull  $queryResult
		for ($i = 0; $i -lt $queryResult.Count; $i++)
		{
			Assert-PropertiesCount $queryResult[$i] $propertiesCount	
			Assert-IsInstance $queryResult[$i].id String
			Assert-AreEqual $queryResult[$i].Properties.exclude $True
			Assert-NotNull $queryResult[$i].Properties.lowCpuThreshold String
			Assert-AreEqual $queryResult[$i].Properties.lowCpuThreshold 	$lowCpuThresholdParameter
			Assert-AreEqual $queryResult[$i].Type $TypeValue
		}
	}Finally{
		$queryResult = Set-AzAdvisorConfiguration -LowCpuThreshold $lowCpuThresholdParameter
	}
}

function Set-AzAdvisorConfigurationPipelineByLowCpuExclude
{
	try{
		$propertiesCount = 4
		$lowCpuThresholdParameter = 20
		$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorConfigurationData"
		$TypeValue = "Microsoft.Advisor/Configurations"

		$queryResult = Get-AzAdvisorConfiguration | Set-AzAdvisorConfiguration -LowCpuThreshold $lowCpuThresholdParameter 
		
		Assert-IsInstance $queryResult $cmdletReturnType
	
		Assert-NotNull  $queryResult

		for ($i = 0; $i -lt $queryResult.Count; $i++)
		{
			Assert-PropertiesCount $queryResult[$i] $propertiesCount	
			Assert-IsInstance $queryResult[$i].id String
			Assert-NotNull $queryResult[$i].Properties.lowCpuThreshold String
			Assert-AreEqual $queryResult[$i].Properties.lowCpuThreshold 	$lowCpuThresholdParameter
			Assert-AreEqual $queryResult[$i].Type $TypeValue
		}
	}Finally{
		$queryResult = Get-AzAdvisorConfiguration | Set-AzAdvisorConfiguration -LowCpuThreshold $lowCpuThresholdParameter 
	}
}


function Set-AzAdvisorConfigurationWithRg
{
	$propertiesCount = 4
	$RgName = "testing"
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorConfigurationData"
	$TypeValue = "Microsoft.Advisor/Configurations"

	$queryResult = Set-AzAdvisorConfiguration -ResourceGroupName $RgName 
		
	Assert-IsInstance $queryResult $cmdletReturnType
	
	Assert-NotNull  $queryResult

	for ($i = 0; $i -lt $queryResult.Count; $i++)
	{
		Assert-PropertiesCount $queryResult[$i] $propertiesCount	
		Assert-IsInstance $queryResult[$i].id String
		Assert-NotNull $queryResult[$i].Properties.exclude String
		Assert-Null $queryResult[$i].Properties.lowCpu String
		Assert-AreEqual $queryResult[$i].Type $TypeValue
	}
}

function Set-AzAdvisorConfigurationByRgExclude
{
	$propertiesCount = 4
	$RgName = "testing"
	$cmdletReturnType = "Microsoft.Azure.Commands.Advisor.Cmdlets.Models.PsAzureAdvisorConfigurationData"
	$TypeValue = "Microsoft.Advisor/Configurations"

	$queryResult = Set-AzAdvisorConfiguration -ResourceGroupName $RgName 
			
	Assert-IsInstance $queryResult $cmdletReturnType
	
	Assert-NotNull  $queryResult
	for ($i = 0; $i -lt $queryResult.Count; $i++)
	{
		Assert-PropertiesCount $queryResult[$i] $propertiesCount	
		Assert-IsInstance $queryResult[$i].id String
		Assert-NotNull $queryResult[$i].Properties.exclude String
		Assert-Null $queryResult[$i].Properties.lowCpu String
		Assert-AreEqual $queryResult[$i].Properties.exclude	$False
		Assert-AreEqual $queryResult[$i].Type $TypeValue
	}
}