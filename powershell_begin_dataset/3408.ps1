













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
        
        $result = New-AzureRmWebAppBackup -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri -BackupName $backupName 

        
        Assert-AreEqual $backupName $result.BackupName
        Assert-NotNull $result.StorageAccountUrl
    }
    finally
    {
        
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzureRmWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzureRmAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzureRmResourceGroup -Name $rgName -Force
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
        
        $backup = $app | New-AzureRmWebAppBackup -StorageAccountUrl $sasUri -BackupName $backupName

        
        Assert-AreEqual $backupName $backup.BackupName
        Assert-NotNull $backup.StorageAccountUrl

        
        $backup.BackupName = $backupName2
        $backup2 = $backup | New-AzureRmWebAppBackup

        
        Assert-AreEqual $backupName2 $backup2.BackupName
        Assert-NotNull $backup2.StorageAccountUrl
    }
    finally
    {
        
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzureRmWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzureRmAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzureRmResourceGroup -Name $rgName -Force
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

        
        $newBackup = New-AzureRmWebAppBackup -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri -BackupName $backupName

        
        $result = Get-AzureRmWebAppBackup -ResourceGroupName $rgName -Name $wName -BackupId $newBackup.BackupId

        
        Assert-AreEqual $backupName $result.BackupName
        Assert-NotNull $result.StorageAccountUrl
        Assert-NotNull $result.BackupId

        
        $pipeResult = $result | Get-AzureRmWebAppBackup

        Assert-AreEqual $backupName $pipeResult.BackupName
        Assert-AreEqual $result.StorageAccountUrl $pipeResult.StorageAccountUrl 
        Assert-AreEqual $result.BackupId $pipeResult.BackupId
    }
    finally
    {
        
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzureRmWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzureRmAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzureRmResourceGroup -Name $rgName -Force
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
        
        
        $backup = New-AzureRmWebAppBackup -ResourceGroupName $rgName -Name $wName -StorageAccountUrl $sasUri -BackupName $backupName -Databases $dbBackupSetting

        
        $backupList = Get-AzureRmWebAppBackupList -ResourceGroupName $rgName -Name $wName
        $listBackup = $backupList | where {$_.BackupId -eq $backup.BackupId}

        
        Assert-AreEqual 1 $backupList.Count
        Assert-NotNull $listBackup
        Assert-AreEqual $backup.BackupName $listBackup.BackupName

        
        $pipeBackupList = $app | Get-AzureRmWebAppBackupList
        $pipeBackup = $pipeBackupList | where {$_.BackupId -eq $backup.BackupId}

        
        Assert-AreEqual 1 $pipeBackupList.Count
        Assert-NotNull $pipeBackup
        Assert-AreEqual $backup.BackupName $pipeBackup.BackupName
    }
    finally
    {
        
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzureRmWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzureRmAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzureRmResourceGroup -Name $rgName -Force
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

        
        $config = Edit-AzureRmWebAppBackupConfiguration `
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

        
        $getConfig = Get-AzureRmWebAppBackupConfiguration -ResourceGroupName $rgName -Name $wName

        
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
        
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzureRmWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzureRmAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzureRmResourceGroup -Name $rgName -Force
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

        
        $app | Edit-AzureRmWebAppBackupConfiguration `
            -StorageAccountUrl $sasUri -FrequencyInterval $frequencyInterval `
            -FrequencyUnit $frequencyUnit -RetentionPeriodInDays $retentionPeriod `
            -StartTime $startTime -KeepAtLeastOneBackup
        $config = $app | Get-AzureRmWebAppBackupConfiguration

        
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
        $config | Edit-AzureRmWebAppBackupConfiguration
        $pipeConfig = $app | Get-AzureRmWebAppBackupConfiguration

        
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
        
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stoName
        Remove-AzureRmWebApp -ResourceGroupName $rgName -Name $wName -Force
        Remove-AzureRmAppServicePlan -ResourceGroupName $rgName -Name  $whpName -Force
        Remove-AzureRmResourceGroup -Name $rgName -Force
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
    New-AzureRmResourceGroup -Name $resourceGroup -Location $location | Out-Null
    New-AzureRmAppServicePlan -ResourceGroupName $resourceGroup -Name  $hostingPlan -Location  $location -Tier $tier | Out-Null
    $app = New-AzureRmWebApp -ResourceGroupName $resourceGroup -Name $appName -Location $location -AppServicePlan $hostingPlan 
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
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageName -Location $location -Type $storageType | Out-Null
    $stoKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageName).Key1;
    
    $accessDuration = New-Object -TypeName TimeSpan(2,0,0)
    $permissions = [Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions]::Write
    $sasUri = Get-SasUri $storageName $stoKey $stoContainerName $accessDuration $permissions
    return $sasUri
}
