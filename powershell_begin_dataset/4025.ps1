














function Test-DeploymentEndToEnd
{
    try
	{
	    
		$rgname = Get-ResourceGroupName
		$deploymentName = Get-ResourceName
		$location = "WestUS"

		New-AzResourceGroup -Name $rgname -Location $location

		
		$deployment = New-AzDeployment -Name $deploymentName -Location $location -TemplateFile subscription_level_template.json -TemplateParameterFile subscription_level_parameters.json -nestedDeploymentRG $rgname
    
		
		Assert-AreEqual Succeeded $deployment.ProvisioningState
    
		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/providers/Microsoft.Resources/deployments/$deploymentName"
		$getById = Get-AzDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName

		$templatePath = Save-AzDeploymentTemplate -Name $deploymentName -Force
		Assert-NotNull $templatePath.Path

		$operations = Get-AzDeploymentOperation -DeploymentName $deploymentName
		Assert-AreEqual 4 @($operations).Count

		Remove-AzDeployment -Name $deploymentName
	}
	finally
	{
	    Clean-ResourceGroup $rgname
	}
}


function Test-DeploymentAsJob
{
    try
	{
	    
		$rgname = Get-ResourceGroupName
		$deploymentName = Get-ResourceName
		$storageAccountName = Get-ResourceName
		$location = "WestUS"

		New-AzResourceGroup -Name $rgname -Location $location

		
		$job = New-AzDeployment -Name $deploymentName -Location $location -TemplateFile subscription_level_template.json -nestedDeploymentRG $rgname -storageAccountName $storageAccountName -AsJob
		Assert-AreEqual Running $job[0].State

		$job = $job | Wait-Job
		Assert-AreEqual Completed $job[0].State

		$deployment = $job | Receive-Job
		Assert-AreEqual Succeeded $deployment.ProvisioningState
    
		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/providers/Microsoft.Resources/deployments/$deploymentName"
		$getById = Get-AzDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName

		$operations = Get-AzDeploymentOperation -DeploymentName $deploymentName
		Assert-AreEqual 4 @($operations).Count

		Remove-AzDeployment -Name $deploymentName
	}
	finally
	{
	    Clean-ResourceGroup $rgname
	}
}


function Test-StopDeployment
{
    try
	{
	    
		$rgname = Get-ResourceGroupName
		$deploymentName = Get-ResourceName
		$storageAccountName = Get-ResourceName
		$location = "WestUS"

		New-AzResourceGroup -Name $rgname -Location $location

		
		$job = New-AzDeployment -Name $deploymentName -Location $location -TemplateFile subscription_level_template.json -nestedDeploymentRG $rgname -storageAccountName $storageAccountName -AsJob
		Assert-AreEqual Running $job[0].State

		

		Stop-AzDeployment -Name $deploymentName

		$job = $job | Wait-Job
		Assert-AreEqual Completed $job[0].State

		$deployment = $job | Receive-Job
		Assert-AreEqual Canceled $deployment.ProvisioningState

		

		Remove-AzDeployment -Name $deploymentName
	}
	finally
	{
	    Clean-ResourceGroup $rgname
	}
}