














function Test-CreateManagedDatabase
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId

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

		
		$managedDatabaseName = Get-ManagedDatabaseName
		$db = New-AzSqlInstanceDatabase -InstanceObject $managedInstance -Name $managedDatabaseName
		Assert-AreEqual $db.Name $managedDatabaseName
		Assert-NotNull $db.Collation
		Assert-NotNull $db.CreationDate

		
		$managedDatabaseName = Get-ManagedDatabaseName
		$db = $managedInstance | New-AzSqlInstanceDatabase -Name $managedDatabaseName
		Assert-AreEqual $db.Name $managedDatabaseName
		Assert-NotNull $db.Collation
		Assert-NotNull $db.CreationDate
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetManagedDatabase
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId
	
	
	$managedDatabaseName = Get-ManagedDatabaseName
	$db1 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName
	Assert-AreEqual $db1.Name $managedDatabaseName

	$managedDatabaseName = Get-ManagedDatabaseName
	$db2 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName
	Assert-AreEqual $db2.Name $managedDatabaseName

	try
	{
		
		$gdb1 = Get-AzSqlInstanceDatabase -ResourceGroupName $managedInstance.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $db1.Name
		Assert-NotNull $gdb1
		Assert-AreEqual $db1.Name $gdb1.Name
		Assert-AreEqual $db1.Collation $gdb1.Collation

		
		$all = Get-AzSqlInstanceDatabase -ResourceGroupName $managedInstance.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name *
		Assert-NotNull $all
		Assert-AreEqual $all.Count 2

		
		$gdb2 = Get-AzSqlInstanceDatabase -InstanceResourceId $managedInstance.Id -Name $db1.Name
		Assert-NotNull $gdb2
		Assert-AreEqual $db1.Name $gdb2.Name
		Assert-AreEqual $db1.Collation $gdb2.Collation

		
		$all = $managedInstance | Get-AzSqlInstanceDatabase
		Assert-AreEqual $all.Count 2
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RemoveManagedDatabase
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId
	
	
	$managedDatabaseName = Get-ManagedDatabaseName
	$db1 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName
	Assert-AreEqual $db1.Name $managedDatabaseName

	$managedDatabaseName = Get-ManagedDatabaseName
	$db2 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName
	Assert-AreEqual $db2.Name $managedDatabaseName

	$managedDatabaseName = Get-ManagedDatabaseName
	$db3 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName
	Assert-AreEqual $db3.Name $managedDatabaseName

	$managedDatabaseName = Get-ManagedDatabaseName
	$db4 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName
	Assert-AreEqual $db4.Name $managedDatabaseName

	$all = $managedInstance | Get-AzSqlInstanceDatabase
	Assert-AreEqual $all.Count 4

	try
	{
		
		Remove-AzSqlInstanceDatabase -ResourceGroupName $managedInstance.ResourceGroupname -InstanceName $managedInstance.ManagedInstanceName -Name $db1.Name -Force
		
		$all = $managedInstance | Get-AzSqlInstanceDatabase
		Assert-AreEqual $all.Count 3

		
		$db2 | Remove-AzSqlInstanceDatabase -Force

		$all = $managedInstance | Get-AzSqlInstanceDatabase
		Assert-AreEqual $all.Count 2

		
		Remove-AzSqlInstanceDatabase -InputObject $db3 -Force
		
		$all = $managedInstance | Get-AzSqlInstanceDatabase
		Assert-AreEqual $all.Count 1

		
		Remove-AzSqlInstanceDatabase -ResourceId $db4.Id -Force
		
		$all = $managedInstance | Get-AzSqlInstanceDatabase
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RestoreManagedDatabase
{
	
	$rg = Create-ResourceGroupForTest
	$rg2 = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId
	$managedInstance2 = Create-ManagedInstanceForTest $rg2 $subnetId

	try
	{
		
		$managedDatabaseName = Get-ManagedDatabaseName
		$collation = "SQL_Latin1_General_CP1_CI_AS"
		$job1 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -Collation $collation -AsJob
		$job1 | Wait-Job
		$db = $job1.Output

		Assert-AreEqual $db.Name $managedDatabaseName

		$targetManagedDatabaseName = Get-ManagedDatabaseName
		$pointInTime = (Get-date).AddMinutes(5)

		
		Wait-Seconds 450

		
		$restoredDb = Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -PointInTime $pointInTime -TargetInstanceDatabaseName $targetManagedDatabaseName
		Assert-NotNull $restoredDb
		Assert-AreEqual $restoredDb.Name $targetManagedDatabaseName
		Assert-AreEqual $restoredDb.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $restoredDb.ManagedInstanceName $managedInstance.ManagedInstanceName

		
		$restoredDb2 = Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -PointInTime $pointInTime -TargetInstanceDatabaseName $targetManagedDatabaseName -TargetInstanceName $managedInstance2.ManagedInstanceName -TargetResourceGroupName $rg2.ResourceGroupName
		Assert-NotNull $restoredDb2
		Assert-AreEqual $restoredDb2.Name $targetManagedDatabaseName
		Assert-AreEqual $restoredDb2.ResourceGroupName $rg2.ResourceGroupName
		Assert-AreEqual $restoredDb2.ManagedInstanceName $managedInstance2.ManagedInstanceName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $rg2
	}
}


function Test-RestoreDeletedManagedDatabase
{
	
	$rg = Create-ResourceGroupForTest
	$rg2 = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId
	$managedInstance2 = Create-ManagedInstanceForTest $rg2 $subnetId

	try
	{
		
		$managedDatabaseName = Get-ManagedDatabaseName
		$collation = "SQL_Latin1_General_CP1_CI_AS"
		$job1 = New-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -Collation $collation -AsJob
		$job1 | Wait-Job
		$db = $job1.Output

		Assert-AreEqual $db.Name $managedDatabaseName

		$targetManagedDatabaseName1 = Get-ManagedDatabaseName
		$targetManagedDatabaseName2 = Get-ManagedDatabaseName
		$targetManagedDatabaseName3 = Get-ManagedDatabaseName
		$targetManagedDatabaseName4 = Get-ManagedDatabaseName
		$targetManagedDatabaseName5 = Get-ManagedDatabaseName

		
		Wait-Seconds 450

		
		Remove-AzSqlInstanceDatabase -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -Force

		
		$deletedDatabases = Get-AzSqlDeletedInstanceDatabaseBackup -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -DatabaseName $managedDatabaseName 

		
		$restoredDb1 = Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -DeletionDate $deletedDatabases[0].DeletionDate -PointInTime $deletedDatabases[0].EarliestRestorePoint -TargetInstanceDatabaseName $targetManagedDatabaseName1
		Assert-NotNull $restoredDb1
		Assert-AreEqual $restoredDb1.Name $targetManagedDatabaseName1
		Assert-AreEqual $restoredDb1.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $restoredDb1.ManagedInstanceName $managedInstance.ManagedInstanceName

		
		$restoredDb2 = Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -ResourceGroupName $rg.ResourceGroupName -InstanceName $managedInstance.ManagedInstanceName -Name $managedDatabaseName -DeletionDate $deletedDatabases[0].DeletionDate -PointInTime $deletedDatabases[0].EarliestRestorePoint -TargetInstanceDatabaseName $targetManagedDatabaseName2 -TargetInstanceName $managedInstance2.ManagedInstanceName -TargetResourceGroupName $rg2.ResourceGroupName
		Assert-NotNull $restoredDb2
		Assert-AreEqual $restoredDb2.Name $targetManagedDatabaseName2
		Assert-AreEqual $restoredDb2.ResourceGroupName $rg2.ResourceGroupName
		Assert-AreEqual $restoredDb2.ManagedInstanceName $managedInstance2.ManagedInstanceName

		
		$restoredDb3 = Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -InputObject $deletedDatabases[0] -PointInTime $deletedDatabases[0].EarliestRestorePoint -TargetInstanceDatabaseName $targetManagedDatabaseName3
		Assert-NotNull $restoredDb3
		Assert-AreEqual $restoredDb3.Name $targetManagedDatabaseName3
		Assert-AreEqual $restoredDb3.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $restoredDb3.ManagedInstanceName $managedInstance.ManagedInstanceName

		
		$restoredDb4 = Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -ResourceId $deletedDatabases[0].Id -PointInTime $deletedDatabases[0].EarliestRestorePoint -TargetInstanceDatabaseName $targetManagedDatabaseName4
		Assert-NotNull $restoredDb4
		Assert-AreEqual $restoredDb4.Name $targetManagedDatabaseName4
		Assert-AreEqual $restoredDb4.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $restoredDb4.ManagedInstanceName $managedInstance.ManagedInstanceName.

		
		$restoredDb5 = $deletedDatabases[0] | Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -PointInTime $deletedDatabases[0].EarliestRestorePoint -TargetInstanceDatabaseName $targetManagedDatabaseName5
		Assert-NotNull $restoredDb5
		Assert-AreEqual $restoredDb5.Name $targetManagedDatabaseName5
		Assert-AreEqual $restoredDb5.ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $restoredDb5.ManagedInstanceName $managedInstance.ManagedInstanceName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $rg2
	}
}


function Test-GetManagedDatabaseGeoBackup
{
	
	$rgName = "restore-rg"	
	$managedInstanceName = "testbrinstance"
	$managedDatabaseName = "sourcedb"

	
	$gdb1 = Get-AzSqlInstanceDatabaseGeoBackup -ResourceGroupName $rgName -InstanceName $managedInstanceName -Name $managedDatabaseName
	Assert-NotNull $gdb1
	Assert-AreEqual $managedDatabaseName $gdb1.Name

	
	$all = Get-AzSqlInstanceDatabaseGeoBackup -ResourceGroupName $rgName -InstanceName $managedInstanceName -Name *

	Assert-NotNull $all
	if($all.Count -le 1)
	{
        throw "Should get more than 1 backup geo-redundant backups"
    }
}


function Test-GeoRestoreManagedDatabase
{
	
    $rgName = "restore-rg"	
	$managedInstanceName = "testbrinstance"
	$managedDatabaseName = "sourcedb"

	$targetRgName = "restore-rg"
	$targetInstanceName = "testbrinstance"
	try
	{
		$sourceDbGeoBackup = Get-AzSqlInstanceDatabaseGeoBackup -ResourceGroupName $rgName -InstanceName $managedInstanceName -Name $managedDatabaseName

		Assert-NotNull $sourceDbGeoBackup

		$targetManagedDatabaseName1 = Get-ManagedDatabaseName
		$targetManagedDatabaseName2 = Get-ManagedDatabaseName
		$targetManagedDatabaseName3 = Get-ManagedDatabaseName
		$targetManagedDatabaseName4 = Get-ManagedDatabaseName

		
		$restoredDb1 = Restore-AzSqlInstanceDatabase -FromGeoBackup -ResourceId $sourceDbGeoBackup.RecoverableDatabaseId -TargetInstanceDatabaseName $targetManagedDatabaseName1 -TargetInstanceName $targetInstanceName -TargetResourceGroupName $targetRgName
		Assert-NotNull $restoredDb1
		Assert-AreEqual $restoredDb1.Name $targetManagedDatabaseName1
		Assert-AreEqual $restoredDb1.ResourceGroupName $targetRgName
		Assert-AreEqual $restoredDb1.ManagedInstanceName $targetInstanceName

		
		$restoredDb2 = Restore-AzSqlInstanceDatabase -FromGeoBackup -ResourceGroupName $rgName -InstanceName $managedInstanceName -Name $managedDatabaseName -TargetInstanceDatabaseName $targetManagedDatabaseName2 -TargetInstanceName $targetInstanceName -TargetResourceGroupName $targetRgName
		Assert-NotNull $restoredDb2
		Assert-AreEqual $restoredDb2.Name $targetManagedDatabaseName2
		Assert-AreEqual $restoredDb2.ResourceGroupName $targetRgName
		Assert-AreEqual $restoredDb2.ManagedInstanceName $targetInstanceName
		
		
		$restoredDb3 = Restore-AzSqlInstanceDatabase -FromGeoBackup -GeoBackupObject $sourceDbGeoBackup -TargetInstanceDatabaseName $targetManagedDatabaseName3 -TargetInstanceName $targetInstanceName -TargetResourceGroupName $targetRgName
		Assert-NotNull $restoredDb3
		Assert-AreEqual $restoredDb3.Name $targetManagedDatabaseName3
		Assert-AreEqual $restoredDb3.ResourceGroupName $targetRgName
		Assert-AreEqual $restoredDb3.ManagedInstanceName $targetInstanceName

		
		$restoredDb4 = $sourceDbGeoBackup | Restore-AzSqlInstanceDatabase -FromGeoBackup -TargetInstanceDatabaseName $targetManagedDatabaseName4 -TargetInstanceName $targetInstanceName -TargetResourceGroupName $targetRgName
		Assert-NotNull $restoredDb4
		Assert-AreEqual $restoredDb4.Name $targetManagedDatabaseName4
		Assert-AreEqual $restoredDb4.ResourceGroupName $targetRgName
	   Assert-AreEqual $restoredDb4.ManagedInstanceName $targetInstanceName	

	}
	finally
	{
		$restoredDb1 | Remove-AzSqlInstanceDatabase -Force
		$restoredDb2 | Remove-AzSqlInstanceDatabase -Force
		$restoredDb3 | Remove-AzSqlInstanceDatabase -Force
		$restoredDb4 | Remove-AzSqlInstanceDatabase -Force
	}
}