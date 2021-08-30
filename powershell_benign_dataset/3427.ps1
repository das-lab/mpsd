














function Test-ValidateDeployment
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"
	$location = Get-ProviderLocation "Microsoft.Web/sites"

	
	New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
	$list = Test-AzureResourceGroupTemplate -ResourceGroupName $rgname -TemplateFile Build2014_Website_App.json -siteName $rname -hostingPlanName $rname -siteLocation $location -sku Free -workerSize 0

	
	Assert-AreEqual 0 @($list).Count
}


function Test-NewDeploymentFromTemplateFile
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleDeploymentTemplate.json -TemplateParameterFile sampleDeploymentTemplateParams.json

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-CrossResourceGroupDeploymentFromTemplateFile
{
	
	$rgname = "firstRgInTest"
	$rgname2 = "$($rgname)Second"
	$rname = "dploname"
	$rglocation = "Central US"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation -Force
		New-AzureRmResourceGroup -Name $rgname2 -Location $rglocation -Force
		
		$parameters = @{ "NestedDeploymentResourceGroup" = $rgname2 }
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplateWithCrossResourceGroupDeployment.json -TemplateParameterObject $parameters

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName

		$nestedDeploymentId = "/subscriptions/$subId/resourcegroups/$rgname2/providers/Microsoft.Resources/deployments/nestedTemplate"
		$nestedDeployment = Get-AzureRmResourceGroupDeployment -Id $nestedDeploymentId
		Assert-AreEqual Succeeded $nestedDeployment.ProvisioningState
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $rgname2
    }
}


function Test-NestedErrorsDisplayed
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		$ErrorActionPreference = "SilentlyContinue"
		$Error.Clear()
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplateThrowsNestedErrors.json
	}
	catch
	{
		Assert-True { $Error[1].Contains("Storage account name must be between 3 and 24 characters in length") }
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NestedDeploymentFromTemplateFile
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleNestedTemplate.json -TemplateParameterFile sampleNestedTemplateParams.json

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SaveDeploymentTemplateFile
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleDeploymentTemplate.json -TemplateParameterFile sampleDeploymentTemplateParams.json

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState
		
		$saveOutput = Save-AzureRmResourceGroupDeploymentTemplate -ResourceGroupName $rgname -DeploymentName $rname -Force
		Assert-NotNull $saveOutput
		Assert-True { $saveOutput.Path.Contains($rname + ".json") }
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewDeploymentWithKeyVaultReference
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$keyVaultname = Get-ResourceName
	$secretName = Get-ResourceName
	$rglocation = "CentralUSEUAP"
	$location = Get-ProviderLocation "Microsoft.Web/sites"
	$hostplanName = "xDeploymentTestHost26668"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation

		$context = Get-AzureRmContext
		$subscriptionId = $context.Subscription.SubscriptionId
		$tenantId = $context.Tenant.TenantId
		$adUser = Get-AzureRmADUser -UserPrincipalName $context.Account.Id
		$objectId = $adUser.Id
		$KeyVaultResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $rgname + "/providers/Microsoft.KeyVault/vaults/" + $keyVaultname
		
		$parameters = @{ "keyVaultName" = $keyVaultname; "secretName" = $secretName; "secretValue" = $hostplanName; "tenantId" = $tenantId; "objectId" = $objectId }
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile keyVaultSetupTemplate.json -TemplateParameterObject $parameters

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$content = (Get-Content keyVaultTemplateParams.json) -join '' | ConvertFrom-Json
		$content.hostingPlanName.reference.KeyVault.id = $KeyVaultResourceId
		$content.hostingPlanName.reference.SecretName = $secretName
		$content | ConvertTo-Json -depth 999 | Out-File keyVaultTemplateParams.json

		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplate.json -TemplateParameterFile keyVaultTemplateParams.json

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewDeploymentWithComplexPramaters
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -TemplateParameterFile complexParameters.json

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewDeploymentWithParameterObject
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -TemplateParameterObject @{appSku=@{code="f1"; name="Free"}; servicePlan="plan1"; ranks=@("c", "d")}

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewDeploymentWithDynamicParameters
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -appSku @{code="f3"; name=@{major="Official"; minor="1.0"}} -servicePlan "plan1" -ranks @("c", "d")

		
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzureRmContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzureRmResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}
	
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewDeploymentWithInvalidParameters
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		
		$ErrorActionPreference = "SilentlyContinue"
		$Error.Clear()
		New-AzureRmResourceGroup -Name $rgname -Location $rglocation
		$deployment = New-AzureRmResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -appSku @{code="f4"; name="Free"} -servicePlan "plan1"
	}
	catch
	{
		Assert-True { $Error[1].Contains("The parameter value is not part of the allowed value(s)") }
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}