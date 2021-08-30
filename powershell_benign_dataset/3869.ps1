


















function Test-CreateNewWebAppBackup
{
    $rgName = Get-ResourceGroupName
    $wName = Get-WebsiteName
    $location = Get-Location
    $whpName = Get-WebHostPlanName
    $backupName = Get-BackupName
    $tier = "Standard"
    $stoName = 'sto' + $rgName
    $stoContainerName = 'container' + $rgName
    $stoType = 'Standard_LRS'

    try
    {
        $app = Create-TestWebApp $rgName $location $whpName $tier $wName
        $sasUri = Create-TestStorageAccount $rgName $location $stoName $stoType $stoContainerName
        
        $result = New-AzWebAppBackup -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri -BackupName $backupName 

        
        Assert-AreEqual $backupName $result.BackupName
        Assert-NotNull $result.StorageAccountUrl
    }
    finally
    {
        
        Remove-AzStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzResourceGroup -Name $rgName -Force
    }
}

function Test-CreateNewWebAppBackupPiping
{
    
    $rgName = Get-ResourceGroupName
    $wName = Get-WebsiteName
    $location = Get-Location
    $whpName = Get-WebHostPlanName
    $backupName = Get-BackupName
    $backupName2 = Get-BackupName
    $tier = "Standard"
    $stoName = 'sto' + $rgName
    $stoContainerName = 'container' + $rgName
    $stoType = 'Standard_LRS'

    try
    {
        $app = Create-TestWebApp $rgName $location $whpName $tier $wName
        $sasUri = Create-TestStorageAccount $rgName $location $stoName $stoType $stoContainerName
        
        $backup = $app | New-AzWebAppBackup -StorageAccountUrl $sasUri -BackupName $backupName

        
        Assert-AreEqual $backupName $backup.BackupName
        Assert-NotNull $backup.StorageAccountUrl

		$count = 0
		while (($backup.BackupStatus -like "Created" -or $backup.BackupStatus -like "InProgress") -and $count -le 20)
		{
			Wait-Seconds 30
		    $backup = $backup | Get-AzWebAppBackup
			$count++
		}

        
        $backup.BackupName = $backupName2
        $backup2 = $backup | New-AzWebAppBackup

        
        Assert-AreEqual $backupName2 $backup2.BackupName
        Assert-NotNull $backup2.StorageAccountUrl
    }
    finally
    {
        
        Remove-AzStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzResourceGroup -Name $rgName -Force
    }
}

function Test-GetWebAppBackup
{
    
    $rgName = Get-ResourceGroupName
    $wName = Get-WebsiteName
    $location = Get-Location
    $whpName = Get-WebHostPlanName
    $backupName = Get-BackupName
    $tier = "Standard"
    $stoName = 'sto' + $rgName
    $stoType = 'Standard_LRS'
    $stoContainerName = 'container' + $rgName

    try
    {
        $app = Create-TestWebApp $rgName $location $whpName $tier $wName
        $sasUri = Create-TestStorageAccount $rgName $location $stoName $stoType $stoContainerName

        
        $newBackup = New-AzWebAppBackup -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri -BackupName $backupName

        
        $result = Get-AzWebAppBackup -ResourceGroupName $rgName -Name $wName -BackupId $newBackup.BackupId

        
        Assert-AreEqual $backupName $result.BackupName
        Assert-NotNull $result.StorageAccountUrl
        Assert-NotNull $result.BackupId

        
        $pipeResult = $result | Get-AzWebAppBackup

        Assert-AreEqual $backupName $pipeResult.BackupName
        Assert-AreEqual $result.StorageAccountUrl $pipeResult.StorageAccountUrl 
        Assert-AreEqual $result.BackupId $pipeResult.BackupId
    }
    finally
    {
        
        Remove-AzStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzResourceGroup -Name $rgName -Force
    }
}

function Test-GetWebAppBackupList
{
    
    $rgName = Get-ResourceGroupName
    $wName = Get-WebsiteName
    $location = Get-Location
    $whpName = Get-WebHostPlanName
    $backupName = Get-BackupName
    $tier = "Standard"
    $stoName = 'sto' + $rgName
    $stoType = 'Standard_LRS'
    $stoContainerName = 'container' + $rgName

    try
    {
        $app = Create-TestWebApp $rgName $location $whpName $tier $wName
        $sasUri = Create-TestStorageAccount $rgName $location $stoName $stoType $stoContainerName
        
        
        $backup = New-AzWebAppBackup -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri -BackupName $backupName -Databases $dbBackupSetting

        
        $backupList = Get-AzWebAppBackupList -ResourceGroupName $rgName -Name $wName
        $listBackup = $backupList | where {$_.BackupId -eq $backup.BackupId}

        
        Assert-AreEqual 1 $backupList.Count
        Assert-NotNull $listBackup
        Assert-AreEqual $backup.BackupName $listBackup.BackupName

        
        $pipeBackupList = $app | Get-AzWebAppBackupList
        $pipeBackup = $pipeBackupList | where {$_.BackupId -eq $backup.BackupId}

        
        Assert-AreEqual 1 $pipeBackupList.Count
        Assert-NotNull $pipeBackup
        Assert-AreEqual $backup.BackupName $pipeBackup.BackupName
    }
    finally
    {
        
        Remove-AzStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzResourceGroup -Name $rgName -Force
    }
}

function Test-EditAndGetWebAppBackupConfiguration
{
    
    $rgName = Get-ResourceGroupName
    $wName = Get-WebsiteName
    $location = Get-Location
    $whpName = Get-WebHostPlanName
    $tier = "Standard"
    $stoName = 'sto' + $rgName
    $stoContainerName = 'container' + $rgName
    $stoType = 'Standard_LRS'

    try
    {
        
        $app = Create-TestWebApp $rgName $location $whpName $tier $wName
        $sasUri = Create-TestStorageAccount $rgName $location $stoName $stoType $stoContainerName
        $startTime = (Get-Date).ToUniversalTime().AddDays(1)
        $frequencyInterval = 7
        $frequencyUnit = "Day"
        $retentionPeriod = 3

        
        $config = Edit-AzWebAppBackupConfiguration `
            -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri `
            -FrequencyInterval $frequencyInterval -FrequencyUnit $frequencyUnit `
            -RetentionPeriodInDays $retentionPeriod -StartTime $startTime `
            -KeepAtLeastOneBackup 

        
        Assert-True { $config.Enabled }
        Assert-NotNull $config.StorageAccountUrl
        Assert-AreEqual $frequencyInterval $config.FrequencyInterval
        Assert-AreEqual $frequencyUnit $config.FrequencyUnit 
        Assert-True { $config.KeepAtLeastOneBackup }
        Assert-AreEqual $retentionPeriod $config.RetentionPeriodInDays
        
        Assert-NotNull $config.StartTime

        
        $getConfig = Get-AzWebAppBackupConfiguration -ResourceGroupName $rgName -Name $wName

        
        Assert-True { $getConfig.Enabled }
        Assert-NotNull $getConfig.StorageAccountUrl
        Assert-AreEqual $frequencyInterval $getConfig.FrequencyInterval
        Assert-AreEqual $frequencyUnit $getConfig.FrequencyUnit 
        Assert-True { $getConfig.KeepAtLeastOneBackup }
        Assert-AreEqual $retentionPeriod $getConfig.RetentionPeriodInDays
        
        Assert-NotNull $getConfig.StartTime
    }
    finally
    {
        
        Remove-AzStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzResourceGroup -Name $rgName -Force
    }
}

function Test-EditAndGetWebAppBackupConfigurationPiping
{
    
    $rgName = Get-ResourceGroupName
    $wName = Get-WebsiteName
    $location = Get-Location
    $whpName = Get-WebHostPlanName
    $tier = "Standard"
    $stoName = 'sto' + $rgName
    $stoContainerName = 'container' + $rgName
    $stoType = 'Standard_LRS'

    try
    {
        
        $app = Create-TestWebApp $rgName $location $whpName $tier $wName
        $sasUri = Create-TestStorageAccount $rgName $location $stoName $stoType $stoContainerName
        $startTime = (Get-Date).ToUniversalTime().AddDays(1)
        $frequencyInterval = 7
        $frequencyUnit = "Day"
        $retentionPeriod = 3

        
        $app | Edit-AzWebAppBackupConfiguration `
            -StorageAccountUrl $sasUri -FrequencyInterval $frequencyInterval `
            -FrequencyUnit $frequencyUnit -RetentionPeriodInDays $retentionPeriod `
            -StartTime $startTime -KeepAtLeastOneBackup
        $config = $app | Get-AzWebAppBackupConfiguration

        
        Assert-True { $config.Enabled }
        Assert-NotNull $config.StorageAccountUrl
        Assert-AreEqual $frequencyInterval $config.FrequencyInterval
        Assert-AreEqual $frequencyUnit $config.FrequencyUnit 
        Assert-True { $config.KeepAtLeastOneBackup }
        Assert-AreEqual $retentionPeriod $config.RetentionPeriodInDays
        
        Assert-NotNull $config.StartTime

        
        $newFrequencyInterval = 5
        $newRetentionPeriod = 2
        $newFrequencyUnit = "Hour"
        $config.FrequencyInterval = $newFrequencyInterval
        $config.RetentionPeriodInDays = $newRetentionPeriod
        $config.FrequencyUnit = $newFrequencyUnit
        $config | Edit-AzWebAppBackupConfiguration
        $pipeConfig = $app | Get-AzWebAppBackupConfiguration

        
        Assert-True { $pipeConfig.Enabled }
        Assert-NotNull $pipeConfig.StorageAccountUrl
        Assert-AreEqual $newFrequencyInterval $pipeConfig.FrequencyInterval
        Assert-AreEqual $newFrequencyUnit $pipeConfig.FrequencyUnit 
        Assert-True { $pipeConfig.KeepAtLeastOneBackup }
        Assert-AreEqual $newRetentionPeriod $pipeConfig.RetentionPeriodInDays
        
        Assert-NotNull $pipeConfig.StartTime
    }
    finally
    {
        
        Remove-AzStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzResourceGroup -Name $rgName -Force
    }
}

function Test-GetWebAppSnapshot
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$slotName = "staging"
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Premium"
	$isRecordMode = ((Get-WebsitesTestMode) -ne 'Playback')

	try
	{
		New-AzResourceGroup -Name $rgname -Location $location
		New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		$app = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		New-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName

		
		while ($snap -eq $null)
		{
			$snap = Get-AzWebAppSnapshot $app
			if ($isRecordMode)
			{
				Start-Sleep -Seconds 60
			}
		}

		
		$snapshots = Get-AzWebAppSnapshot -ResourceGroupName $rgname -Name $wname -UseDisasterRecovery
		Assert-True { $snapshots.Length -gt 0 }
		Assert-NotNull $snapshots[0]
		Assert-NotNull $snapshots[0].SnapshotTime
		Assert-AreEqual 'Production' $snapshots[0].Slot

		
		$snapshots = Get-AzWebAppSnapshot $rgname $wname
		Assert-True { $snapshots.Length -gt 0 }
		Assert-NotNull $snapshots[0]
		Assert-NotNull $snapshots[0].SnapshotTime
		Assert-AreEqual 'Production' $snapshots[0].Slot

		
		$snapshots = Get-AzWebAppSnapshot -ResourceGroupName $rgname -Name $wname -Slot $slotName
		Assert-True { $snapshots.Length -gt 0 }
		Assert-NotNull $snapshots[0]
		Assert-NotNull $snapshots[0].SnapshotTime
		Assert-AreEqual $slotName $snapshots[0].Slot

		
		$app = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		$snapshots = $app | Get-AzWebAppSnapshot
		Assert-True { $snapshots.Length -gt 0 }
		Assert-NotNull $snapshots[0]
		Assert-NotNull $snapshots[0].SnapshotTime
		Assert-AreEqual 'Production' $snapshots[0].Slot

	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}

function Test-RestoreWebAppSnapshot
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$slotName = "staging"
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Premium"
	$isRecordMode = ((Get-WebsitesTestMode) -ne 'Playback')

	try
	{
		New-AzResourceGroup -Name $rgname -Location $location
		New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		$app = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		New-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName

		
		while ($snap -eq $null)
		{
			$snap = Get-AzWebAppSnapshot $app
			if ($isRecordMode)
			{
				Start-Sleep -Seconds 60
			}
		}

		
		$snapshot = (Get-AzWebAppSnapshot $rgname $wname)[0]
		Restore-AzWebAppSnapshot -ResourceGroupName $rgname -Name $wname -InputObject $snapshot -Force -RecoverConfiguration

		if ($isRecordMode)
		{
			Start-Sleep -Seconds 600
		}

		
		Restore-AzWebAppSnapshot $rgname $wname $slotName $snapshot -RecoverConfiguration -UseDisasterRecovery -Force

		if ($isRecordMode)
		{
			Start-Sleep -Seconds 600
		}

		
		$job = $snapshot | Restore-AzWebAppSnapshot -Force -AsJob
		$job | Wait-Job

		if ($isRecordMode)
		{
			Start-Sleep -Seconds 600
		}
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}

function Test-GetDeletedWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$slotName = "staging"
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Standard"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		New-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force

		$deletedApp = Get-AzDeletedWebApp -ResourceGroupName $rgname -Name $wname -Slot "Production" -Location $location
		Assert-NotNull $deletedApp
		Assert-AreEqual $rgname $deletedApp.ResourceGroupName
		Assert-AreEqual $wname $deletedApp.Name

		$deletedSlot = Get-AzDeletedWebApp -ResourceGroupName $rgname -Name $wname -Slot $slotName -Location $location
		Assert-NotNull $deletedSlot
		Assert-AreEqual $rgname $deletedSlot.ResourceGroupName
		Assert-AreEqual $wname $deletedSlot.Name
		Assert-AreEqual $slotName $deletedSlot.Slot
	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}

function Test-RestoreDeletedWebAppToExisting
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$slotName = "staging"
	$appWithSlotName = "$wname/$slotName"
	$delName = Get-WebsiteName
	$delSlot = "testslot"
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Premium"
	$isRecordMode = ((Get-WebsitesTestMode) -ne 'Playback')

	try
	{
		New-AzResourceGroup -Name $rgname -Location $location
		New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		New-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName

		
		$tmpApp = New-AzWebApp -ResourceGroupName $rgname -Name $delName -Location $location -AppServicePlan $whpName 
		New-AzWebAppSlot -ResourceGroupName $rgname -Name $delName -Slot $delSlot

		while ($snap -eq $null)
		{
			$snap = Get-AzWebAppSnapshot $tmpApp
			if ($isRecordMode)
			{
				Start-Sleep -Seconds 60
			}
		}

		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $delName -Slot $delSlot -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $delName -Force

		$deletedApp = Get-AzDeletedWebApp -ResourceGroupName $rgname -Name $delName -Slot "Production"

		
		$restoredApp = Restore-AzDeletedWebApp $deletedApp -TargetResourceGroupName $rgname -TargetName $wname -Force
		if ($isRecordMode) 
		{
			
			Start-Sleep -Seconds 900
		}

		
		$restoredSlot = Restore-AzDeletedWebApp -ResourceGroupName $rgname -Name $delName -Slot $delSlot -TargetResourceGroupName $rgname -TargetName $wname -TargetSlot $slotName -Force
		if ($isRecordMode) 
		{
			Start-Sleep -Seconds 900
		}

		Assert-NotNull $restoredApp
		Assert-AreEqual $rgname $restoredApp.ResourceGroup
		Assert-AreEqual $wname $restoredApp.Name

		Assert-NotNull $restoredSlot
		Assert-AreEqual $rgname $restoredSlot.ResourceGroup
		Assert-AreEqual $appWithSlotName $restoredSlot.Name
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotName -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}

function Test-RestoreDeletedWebAppToNew
{
	
	$rgname = Get-ResourceGroupName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Premium"
	$delName = Get-WebsiteName
	$isRecordMode = ((Get-WebsitesTestMode) -ne 'Playback')

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier

		
		$tmpApp = New-AzWebApp -ResourceGroupName $rgname -Name $delName -Location $location -AppServicePlan $whpName 
		while ($snap -eq $null)
		{
			$snap = Get-AzWebAppSnapshot $tmpApp
			if ($isRecordMode)
			{
				Start-Sleep -Seconds 60
			}
		}

		Remove-AzWebApp -ResourceGroupName $rgname -Name $delName -Force
		$deletedApp = Get-AzDeletedWebApp -ResourceGroupName $rgname -Name $delName -Slot "Production"

		
		$job = $deletedApp | Restore-AzDeletedWebApp -TargetResourceGroupName $rgname -TargetAppServicePlanName $whpName -UseDisasterRecovery -Force -AsJob
		$result = $job | Wait-Job
		Assert-AreEqual "Completed" $result.State;

		$restoredApp = $job | Receive-Job
		Assert-NotNull $restoredApp
		Assert-AreEqual $rgname $restoredApp.ResourceGroup
		Assert-AreEqual $delName $restoredApp.Name

		if ($isRecordMode) 
		{
			
			Start-Sleep -Seconds 900
		}
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $delName -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}




function Create-TestWebApp
{
    param (
        [string] $resourceGroup,
        [string] $location,
        [string] $hostingPlan,
        [string] $tier,
        [string] $appName
    )
    New-AzResourceGroup -Name $resourceGroup -Location $location | Out-Null
    New-AzAppServicePlan -ResourceGroupName $resourceGroup -Name  $hostingPlan -Location  $location -Tier $tier | Out-Null
    $app = New-AzWebApp -ResourceGroupName $resourceGroup -Name $appName -Location $location -AppServicePlan $hostingPlan 
    return $app
}


function Create-TestStorageAccount
{
    param (
        [string] $resourceGroup,
        [string] $location,
        [string] $storageName,
        [string] $storageType,
        [string] $stoContainerName
    )
    New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageName -Location $location -Type $storageType | Out-Null
    $stoKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageName).Key1;
    
    $accessDuration = New-Object -TypeName TimeSpan(2,0,0)
    $permissions = [Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions]::Write -bor
		[Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions]::Read -bor
		[Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions]::List -bor
		[Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions]::Delete
    $sasUri = Get-SasUri $storageName $stoKey $stoContainerName $accessDuration $permissions
    return $sasUri
}