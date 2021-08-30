














function Test-ManagedLiveDatabaseShortTermRetentionPolicy
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId

	
	$invalidRetention = 45

 	try
	{
		
		$managedDatabaseName = Get-ManagedDatabaseName
		$collation = "SQL_Latin1_General_CP1_CI_AS"
		$job1 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -Collation $collation -AsJob
		$job1 | Wait-Job
		$db = $job1.Output

		Assert-AreEqual $db.Name $managedDatabaseName
		Assert-NotNull $db.Collation
		Assert-NotNull $db.CreationDate

 		
		$retention = 28
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName -RetentionDays $retention
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy.RetentionDays

 		
		$retention = 21
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -AzureInstanceDatabaseObject $db[0] -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -AzureInstanceDatabaseObject $db[0]
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays

 		
		$retention = 14
		$resourceId = $db.Id + "/backupShortTermRetentionPolicies/default"
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceId $resourceId -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceId $resourceId
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays

 		
		$retention = 7
		$policy = $db | Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = $db | Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
 	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ManagedDeletedDatabaseShortTermRetentionPolicy
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId

	
	$invalidRetention = 45

 	try
	{
		
		$managedDatabaseName = Get-ManagedDatabaseName
		$collation = "SQL_Latin1_General_CP1_CI_AS"
		$job1 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -Collation $collation -AsJob
		$job1 | Wait-Job
		$db = $job1.Output

		Assert-AreEqual $db.Name $managedDatabaseName
		Assert-NotNull $db.Collation
		Assert-NotNull $db.CreationDate

 		
		$retention = 35
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName -RetentionDays $retention
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy.RetentionDays

		
		Remove-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -Force

		
		$deletedDatabases = Get-AzSqlDeletedInstanceDatabaseBackup -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName 

 		
		$retention = 29
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName -DeletionDate $deletedDatabases[0].DeletionDate -RetentionDays $retention
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName -DeletionDate $deletedDatabases[0].DeletionDate
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy.RetentionDays

 		
		$retention = 21
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -AzureInstanceDatabaseObject $deletedDatabases[0] -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -AzureInstanceDatabaseObject $deletedDatabases[0]
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays

 		
		$retention = 14
		$resourceId = $deletedDatabases[0].Id + "/backupShortTermRetentionPolicies/default"
		$policy = Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceId $resourceId -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -ResourceId $resourceId
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays

 		
		$retention = 7
		$policy = $deletedDatabases[0] | Set-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
		$policy = $deletedDatabases[0] | Get-AzSqlInstanceDatabaseBackupShortTermRetentionPolicy
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy.RetentionDays
 	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}