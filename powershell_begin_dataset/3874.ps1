














function Test-CreateNewAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
	$capacity = 2
	$skuName = "S2"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$job = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier "Standard" -WorkerSize Medium -NumberOfWorkers $capacity -AsJob
		$job | Wait-Job
		$createResult = $job | Receive-Job

		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual "Standard" $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name
		Assert-AreEqual $capacity $createResult.Sku.Capacity

		

		$getResult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual "Standard" $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
		Assert-AreEqual $capacity $getResult.Sku.Capacity
	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewAppServicePlanHyperV
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
    $capacity = 1
	$skuName = "PC2"
    $tier = "PremiumContainer"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$job = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Small -HyperV  -AsJob
		$job | Wait-Job
		$createResult = $job | Receive-Job

		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual $tier $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name
		Assert-AreEqual $capacity $createResult.Sku.Capacity

		

		$getResult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual PremiumContainer $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
		Assert-AreEqual $capacity $getResult.Sku.Capacity
        Assert-AreEqual $true $getResult.IsXenon
        Assert-AreEqual "windows" $getResult.Kind

	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}



function Test-SetAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
	$tier = "Shared"
	$skuName ="D1"
	$capacity = 0
	$perSiteScaling = $false;

	$newTier ="PremiumV2"
	$newSkuName = "P2v2"
	$newWorkerSize = "Medium"
	$newCapacity = 2
	$newPerSiteScaling = $true;


	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		
		$actual = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -PerSiteScaling $perSiteScaling
		$result = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName
		
		Assert-AreEqual $whpName $result.Name
		Assert-AreEqual $capacity $result.Sku.Capacity
		Assert-AreEqual $tier $result.Sku.Tier
		Assert-AreEqual $skuName $result.Sku.Name
		Assert-AreEqual $perSiteScaling $result.PerSiteScaling

		
		$job = Set-AzAppServicePlan  -ResourceGroupName $rgname -Name  $whpName -Tier $newTier -NumberofWorkers $newCapacity -WorkerSize $newWorkerSize -PerSiteScaling $newPerSiteScaling -AsJob
		$job | Wait-Job
		$newresult = $job | Receive-Job

		
		Assert-AreEqual $whpName $newresult.Name
		Assert-AreEqual $newCapacity $newresult.Sku.Capacity
		Assert-AreEqual $newTier $newresult.Sku.Tier
		Assert-AreEqual $newSkuName $newresult.Sku.Name
		Assert-AreEqual $newPerSiteScaling $newresult.PerSiteScaling

		
		$newresult.Sku.Capacity = $capacity
		$newresult.Sku.Tier = $tier
		$newresult.Sku.Name = $skuName
		$newresult.PerSiteScaling = $perSiteScaling

		$newresult | Set-AzAppServicePlan

		
		$newresult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName

		
		Assert-AreEqual $whpName $newresult.Name
		Assert-AreEqual $capacity $newresult.Sku.Capacity
		Assert-AreEqual $tier $newresult.Sku.Tier
		Assert-AreEqual $skuName $newresult.Sku.Name
		Assert-AreEqual $perSiteScaling $newresult.PerSiteScaling

	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-GetAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	$location1 = Get-Location
	$serverFarmName1 = Get-WebHostPlanName
	$tier1 = "Shared"
	$skuName1 ="D1"
	$capacity1 = 0

	$location2 = Get-SecondaryLocation
	$serverFarmName2 = Get-WebHostPlanName
	$tier2 ="Standard"
	$skuName2 = "S2"
	$workerSize2 = "Medium"
	$capacity2 = 2
	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location1
		$serverFarm1 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 -Location  $location1 -Tier $tier1
		
		
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name
		
		
		$serverFarm1 = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 

		
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name

		
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName2 -Location  $location2 -Tier $tier2 -WorkerSize $workerSize2 -NumberofWorkers $capacity2
		
		
		Assert-AreEqual $serverFarmName2 $serverFarm2.Name
		Assert-AreEqual $capacity2 $serverFarm2.Sku.Capacity
		Assert-AreEqual $tier2 $serverFarm2.Sku.Tier
		Assert-AreEqual $skuName2 $serverFarm2.Sku.Name
		
		
		$result = Get-AzAppServicePlan -Name $serverFarmName1

		
		Assert-AreEqual 1 $result.Count
		$serverFarm1 = $result[0]
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name

		
		$result = Get-AzAppServicePlan

		
		Assert-True { $result.Count -ge 2 }

		
		$result = Get-AzAppServicePlan -Location $location1 | Select -expand Name 
		
		
		Assert-True { $result -contains $serverFarmName1 }
		Assert-False { $result -contains $serverFarmName2 }

		
		$result = Get-AzAppServicePlan -ResourceGroupName $rgname | Select -expand Name
		
		
		Assert-AreEqual 2 $result.Count
		Assert-True { $result -contains $serverFarmName1 }
		Assert-True { $result -contains $serverFarmName2 }

	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName2 -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$serverFarmName = Get-WebHostPlanName
	$location = Get-Location
	$capacity = 0
	$skuName = "D1"
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName -Location  $location -Tier $tier
		
		
		Assert-AreEqual $serverFarmName $serverFarm.Name
		Assert-AreEqual $tier $serverFarm.Sku.Tier
		Assert-AreEqual $skuName $serverFarm.Sku.Name
		Assert-AreEqual $capacity $serverFarm.Sku.Capacity

		
		$serverFarm |Remove-AzAppServicePlan -Force -AsJob | Wait-Job
		
		$result = Get-AzAppServicePlan -ResourceGroupName $rgname

		Assert-AreEqual 0 $result.Count 
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewAppServicePlanInAse
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = "West US"
	$capacity = 1
	$skuName = "I1"
	$skuTier = "Isolated"
	$aseName = "asedemops"
	$aseResourceGroupName = "asedemorg"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$createResult = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $skuTier -WorkerSize Medium -NumberOfWorkers $capacity -AseName $aseName -AseResourceGroupName $aseResourceGroupName
		
		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual "Isolated" $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name

		
		$getResult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual "Isolated" $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}