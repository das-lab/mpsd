












function Test-CreateAndGetService
{
	$rg = Create-ResourceGroupForTest
	try
	{
		$service = Create-DataMigrationService($rg)

		
		$all = Get-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual 1 $all.Count
		
		
		$all = Get-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name

		Assert-AreEqual $service.Name $all[0].Name
		Assert-AreEqual $rg.Location $all[0].Location
		Assert-AreEqual $service.Service.VirtualSubnetId $all[0].Service.VirtualSubnetId

		
		Assert-ThrowsContains { $all = Get-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -Name Get-ServiceName;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-StopStartDataMigrationService
{
	$rg = Create-ResourceGroupForTest
	try
	{
		$service = Create-DataMigrationService($rg)
		
		Stop-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name

		$all = Get-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name
		Assert-AreEqual 1 $all.Count
		Assert-AreEqual "Stopped" $all[0].Service.ProvisioningState

		
		Start-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name
		
		$all = Get-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name
		Assert-AreEqual 1 $all.Count
		Assert-AreEqual "Succeeded" $all[0].Service.ProvisioningState
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-CreateAndGetProjectSqlSqlDb
{
	$rg = Create-ResourceGroupForTest
	try
	{
		$service = Create-DataMigrationService($rg)
		
		$project = Create-ProjectSqlSqlDb $rg $service

		
		$all = Get-AzDataMigrationProject -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name

        Write-Host $all

		
		
		Assert-AreEqual $all.Count 1
		
		
		$all = Get-AzDataMigrationProject -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name

		Assert-AreEqual $project.Name $all[0].Name
		Assert-AreEqual SQL $all[0].Project.SourcePlatform
		Assert-AreEqual SQLDB $all[0].Project.TargetPlatform

		
		Assert-ThrowsContains { $all = Get-AzDataMigrationProject -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName Get-ProjectName;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-RemoveService
{
	
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		
		Remove-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -Force
		
		Assert-ThrowsContains { $all = Get-AzDataMigrationService -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-RemoveProject
{
	
	$rg = Create-ResourceGroupForTest

	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		
		Remove-AzDataMigrationProject -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -Force
		
		Assert-ThrowsContains { $all = Get-AzDataMigrationProject -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToSourceSqlServer
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-SourceSqlConnectionInfo
		$userName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$password = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$cred = Get-Creds $userName $password

		$task = New-AzDataMigrationTask -TaskType ConnectToSourceSqlServer -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $connectioninfo -SourceCred $cred

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToTargetSqlDb
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-TargetSqlConnectionInfo
		$userName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_USERNAME") 
		$password = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_PASSWORD") 
		$cred = Get-Creds $userName $password

		$task = New-AzDataMigrationTask -TaskType ConnectToTargetSqlDb -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -TargetConnection $connectioninfo -TargetCred $cred

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-GetUserTableTask
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-SourceSqlConnectionInfo
		$userName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$password = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$cred = Get-Creds $userName $password
		$selectedDbs = @("JasmineTest")

		$task = New-AzDataMigrationTask -TaskType GetUserTablesSql -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $connectioninfo -SourceCred $cred -SelectedDatabase $selectedDbs

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-MigrateSqlSqlDB
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName

		
		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		
		$targetConnectionInfo = New-TargetSqlConnectionInfo
		$targetUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_USERNAME")
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword

		$tableMap = New-Object 'system.collections.generic.dictionary[string,string]'
		$tableMap.Add("dbo.TestTable1", "dbo.TestTable1")
		$tableMap.Add("dbo.TestTable2","dbo.TestTable2")

		$sourceDbName = "MigrateOneTime"
		$targetDbName = "JasmineTest"

		$selectedDbs = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDb -Name $sourceDbName -TargetDatabaseName $targetDbName -TableMap $tableMap
		Assert-AreEqual $sourceDbName $selectedDbs[0].Name
		Assert-AreEqual $targetDbName $selectedDbs[0].TargetDatabaseName
		Assert-AreEqual 2 $selectedDbs[0].TableMap.Count
		Assert-AreEqual true $selectedDbs[0].TableMap.ContainsKey("dbo.TestTable1")
		Assert-AreEqual "dbo.TestTable1" $selectedDbs[0].TableMap["dbo.TestTable1"]

		$migTask = New-AzDmsTask -TaskType MigrateSqlServerSqlDb -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $sourceConnectionInfo -SourceCred $sourceCred -TargetConnection $targetConnectionInfo -TargetCred $targetCred -SelectedDatabase  $selectedDbs

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count		
		Assert-AreEqual $sourceDbName $task.ProjectTask.Properties.Input.SelectedDatabases[0].Name
		Assert-AreEqual $targetDbName $task.ProjectTask.Properties.Input.SelectedDatabases[0].TargetDatabaseName

		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToTargetSqlDbMi
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDbMi $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-TargetSqlMiConnectionInfo
		$userName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_USERNAME")
		$password = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_PASSWORD")
		$cred = Get-Creds $userName $password

		$task = New-AzDataMigrationTask -TaskType ConnectToTargetSqlDbMi -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -TargetConnection $connectioninfo -TargetCred $cred

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-MigrateSqlSqlDBMi
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDbMi $rg $service
		$taskName = Get-TaskName

		
		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		
		$targetConnectionInfo = New-TargetSqlMiConnectionInfo
		$targetUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_USERNAME")
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword
		
		$blobSasUri = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("BLOB_SAS_URI")
		$fileSharePath = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PATH")
		$fileShareUsername = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_USERNAME")
		$fileSharePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PASSWORD")
		$fileShareCred = Get-Creds $fileShareUsername $fileSharePassword

		$backupFileShare = New-AzDmsFileShare -Path $fileSharePath -Credential $fileShareCred
		$sourceDbName = "TestMI"
		$targetDbName = "TestMI6"
        $backupMode = "CreateBackup"

		$selectedDbs = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDbMi -Name $sourceDbName -TargetDatabaseName $targetDbName -BackupFileShare $backupFileShare

		Assert-AreEqual $sourceDbName $selectedDbs[0].Name
		Assert-AreEqual $targetDbName $selectedDbs[0].RestoreDatabaseName

        
        
        

        
        

		$migTask = New-AzDataMigrationTask -TaskType MigrateSqlServerSqlDbMi `
		  -ResourceGroupName $rg.ResourceGroupName `
		  -ServiceName $service.Name `
		  -ProjectName $project.Name `
		  -TaskName $taskName `
		  -TargetConnection $targetConnectionInfo `
		  -TargetCred $targetCred `
		  -SourceConnection $sourceConnectionInfo `
		  -SourceCred $sourceCred `
		  -BackupBlobSasUri $blobSasUri `
		  -BackupFileShare $backupFileShare `
		  -SelectedDatabase $selectedDbs `
          -BackupMode $backupMode

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		
		
		Assert-AreEqual $sourceDbName $task.ProjectTask.Properties.Input.SelectedDatabases[0].Name
		Assert-AreEqual $targetDbName $task.ProjectTask.Properties.Input.SelectedDatabases[0].RestoreDatabaseName

		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ValidateMigrationInputSqlSqlDbMi
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDbMi $rg $service
		$taskName = Get-TaskName

		
		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		
		$targetConnectionInfo = New-TargetSqlMiConnectionInfo
		$targetUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_USERNAME")
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword
		
		$blobSasUri = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("BLOB_SAS_URI")
		$fileSharePath = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PATH")
		$fileShareUsername = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_USERNAME")
		$fileSharePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PASSWORD")
		$fileShareCred = Get-Creds $fileShareUsername $fileSharePassword

		$backupFileShare = New-AzDmsFileShare -Path $fileSharePath -Credential $fileShareCred

		$sourceDbName = "TestMI"
		$targetDbName = "TestTarget"
        $backupMode = "CreateBackup"

		$selectedDbs = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDbMi -Name $sourceDbName -TargetDatabaseName $targetDbName -BackupFileShare $backupFileShare

		$migTask = New-AzDataMigrationTask -TaskType ValidateSqlServerSqlDbMi `
		  -ResourceGroupName $rg.ResourceGroupName `
		  -ServiceName $service.Name `
		  -ProjectName $project.Name `
		  -TaskName $taskName `
		  -SourceConnection $sourceConnectionInfo `
		  -SourceCred $sourceCred `
		  -TargetConnection $targetConnectionInfo `
		  -TargetCred $targetCred `
		  -BackupBlobSasUri $blobSasUri `
		  -BackupFileShare $backupFileShare `
		  -SelectedDatabase $selectedDbs `
          -BackupMode $backupMode

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToSourceSqlServerSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-SourceSqlConnectionInfo
		$userName = "testuser"
		$password = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$cred = Get-Creds $userName $password

		$task = New-AzDataMigrationTask -TaskType ConnectToSourceSqlServerSync -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $connectioninfo -SourceCred $cred

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToTargetSqlDbSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName
		
		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = "testuser"
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		$targetConnectionInfo = New-TargetSqlConnectionInfo
		$targetUserName = "testuser"
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword

		$task = New-AzDataMigrationTask -TaskType ConnectToTargetSqlSync -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $sourceConnectionInfo -SourceCred $sourceCred -TargetConnection $targetConnectionInfo -TargetCred $targetCred

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-GetUserTableSyncTask
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName

		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = "testuser"
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		$targetConnectionInfo = New-TargetSqlConnectionInfo
		$targetUserName = "testuser"
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword

		$selectedSourceDb = @("MigrateOneTime")
		$selectedTargetDb = @("JasmineTest")

		$task = New-AzDataMigrationTask -TaskType GetUserTablesSqlSync `
			-ResourceGroupName $rg.ResourceGroupName `
			-ServiceName $service.Name `
			-ProjectName $project.Name `
			-TaskName $taskName `
			-SourceConnection $sourceConnectionInfo `
			-SourceCred $sourceCred `
			-TargetConnection $targetConnectionInfo `
			-TargetCred $targetCred `
			-SelectedSourceDatabases $selectedSourceDb `
			-SelectedTargetDatabases $selectedTargetDb

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ValidateMigrationInputSqlSqlDbSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName

		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = "testuser"
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		$targetConnectionInfo = New-TargetSqlConnectionInfo
		$targetUserName = "testuser"
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword

		$tableMap = New-Object 'system.collections.generic.dictionary[string,string]'
		$tableMap.Add("dbo.TestTable1", "dbo.TestTable1")
		$tableMap.Add("dbo.TestTable2","dbo.TestTable2")

        $sourceDb = "MigrateOneTime"
        $targetDb = "JasmineTest"

		$selectedDbs = New-AzDmsSyncSelectedDB -TargetDatabaseName $targetDb `
		  -SchemaName dbo `
		  -TableMap $tableMap `
		  -Name $sourceDb

		$migTask = New-AzDataMigrationTask -TaskType ValidateSqlServerSqlDbSync `
		  -ResourceGroupName $rg.ResourceGroupName `
		  -ServiceName $service.Name `
		  -ProjectName $project.Name `
		  -TaskName $taskName `
		  -SourceConnection $sourceConnectionInfo `
		  -SourceCred $sourceCred `
		  -TargetConnection $targetConnectionInfo `
		  -TargetCred $targetCred `
		  -SelectedDatabase  $selectedDbs

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-MigrateSqlSqlDBSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDb $rg $service
		$taskName = Get-TaskName

		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = "testuser"
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		$targetConnectionInfo = New-TargetSqlConnectionInfo
		$targetUserName = "testuser"
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDB_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword

		$tableMap = New-Object 'system.collections.hashtable'
		$tableMap.Add("dbo.TestTable1", "dbo.TestTable1")
		$tableMap.Add("dbo.TestTable2","dbo.TestTable2")

        $sourceDb = "MigrateOneTime"
        $targetDb = "JasmineTest"

		$selectedDbs = New-AzDmsSyncSelectedDB -TargetDatabaseName $targetDb `
		  -SchemaName dbo `
		  -TableMap $tableMap `
		  -SourceDatabaseName $sourceDb

		$migTask = New-AzDmsTask -TaskType MigrateSqlServerSqlDbSync `
			-ResourceGroupName $rg.ResourceGroupName `
			-ServiceName $service.Name `
			-ProjectName $project.Name `
			-TaskName $taskName `
			-SourceConnection $sourceConnectionInfo `
			-SourceCred $sourceCred `
			-TargetConnection $targetConnectionInfo `
			-TargetCred $targetCred `
			-SelectedDatabase  $selectedDbs

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count

		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			Foreach($output in $task.ProjectTask.Properties.Output) {
			    if ($output.Id -clike 'db|*')
			    {
				    Write-Host ($output | Format-List | Out-String)

				    if ($output.MigrationState -eq "READY_TO_COMPLETE")
				    {
					    $command = Invoke-AzDmsCommand -CommandType CompleteSqlDBSync `
						    -ResourceGroupName $rg.ResourceGroupName `
						    -ServiceName $service.Name `
						    -ProjectName $project.Name `
						    -TaskName $taskName `
						    -DatabaseName $output.DatabaseName
				    }
                }
            }

			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToSourceMongoDb
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectMongoDbMongoDb $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-SourceMongoDbConnectionInfo

		$task = New-AzDataMigrationTask -TaskType ConnectToSourceMongoDb -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $connectioninfo -Wait

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}

}

function Test-ConnectToTargetCosmosDb
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectMongoDbMongoDb $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-TargetMongoDbConnectionInfo

		$task = New-AzDataMigrationTask -TaskType ConnectToSourceMongoDb -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $connectioninfo -Wait

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-MigrateMongoDb
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectMongoDbMongoDb $rg $service
		$taskName = Get-TaskName

		$sourceConnectionInfo = New-SourceMongoDbConnectionInfo
		$targetConnectionInfo = New-TargetMongoDbConnectionInfo

		
		
		
		$testColSettingA = New-AzDataMigrationMongoDbCollectionSetting -Name large -RU 1000 -CanDelete -ShardKey "_id"
		$testColSettingB = New-AzDataMigrationMongoDbCollectionSetting -Name many -RU 1000 -CanDelete -ShardKey "_id"
		$testDbSetting = New-AzDataMigrationMongoDbDatabaseSetting -Name test -CollectionSetting @($testColSettingA, $testColSettingB)

		
		
		
		$validationTask = New-AzDmsTask -TaskType ValidateMongoDbMigration -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $sourceConnectionInfo -TargetConnection $targetConnectionInfo  -SelectedDatabase  @($testDbSetting) -Wait
		$taskName = Get-TaskName
		$migTask = New-AzDmsTask -TaskType MigrateMongoDb -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -SourceConnection $sourceConnectionInfo -TargetConnection $targetConnectionInfo  -SelectedDatabase  @($testDbSetting) -MigrationValidation $validationTask -Replication Disabled

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

			if($task.ProjectTask.Properties.State -eq "Running") {
				$res = Invoke-AzDataMigrationCommand  -CommandType CancelMongoDB -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -ObjectName "test.many"
				Assert-AreEqual "Accepted" $res.State
			}
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ConnectToTargetSqlDbMiSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDbMi $rg $service
		$taskName = Get-TaskName
		$connectionInfo = New-TargetSqlMiSyncConnectionInfo
		$userName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_USERNAME")
		$password = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_PASSWORD")
		$cred = Get-Creds $userName $password
		$app = New-AzureActiveDirectoryApp

		$task = New-AzDataMigrationTask -TaskType ConnectToTargetSqlDbMiSync -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -TargetConnection $connectioninfo -TargetCred $cred -AzureActiveDirectoryApp $app

		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State
		
		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-ValidateMigrationInputSqlSqlDbMiSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDbMi $rg $service
		$taskName = Get-TaskName

		
		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		
		$targetConnectionInfo = New-TargetSqlMiSyncConnectionInfo
		$targetUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_USERNAME")
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword
		
		$app = New-AzureActiveDirectoryApp

		$fileSharePath = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PATH")
		$fileShareUsername = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_USERNAME")
		$fileSharePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PASSWORD")
		$fileShareCred = Get-Creds $fileShareUsername $fileSharePassword
		$backupFileShare = New-AzDmsFileShare -Path $fileSharePath -Credential $fileShareCred

		$storageResourceId = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("STORAGE_RESOURCE_ID")

		$sourceDbName = "AdventureWorks"
		$targetDbName = getDmsAssetName AdventureWorks

		$selectedDbs = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDbMi -Name $sourceDbName -TargetDatabaseName $targetDbName -BackupFileShare $backupFileShare

		$migTask = New-AzDataMigrationTask -TaskType ValidateSqlServerSqlDbMiSync `
		  -ResourceGroupName $rg.ResourceGroupName `
		  -ServiceName $service.Name `
		  -ProjectName $project.Name `
		  -TaskName $taskName `
		  -SourceConnection $sourceConnectionInfo `
		  -SourceCred $sourceCred `
		  -TargetConnection $targetConnectionInfo `
		  -TargetCred $targetCred `
		  -BackupFileShare $backupFileShare `
		  -SelectedDatabase $selectedDbs `
		  -AzureActiveDirectoryApp $app `
		  -StorageResourceId $storageResourceId


		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}

function Test-MigrateSqlSqlDbMiSync
{
	$rg = Create-ResourceGroupForTest
	
	try
	{
		$service = Create-DataMigrationService($rg)
		$project = Create-ProjectSqlSqlDbMi $rg $service
		$taskName = Get-TaskName

		
		$sourceConnectionInfo = New-SourceSqlConnectionInfo
		$sourceUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_USERNAME")
		$sourcePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQL_PASSWORD")
		$sourceCred = Get-Creds $sourceUserName $sourcePassword

		
		$targetConnectionInfo = New-TargetSqlMiSyncConnectionInfo
		$targetUserName = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_USERNAME")
		$targetPassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("SQLDBMI_PASSWORD")
		$targetCred = Get-Creds $targetUserName $targetPassword
		
		$app = New-AzureActiveDirectoryApp

		$fileSharePath = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PATH")
		$fileShareUsername = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_USERNAME")
		$fileSharePassword = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("FILESHARE_PASSWORD")
		$fileShareCred = Get-Creds $fileShareUsername $fileSharePassword
		$backupFileShare = New-AzDmsFileShare -Path $fileSharePath -Credential $fileShareCred

		$storageResourceId = [Microsoft.Azure.Commands.DataMigrationConfig]::GetConfigString("STORAGE_RESOURCE_ID")

		$sourceDbName = "AdventureWorks"
		$dbId = "db|"+$sourceDbName
		$targetDbName = getDmsAssetName AdventureWorks

		$selectedDbs = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDbMi -Name $sourceDbName -TargetDatabaseName $targetDbName -BackupFileShare $backupFileShare

		$migTask = New-AzDataMigrationTask -TaskType MigrateSqlServerSqlDbMiSync `
		  -ResourceGroupName $rg.ResourceGroupName `
		  -ServiceName $service.Name `
		  -ProjectName $project.Name `
		  -TaskName $taskName `
		  -SourceConnection $sourceConnectionInfo `
		  -SourceCred $sourceCred `
		  -TargetConnection $targetConnectionInfo `
		  -TargetCred $targetCred `
		  -BackupFileShare $backupFileShare `
		  -SelectedDatabase $selectedDbs `
		  -AzureActiveDirectoryApp $app `
		  -StorageResourceId $storageResourceId


		$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand

		Assert-AreEqual $taskName $task[0].Name
		Assert-AreEqual 1 $task.Count
		
		while(($task.ProjectTask.Properties.State -eq "Running") -or ($task.ProjectTask.Properties.State -eq "Queued"))
		{
			Foreach($output in $task.ProjectTask.Properties.Output)
			{
				if ($output.Id -eq  $dbId)
				{
					if ($output.MigrationState -eq "LOG_FILES_UPLOADING")
					{
						if ($output.FullBackupSetInfo.BackupType -eq "Database")
						{
							if($output.FullBackupSetInfo.IsBackupRestored)
							{
								$command = Invoke-AzDmsCommand -CommandType CompleteSqlMiSync `
								-ResourceGroupName $rg.ResourceGroupName `
								-ServiceName $service.Name `
								-ProjectName $project.Name `
								-TaskName $taskName `
								-DatabaseName $output.SourceDatabaseName
							}
						}
					}
				}
			}

			SleepTask 15
			$task = Get-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand
		}

		Assert-AreEqual "Succeeded" $task.ProjectTask.Properties.State

		Remove-AzDataMigrationTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Force
		
		Assert-ThrowsContains { $all = Get-AzDmsTask -ResourceGroupName $rg.ResourceGroupName -ServiceName $service.Name -ProjectName $project.Name -TaskName $taskName -Expand ;} "NotFound"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}