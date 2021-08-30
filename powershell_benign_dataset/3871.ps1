














function Test-GetWebAppAccessRestriction
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "S1"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname

		
		Assert-AreEqual $false $actual.ScmSiteUseMainSiteRestrictionConfig
		Assert-AreEqual 1 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "Allow all" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
		Assert-AreEqual 1 $actual.ScmSiteAccessRestrictions.Count
		Assert-AreEqual "Allow all" $actual.ScmSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.ScmSiteAccessRestrictions[0].Action

	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-UpdateWebAppAccessRestrictionSimple
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "S1"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		Update-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname -ScmSiteUseMainSiteRestrictionConfig
		$actual = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname

		
		Assert-AreEqual $true $actual.ScmSiteUseMainSiteRestrictionConfig
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-UpdateWebAppAccessRestrictionComplex
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Update-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname -ScmSiteUseMainSiteRestrictionConfig -PassThru

		
		Assert-AreEqual $true $actual.ScmSiteUseMainSiteRestrictionConfig

		
		Update-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname -ScmSiteUseMainSiteRestrictionConfig:$false
		$actual = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname

		
		Assert-AreEqual $false $actual.ScmSiteUseMainSiteRestrictionConfig
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-AddWebAppAccessRestriction
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -Action Allow -IpAddress 130.220.0.0/27 -Priority 200 -PassThru

		
		Assert-AreEqual 2 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "developers" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
		Assert-AreEqual "Deny all" $actual.MainSiteAccessRestrictions[1].RuleName
		Assert-AreEqual "Deny" $actual.MainSiteAccessRestrictions[1].Action
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-AddWebAppAccessRestrictionServiceEndpoint
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$vNetResourceGroupName = "pstest-rg"
	$vNetName = "pstest-vnet"
	$subnetName = "endpoint-subnet"
	$tier = "Shared"

	try
	{
		
		Write-Debug "Starting Test-AddWebAppAccessRestrictionServiceEndpoint"
		New-AzResourceGroup -Name $rgname -Location $location
		
		
		
		
		

		
		$subscriptionId = getSubscription
		$subnetId = '/subscriptions/' + $subscriptionId + '/resourceGroups/' + $vNetResourceGroupName + '/providers/Microsoft.Network/virtualNetworks/' + $vNetName +  '/subnets/' + $subnetName
				
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
				
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId		
		
		
		$actual = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name vNetIntegration -Action Allow -SubnetId $subnetId -Priority 150 -PassThru

		
		Assert-AreEqual 2 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "vNetIntegration" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
		Assert-AreEqual "Deny all" $actual.MainSiteAccessRestrictions[1].RuleName
		Assert-AreEqual "Deny" $actual.MainSiteAccessRestrictions[1].Action

		
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveWebAppAccessRestriction
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -Action Allow -IpAddress 130.220.0.0/27 -Priority 200 -PassThru

		
		Assert-AreEqual 2 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "developers" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
		Assert-AreEqual "Deny all" $actual.MainSiteAccessRestrictions[1].RuleName
		Assert-AreEqual "Deny" $actual.MainSiteAccessRestrictions[1].Action

		
		$actual = Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -PassThru

		
		Assert-AreEqual 1 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "Allow all" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-AddWebAppAccessRestrictionScm
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -Action Allow -IpAddress 130.220.0.0/27 -Priority 200 -TargetScmSite -PassThru

		
		Assert-AreEqual 2 $actual.ScmSiteAccessRestrictions.Count
		Assert-AreEqual "developers" $actual.ScmSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.ScmSiteAccessRestrictions[0].Action
		Assert-AreEqual "Deny all" $actual.ScmSiteAccessRestrictions[1].RuleName
		Assert-AreEqual "Deny" $actual.ScmSiteAccessRestrictions[1].Action
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveWebAppAccessRestrictionScm
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -Action Allow -IpAddress 130.220.0.0/27 -Priority 200 -TargetScmSite -PassThru

		
		Assert-AreEqual 2 $actual.ScmSiteAccessRestrictions.Count
		Assert-AreEqual "developers" $actual.ScmSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.ScmSiteAccessRestrictions[0].Action
		Assert-AreEqual "Deny all" $actual.ScmSiteAccessRestrictions[1].RuleName
		Assert-AreEqual "Deny" $actual.ScmSiteAccessRestrictions[1].Action

		
		$actual = Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -TargetScmSite -PassThru

		
		Assert-AreEqual 1 $actual.ScmSiteAccessRestrictions.Count
		Assert-AreEqual "Allow all" $actual.ScmSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.ScmSiteAccessRestrictions[0].Action
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-AddWebAppAccessRestrictionSlot
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName	
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$slotName = "stage"
	$tier = "S1"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		$webAppSlot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -AppServicePlan $whpName -Slot $slotName

		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$actual = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $rgname -Name $wname -SlotName $slotName

		
		Assert-AreEqual $false $actual.ScmSiteUseMainSiteRestrictionConfig
		Assert-AreEqual 1 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "Allow all" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
		Assert-AreEqual 1 $actual.ScmSiteAccessRestrictions.Count
		Assert-AreEqual "Allow all" $actual.ScmSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.ScmSiteAccessRestrictions[0].Action

		
		$actual = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rgname -WebAppName $wname -Name developers -Action Allow -IpAddress 130.220.0.0/27 -Priority 200 -SlotName $slotName -PassThru

		
		Assert-AreEqual 2 $actual.MainSiteAccessRestrictions.Count
		Assert-AreEqual "developers" $actual.MainSiteAccessRestrictions[0].RuleName
		Assert-AreEqual "Allow" $actual.MainSiteAccessRestrictions[0].Action
		Assert-AreEqual "Deny all" $actual.MainSiteAccessRestrictions[1].RuleName
		Assert-AreEqual "Deny" $actual.MainSiteAccessRestrictions[1].Action
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}