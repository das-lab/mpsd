














function Test-CreateElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		
		$poolName = Get-ElasticPoolName
		$job = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $poolName -Edition Standard -Dtu 200 -DatabaseDtuMin 10 -DatabaseDtuMax 100 -StorageMB 204800 -AsJob
		$job | Wait-Job
		$ep1 = $job.Output

		Assert-NotNull $ep1
		Assert-AreEqual	Standard $ep1.Edition
		Assert-AreEqual StandardPool $ep1.SkuName
		Assert-AreEqual 200 $ep1.Capacity
		Assert-AreEqual 10 $ep1.DatabaseCapacityMin
		Assert-AreEqual 100 $ep1.DatabaseCapacityMax

		
		$poolName = Get-ElasticPoolName
		$ep2 = $server | New-AzSqlElasticPool -ElasticPoolName $poolName
		Assert-NotNull $ep2
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-CreateVcoreElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		$job = New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
				-ElasticPoolName $poolName -VCore 2 -Edition GeneralPurpose -ComputeGeneration Gen4  -DatabaseVCoreMin 0.1 -DatabaseVCoreMax 2 -AsJob
		$job | Wait-Job
		$ep1 = $job.Output

		Assert-NotNull $ep1
		Assert-AreEqual GP_Gen4 $ep1.SkuName
		Assert-AreEqual GeneralPurpose $ep1.Edition
		Assert-AreEqual 2 $ep1.Capacity
		Assert-AreEqual 0.1 $ep1.DatabaseCapacityMin
		Assert-AreEqual 2.0 $ep1.DatabaseCapacityMax

		
		$poolName = Get-ElasticPoolName
		Assert-ThrowsContains -script { New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-ElasticPoolName $poolName -VCore 1 -Edition BusinessCritial -ComputeGeneration BC_Gen4 -StorageMB 204800 } -message "Mismatch between SKU name 'BC_Gen4_1' and tier 'BusinessCritical'"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-CreateVcoreElasticPoolWithLicenseType
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{

		
		$poolName = Get-ElasticPoolName
		$ep1 = New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
				-ElasticPoolName $poolName -VCore 2 -Edition GeneralPurpose -ComputeGeneration Gen4  -DatabaseVCoreMin 0.1 -DatabaseVCoreMax 2

		Assert-NotNull $ep1
		Assert-AreEqual LicenseIncluded $ep1.LicenseType 

		
		$poolName = Get-ElasticPoolName
		$ep2 = New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
				-ElasticPoolName $poolName -VCore 2 -Edition GeneralPurpose -ComputeGeneration Gen4  -DatabaseVCoreMin 0.1 -DatabaseVCoreMax 2 -LicenseType BasePrice

		Assert-NotNull $ep2
		Assert-AreEqual BasePrice $ep2.LicenseType

		
		$poolName = Get-ElasticPoolName
		$ep3 = New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
				-ElasticPoolName $poolName -VCore 2 -Edition GeneralPurpose -ComputeGeneration Gen4  -DatabaseVCoreMin 0.1 -DatabaseVCoreMax 2 -LicenseType LicenseIncluded

		Assert-NotNull $ep3
		Assert-AreEqual LicenseIncluded $ep3.LicenseType
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-CreateElasticPoolWithZoneRedundancy
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "West Europe"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $poolName -Edition Premium -ZoneRedundant
		Assert-NotNull $ep1
		Assert-AreEqual Premium $ep1.Edition
		Assert-NotNull $ep1.ZoneRedundant
		Assert-AreEqual "true" $ep1.ZoneRedundant

		
		$poolName = Get-ElasticPoolName
		$ep2 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $poolName -Edition Premium -Dtu 125
		Assert-NotNull $ep2
		Assert-AreEqual 125 $ep2.Capacity
		Assert-AreEqual Premium $ep2.Edition
		Assert-NotNull $ep2.ZoneRedundant
		Assert-AreEqual "false" $ep2.ZoneRedundant
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	$poolName = Get-ElasticPoolName
	$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-ElasticPoolName $poolName -Edition Standard -Dtu 200 -DatabaseDtuMin 10 -DatabaseDtuMax 100
	Assert-NotNull $ep1

	$poolName = Get-ElasticPoolName
	$ep2 = $server | New-AzSqlElasticPool -ElasticPoolName $poolName -Edition Standard -Dtu 400 -DatabaseDtuMin 10 `
		 -DatabaseDtuMax 100
	Assert-NotNull $ep2


	try
	{
		
		$job = Set-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $ep1.ElasticPoolName -Dtu 400 -DatabaseDtuMin 0 -DatabaseDtuMax 50 -Edition Standard -StorageMB 409600 -AsJob
		$job | Wait-Job
		$sep1 = $job.Output

		Assert-NotNull $sep1
		Assert-AreEqual 400 $sep1.Capacity
		Assert-AreEqual 429496729600 $sep1.MaxSizeBytes
		Assert-AreEqual Standard $sep1.Edition
		Assert-AreEqual StandardPool $sep1.SkuName
		Assert-AreEqual 0 $sep1.DatabaseCapacityMin
		Assert-AreEqual 50 $sep1.DatabaseCapacityMax

		
		$sep2 = $server | Set-AzSqlElasticPool -ElasticPoolName $ep2.ElasticPoolName -Dtu 200 `
			-DatabaseDtuMin 10 -DatabaseDtuMax 50  -Edition Standard -StorageMB 204800

		Assert-NotNull $sep2
		Assert-AreEqual 200 $sep2.Capacity
		Assert-AreEqual 214748364800 $sep2.MaxSizeBytes
		Assert-AreEqual Standard $sep2.Edition
		Assert-AreEqual StandardPool $sep2.SkuName
		Assert-AreEqual 10 $sep2.DatabaseCapacityMin
		Assert-AreEqual 50 $sep2.DatabaseCapacityMax
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateVcoreElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	
	$poolName = Get-ElasticPoolName
	$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-ElasticPoolName $poolName -VCore 2 -Edition GeneralPurpose -ComputeGeneration Gen4
	Assert-NotNull $ep1

	
	$poolName = Get-ElasticPoolName
	$ep2 = $server | New-AzSqlElasticPool -ElasticPoolName $poolName -Edition Standard -Dtu 400 -DatabaseDtuMin 10 `
		 -DatabaseDtuMax 100
	Assert-NotNull $ep2

	try
	{
		
		$job = Set-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $ep1.ElasticPoolName -Dtu 400 -DatabaseDtuMin 0 -DatabaseDtuMax 50 -Edition Standard -StorageMB 409600 -AsJob
		$job | Wait-Job
		$sep1 = $job.Output

		Assert-NotNull $sep1
		Assert-AreEqual 400 $sep1.Capacity
		Assert-AreEqual 429496729600 $sep1.MaxSizeBytes
		Assert-AreEqual Standard $sep1.Edition
		Assert-AreEqual StandardPool $sep1.SkuName
		Assert-AreEqual 0 $sep1.DatabaseCapacityMin
		Assert-AreEqual 50 $sep1.DatabaseCapacityMax

		
		$sep2 = $server | Set-AzSqlElasticPool -ElasticPoolName $ep2.ElasticPoolName -VCore 2 `
			-Edition GeneralPurpose -ComputeGeneration Gen4 -StorageMB 204800

		Assert-NotNull $sep2
		Assert-AreEqual 2 $sep2.Capacity
		Assert-AreEqual 214748364800 $sep2.MaxSizeBytes
		Assert-AreEqual GeneralPurpose $sep2.Edition
		Assert-AreEqual GP_Gen4 $sep2.SkuName
		Assert-AreEqual 0 $sep2.DatabaseCapacityMin
		Assert-AreEqual 2 $sep2.DatabaseCapacityMax

		
		$sep3 = $server | Set-AzSqlElasticPool -ElasticPoolName $ep2.ElasticPoolName -DatabaseVCoreMin 0.1
		Assert-NotNull $sep3
		Assert-AreEqual 0.1 $sep3.DatabaseCapacityMin

		
		$sep4 = $server | Set-AzSqlElasticPool -ElasticPoolName $ep2.ElasticPoolName -VCore 1
		Assert-NotNull $sep4
		Assert-AreEqual 1 $sep4.Capacity
		Assert-AreEqual 0.1 $sep4.DatabaseCapacityMin
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateVcoreElasticPoolWithLicenseType
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	
	$poolName = Get-ElasticPoolName
	$ep1 = New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $poolName -VCore 2 -Edition GeneralPurpose -ComputeGeneration Gen4
	Assert-NotNull $ep1

	try
	{
		
		$resp = Set-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $ep1.ElasticPoolName -LicenseType BasePrice
		Assert-AreEqual $resp.LicenseType BasePrice

		
		$resp = Set-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $ep1.ElasticPoolName -LicenseType LicenseIncluded
		Assert-AreEqual $resp.LicenseType LicenseIncluded
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateElasticPoolWithZoneRedundancy
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "West Europe"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $poolName -Edition Premium -Dtu 125
		Assert-NotNull $ep1

		
		$sep1 = Set-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $ep1.ElasticPoolName -ZoneRedundant
		Assert-NotNull $sep1
		Assert-NotNull $sep1.ZoneRedundant
		Assert-AreEqual "true" $sep1.ZoneRedundant
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	$poolName = Get-ElasticPoolName
	$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-ElasticPoolName $poolName -Edition Standard -Dtu 200 -DatabaseDtuMin 10 -DatabaseDtuMax 100
	Assert-NotNull $ep1

	$poolName = Get-ElasticPoolName
	$ep2 = $server | New-AzSqlElasticPool -ElasticPoolName $poolName -Edition Standard -Dtu 400 -DatabaseDtuMin 0 `
		 -DatabaseDtuMax 100
	Assert-NotNull $ep2

	try
	{
		
		$gep1 = Get-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $ep1.ElasticPoolName
		Assert-NotNull $ep1
		Assert-AreEqual 200 $ep1.Capacity
		Assert-AreEqual 204800 $ep1.StorageMB
		Assert-AreEqual Standard $ep1.Edition
		Assert-AreEqual 10 $ep1.DatabaseCapacityMin
		Assert-AreEqual 100 $ep1.DatabaseCapacityMax

		
		$gep2 = $ep2 | Get-AzSqlElasticPool
		Assert-NotNull $ep2
		Assert-AreEqual 400 $ep2.Capacity
		Assert-AreEqual 409600 $ep2.StorageMB
		Assert-AreEqual Standard $ep2.Edition
		Assert-AreEqual 0 $ep2.DatabaseCapacityMin
		Assert-AreEqual 100 $ep2.DatabaseCapacityMax

		$all = $server | Get-AzSqlElasticPool -ElasticPoolName *
		Assert-AreEqual $all.Count 2
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetElasticPoolWithZoneRedundancy
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "West Europe"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$poolName = Get-ElasticPoolName
		$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $poolName -Edition Premium -ZoneRedundant

		
		$gep1 = Get-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $ep1.ElasticPoolName
		Assert-NotNull $gep1.ZoneRedundant
		Assert-AreEqual "true" $gep1.ZoneRedundant

		
		$poolName = Get-ElasticPoolName
		$ep2 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $poolName -Edition Premium -Dtu 125

		
		$gep2 = Get-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-ElasticPoolName $ep2.ElasticPoolName
		Assert-NotNull $gep2.ZoneRedundant
		Assert-AreEqual "false" $gep2.ZoneRedundant
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RemoveElasticPool
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	$poolName = Get-ElasticPoolName
	$ep1 = New-AzSqlElasticPool  -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-ElasticPoolName $poolName -Edition Standard -Dtu 200 -DatabaseDtuMin 10 -DatabaseDtuMax 100
	Assert-NotNull $ep1

	$poolName = Get-ElasticPoolName
	$ep2 = $server | New-AzSqlElasticPool -ElasticPoolName $poolName -Edition Standard -Dtu 400 -DatabaseDtuMin 0 `
		 -DatabaseDtuMax 100
	Assert-NotNull $ep2

	try
	{
		
		Remove-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -ElasticPoolName $ep1.ElasticPoolName –Confirm:$false

		
		$ep2 | Remove-AzSqlElasticPool -Force

		$all = $server | Get-AzSqlElasticPool
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-ListAndCancelElasticPoolOperation
{
	
	$location = Get-Location "Microsoft.Sql" "operations" "Southeast Asia"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

	$poolName = Get-ElasticPoolName
	$ep1 = New-AzSqlElasticPool -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-ElasticPoolName $poolName -Edition Premium -Dtu 125 -DatabaseDtuMin 0 -DatabaseDtuMax 50
	Assert-NotNull $ep1

	$poolName = Get-ElasticPoolName
	$ep2 = $server | New-AzSqlElasticPool -ElasticPoolName $poolName -Edition Premium -Dtu 250 -DatabaseDtuMin 0 `
		 -DatabaseDtuMax 50
	Assert-NotNull $ep2

	

	try
	{
		
		$ep1update = Set-AzSqlElasticPool -ResourceGroupName $ep1.ResourceGroupName -ServerName $ep1.ServerName -ElasticPoolName $ep1.ElasticPoolName `
			-Edition Premium -Dtu 250 -DatabaseDtuMin 25 -DatabaseDtuMax 125
		Assert-AreEqual $ep1.ElasticPoolName $ep1update.ElasticPoolName
		Assert-AreEqual Premium $ep1update.Edition
		Assert-AreEqual 250 $ep1update.Capacity

		
		$epactivity = Get-AzSqlElasticPoolActivity -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $ep1update.ElasticPoolName
		$epactivityId

		For($i=0; $i -lt $epactivity.Length; $i++) {
			if($epactivity[$i].Operation -eq "UPDATE"){
				$epactivityId = $epactivity[$i].OperationId
			}
		}

		try
		{
			
			$activityCancel = Stop-AzSqlElasticPoolActivity -ResourceGroupName $ep1.ResourceGroupName -ServerName $ep1.ServerName -ElasticPoolName $ep1.ElasticPoolName -OperationId $epactivityId
		}
		Catch
		{
			$ErrorMessage = $_.Exception.Message
			Assert-AreEqual True $ErrorMessage.Contains("Cannot cancel management operation '" + $epactivityId + "' in the current state") $ErrorMessage
		}

		
		
		$ep2update = Set-AzSqlElasticPool -ResourceGroupName $ep2.ResourceGroupName -ServerName $ep2.ServerName -ElasticPoolName $ep2.ElasticPoolName `
			-Edition Premium -Dtu 500 -DatabaseDtuMin 25 -DatabaseDtuMax 250
		Assert-AreEqual $ep2.ElasticPoolName $ep2update.ElasticPoolName
		Assert-AreEqual Premium $ep2update.Edition
		Assert-AreEqual 500 $ep2update.Capacity

		$epactivity = $ep2update | Get-AzSqlElasticPoolActivity
		For($i=0; $i -lt $epactivity.Length; $i++) {
			if($epactivity[$i].Operation -eq "UPDATE"){
				$epactivityId = $epactivity[$i].OperationId
			}
		}

		$epactivity = $ep2update | Get-AzSqlElasticPoolActivity -OperationId $epactivityId

		try
		{
			
			$activityCancel = $epactivity | Stop-AzSqlElasticPoolActivity
		}
		Catch
		{
			$ErrorMessage = $_.Exception.Message
			Assert-AreEqual True $ErrorMessage.Contains("Cannot cancel management operation '" + $epactivityId + "' in the current state") $ErrorMessage
		}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}