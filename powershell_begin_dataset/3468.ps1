
function Test-RedisCache
{
    
    $resourceGroupName = "PowerShellTest-1"
    $cacheName = "redisteam001"
    $location = "West US"

    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Size P1 -Sku Premium

    Assert-AreEqual $cacheName $cacheCreated.Name
    Assert-AreEqual $location $cacheCreated.Location
    Assert-AreEqual "Microsoft.Cache/Redis" $cacheCreated.Type
    Assert-AreEqual $resourceGroupName $cacheCreated.ResourceGroupName

    Assert-AreEqual 6379 $cacheCreated.Port
    Assert-AreEqual 6380 $cacheCreated.SslPort
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    Assert-AreEqual "6GB" $cacheCreated.Size
    Assert-AreEqual "Premium" $cacheCreated.Sku

    Assert-NotNull $cacheCreated.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheCreated.SecondaryKey "SecondaryKey do not exists"

    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            Assert-AreEqual "succeeded" $cacheGet[0].ProvisioningState
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    $cacheUpdated = Set-AzRedisCache -Name $cacheName -RedisConfiguration @{"maxmemory-policy" = "allkeys-lru"} -EnableNonSslPort $true

    Assert-AreEqual $cacheName $cacheUpdated.Name
    Assert-AreEqual 6379 $cacheUpdated.Port
    Assert-AreEqual 6380 $cacheUpdated.SslPort
    Assert-AreEqual "succeeded" $cacheUpdated.ProvisioningState
    Assert-AreEqual "allkeys-lru" $cacheUpdated.RedisConfiguration.Item("maxmemory-policy")
    Assert-True  { $cacheUpdated.EnableNonSslPort }

    Assert-NotNull $cacheUpdated.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheUpdated.SecondaryKey "SecondaryKey do not exists"

    
    $cachesInResourceGroup = Get-AzRedisCache -ResourceGroupName $resourceGroupName
    Assert-True {$cachesInResourceGroup.Count -ge 1}

    $found = 0
    for ($i = 0; $i -lt $cachesInResourceGroup.Count; $i++)
    {
        if ($cachesInResourceGroup[$i].Name -eq $cacheName)
        {
            $found = 1
            Assert-AreEqual $location $cachesInResourceGroup[$i].Location
            Assert-AreEqual $resourceGroupName $cachesInResourceGroup[$i].ResourceGroupName
            break
        }
    }
    Assert-True {$found -eq 1} "Cache created earlier is not found."

    
    $cachesInSubscription = Get-AzRedisCache
    Assert-True {$cachesInSubscription.Count -ge 1}
    Assert-True {$cachesInSubscription.Count -ge $cachesInResourceGroup.Count}

    $found = 0
    for ($i = 0; $i -lt $cachesInSubscription.Count; $i++)
    {
        if ($cachesInSubscription[$i].Name -eq $cacheName)
        {
            $found = 1
            Assert-AreEqual $location $cachesInSubscription[$i].Location
            Assert-AreEqual $resourceGroupName $cachesInSubscription[$i].ResourceGroupName
            break
        }
    }
    Assert-True {$found -eq 1} "Cache created earlier is not found."

    
    $cacheKeysBeforeUpdate = Get-AzRedisCacheKey -ResourceGroupName $resourceGroupName -Name $cacheName
    Assert-NotNull $cacheKeysBeforeUpdate.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheKeysBeforeUpdate.SecondaryKey "SecondaryKey do not exists"

    
    $cacheKeysAfterUpdate = New-AzRedisCacheKey -ResourceGroupName $resourceGroupName -Name $cacheName -KeyType Primary -Force
    Assert-AreEqual $cacheKeysBeforeUpdate.SecondaryKey $cacheKeysAfterUpdate.SecondaryKey
    Assert-AreNotEqual $cacheKeysBeforeUpdate.PrimaryKey $cacheKeysAfterUpdate.PrimaryKey

    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-SetNonExistingRedisCacheTest
{
    
    $resourceGroupName = "PowerShellTestNonExisting"
    $cacheName = "nonexistingrediscache"
    $location = "West US"

    
    Assert-Throws {Set-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -RedisConfiguration @{"maxmemory-policy" = "allkeys-random"} }
}


function Test-RedisCachePipeline
{
    
    $resourceGroupName = "PowerShellTest-2"
    $cacheName = "redisteam002"
    $location = "West US"

    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Size 1GB -Sku Standard -EnableNonSslPort $true

    Assert-AreEqual $cacheName $cacheCreated.Name
    Assert-AreEqual $location $cacheCreated.Location
    Assert-AreEqual "Microsoft.Cache/Redis" $cacheCreated.Type
    Assert-AreEqual $resourceGroupName $cacheCreated.ResourceGroupName

    Assert-AreEqual 6379 $cacheCreated.Port
    Assert-AreEqual 6380 $cacheCreated.SslPort
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    Assert-AreEqual "1GB" $cacheCreated.Size
    Assert-AreEqual "Standard" $cacheCreated.Sku
    Assert-True { $cacheCreated.EnableNonSslPort }

    Assert-NotNull $cacheCreated.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheCreated.SecondaryKey "SecondaryKey do not exists"

    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName | Set-AzRedisCache -RedisConfiguration @{"maxmemory-policy" = "allkeys-random"} -EnableNonSslPort $false
    $cacheUpdatedPiped = Get-AzRedisCache -Name $cacheName

    Assert-AreEqual $cacheName $cacheUpdatedPiped.Name
    Assert-AreEqual $location $cacheUpdatedPiped.Location
    Assert-AreEqual $resourceGroupName $cacheUpdatedPiped.ResourceGroupName
    Assert-AreEqual 6379 $cacheUpdatedPiped.Port
    Assert-AreEqual 6380 $cacheUpdatedPiped.SslPort
    Assert-AreEqual "succeeded" $cacheUpdatedPiped.ProvisioningState
    Assert-AreEqual "1GB" $cacheUpdatedPiped.Size
    Assert-AreEqual "Standard" $cacheUpdatedPiped.Sku
    Assert-AreEqual "allkeys-random"  $cacheUpdatedPiped.RedisConfiguration.Item("maxmemory-policy")
    Assert-False  { $cacheUpdatedPiped.EnableNonSslPort }

    
    $cacheKeysBeforeUpdate = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName | Get-AzRedisCacheKey
    Assert-NotNull $cacheKeysBeforeUpdate.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheKeysBeforeUpdate.SecondaryKey "SecondaryKey do not exists"

    
    $cacheKeysAfterUpdate = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName | New-AzRedisCacheKey -KeyType Primary -Force
    Assert-AreEqual $cacheKeysBeforeUpdate.SecondaryKey $cacheKeysAfterUpdate.SecondaryKey
    Assert-AreNotEqual $cacheKeysBeforeUpdate.PrimaryKey $cacheKeysAfterUpdate.PrimaryKey

    
    Assert-True {Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName | Remove-AzRedisCache -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-RedisCacheClustering
{
    
    $resourceGroupName = "PowerShellTest-3"
    $cacheName = "redisteam003"
    $location = "West US"

    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Size 6GB -Sku Premium -ShardCount 3
    Assert-AreEqual "Microsoft.Cache/Redis" $cacheCreated.Type
    Assert-AreEqual $resourceGroupName $cacheCreated.ResourceGroupName

    Assert-AreEqual 6379 $cacheCreated.Port
    Assert-AreEqual 6380 $cacheCreated.SslPort
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    Assert-AreEqual "6GB" $cacheCreated.Size
    Assert-AreEqual "Premium" $cacheCreated.Sku
    Assert-AreEqual 3 $cacheCreated.ShardCount

    Assert-NotNull $cacheCreated.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheCreated.SecondaryKey "SecondaryKey do not exists"

    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    $cacheUpdated = Set-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -RedisConfiguration @{"maxmemory-policy" = "allkeys-lru"} -TenantSettings @{"some-key" = "some-value"}

    Assert-AreEqual $cacheName $cacheUpdated.Name
    Assert-AreEqual "succeeded" $cacheUpdated.ProvisioningState
    Assert-AreEqual "6GB" $cacheCreated.Size
    Assert-AreEqual "Premium" $cacheCreated.Sku
    Assert-AreEqual 3 $cacheCreated.ShardCount
    Assert-AreEqual "allkeys-lru" $cacheUpdated.RedisConfiguration.Item("maxmemory-policy")
    Assert-AreEqual "some-value" $cacheUpdated.TenantSettings.Item("some-key")

    Assert-NotNull $cacheUpdated.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheUpdated.SecondaryKey "SecondaryKey do not exists"

    
    $cachesInResourceGroup = Get-AzRedisCache -ResourceGroupName $resourceGroupName
    Assert-True {$cachesInResourceGroup.Count -ge 1}

    $found = 0
    for ($i = 0; $i -lt $cachesInResourceGroup.Count; $i++)
    {
        if ($cachesInResourceGroup[$i].Name -eq $cacheName)
        {
            $found = 1
            Assert-AreEqual $location $cachesInResourceGroup[$i].Location
            Assert-AreEqual $resourceGroupName $cachesInResourceGroup[$i].ResourceGroupName
            Assert-AreEqual "succeeded" $cachesInResourceGroup[$i].ProvisioningState
            Assert-AreEqual "6GB" $cacheCreated.Size
            Assert-AreEqual "Premium" $cacheCreated.Sku
            Assert-AreEqual 3 $cacheCreated.ShardCount
            break
        }
    }
    Assert-True {$found -eq 1} "Cache created earlier is not found."

    
    $cachesInSubscription = Get-AzRedisCache
    Assert-True {$cachesInSubscription.Count -ge 1}
    Assert-True {$cachesInSubscription.Count -ge $cachesInResourceGroup.Count}

    $found = 0
    for ($i = 0; $i -lt $cachesInSubscription.Count; $i++)
    {
        if ($cachesInSubscription[$i].Name -eq $cacheName)
        {
            $found = 1
            Assert-AreEqual $location $cachesInSubscription[$i].Location
            Assert-AreEqual $resourceGroupName $cachesInSubscription[$i].ResourceGroupName
            Assert-AreEqual "succeeded" $cachesInSubscription[$i].ProvisioningState
            Assert-AreEqual "6GB" $cacheCreated.Size
            Assert-AreEqual "Premium" $cacheCreated.Sku
            Assert-AreEqual 3 $cacheCreated.ShardCount
            break
        }
    }
    Assert-True {$found -eq 1} "Cache created earlier is not found."

    
    $cacheKeysBeforeUpdate = Get-AzRedisCacheKey -ResourceGroupName $resourceGroupName -Name $cacheName
    Assert-NotNull $cacheKeysBeforeUpdate.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheKeysBeforeUpdate.SecondaryKey "SecondaryKey do not exists"

    
    $cacheKeysAfterUpdate = New-AzRedisCacheKey -ResourceGroupName $resourceGroupName -Name $cacheName -KeyType Primary -Force
    Assert-AreEqual $cacheKeysBeforeUpdate.SecondaryKey $cacheKeysAfterUpdate.SecondaryKey
    Assert-AreNotEqual $cacheKeysBeforeUpdate.PrimaryKey $cacheKeysAfterUpdate.PrimaryKey

    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-RedisCachePatchSchedules
{
    
    $resourceGroupName = "PowerShellTest-4"
    $cacheName = "redisteam004"
    $location = "West US"

    
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Sku Premium -Size P1
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    $weekend = New-AzRedisCacheScheduleEntry -DayOfWeek "Weekend" -StartHourUtc 2 -MaintenanceWindow "06:00:00"
    $thursday = New-AzRedisCacheScheduleEntry -DayOfWeek "Thursday" -StartHourUtc 10 -MaintenanceWindow "09:00:00"

    $createResult = New-AzRedisCachePatchSchedule -ResourceGroupName $resourceGroupName -Name $cacheName -Entries @($weekend, $thursday)
    Assert-True {$createResult.Count -eq 3}
    foreach ($scheduleEntry in $createResult)
    {
        if($scheduleEntry.DayOfWeek -eq "Thursday")
        {
            Assert-AreEqual 10 $scheduleEntry.StartHourUtc
            Assert-AreEqual "09:00:00" $scheduleEntry.MaintenanceWindow
        }
        elseif($scheduleEntry.DayOfWeek -eq "Saturday" -or $scheduleEntry.DayOfWeek -eq "Sunday")
        {
            Assert-AreEqual 2 $scheduleEntry.StartHourUtc
            Assert-AreEqual "06:00:00" $scheduleEntry.MaintenanceWindow
        }
        else
        {
            Assert-True $false "Unknown DayOfWeek."
        }
    }

    $getResult = Get-AzRedisCachePatchSchedule -ResourceGroupName $resourceGroupName -Name $cacheName
    Assert-True {$getResult.Count -eq 3}
    foreach ($scheduleEntry in $getResult)
    {
        if($scheduleEntry.DayOfWeek -eq "Thursday")
        {
            Assert-AreEqual 10 $scheduleEntry.StartHourUtc
            Assert-AreEqual "09:00:00" $scheduleEntry.MaintenanceWindow
        }
        elseif($scheduleEntry.DayOfWeek -eq "Saturday" -or $scheduleEntry.DayOfWeek -eq "Sunday")
        {
            Assert-AreEqual 2 $scheduleEntry.StartHourUtc
            Assert-AreEqual "06:00:00" $scheduleEntry.MaintenanceWindow
        }
        else
        {
            Assert-True $false "Unknown DayOfWeek."
        }
    }

    Remove-AzRedisCachePatchSchedule -ResourceGroupName $resourceGroupName -Name $cacheName

    Assert-ThrowsContains {Get-AzRedisCachePatchSchedule -ResourceGroupName $resourceGroupName -Name $cacheName} "There are no patch schedules found for redis cache"

    
    $cacheUpdated = Set-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -EnableNonSslPort $true
    Assert-True  { $cacheUpdated.EnableNonSslPort }

    $cacheUpdated2 = Set-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -RedisConfiguration @{"maxmemory-policy" = "allkeys-lru"}
    Assert-AreEqual "allkeys-lru" $cacheUpdated2.RedisConfiguration.Item("maxmemory-policy")
    Assert-True  { $cacheUpdated2.EnableNonSslPort }

    
    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}

function Create-StorageAccount($resourceGroupName,$storageName,$location)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -Location $location -Type "Standard_LRS"
    }
}

function Get-SasForContainer
{
    param
    (
    $resourceGroupName,
    $storageName,
    $storageContainerName,
    [ref] $sasKeyForContainer
    )
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        
        $storageAccountContext = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName).Value[0]

        
        New-AzStorageContainer -Name $storageContainerName -Context $storageAccountContext

        
        $sasKeyForContainer.Value = New-AzStorageContainerSASToken -Name $storageContainerName -Permission "rwdl" -StartTime ([System.DateTime]::Now).AddMinutes(-20) -ExpiryTime ([System.DateTime]::Now).AddHours(2) -Context $storageAccountContext -FullUri
    }
    else
    {
        $sasKeyForContainer.Value = "dummysasforcontainer"
    }
}

function Get-SasForBlob
{
    param
    (
    $resourceGroupName,
    $storageName,
    $storageContainerName,
    $prefix,
    [ref] $sasKeyForBlob
    )
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        
        $storageAccountContext = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName).Value[0]

        
        $sasKeyForBlob.Value = New-AzStorageBlobSASToken -Container $storageContainerName -Blob $prefix -Permission "rwdl" -StartTime ([System.DateTime]::Now).AddMinutes(-20) -ExpiryTime ([System.DateTime]::Now).AddHours(2) -Context $storageAccountContext -FullUri
    }
    else
    {
        $sasKeyForBlob.Value = "dummysasforblob"
    }
}


function Test-ImportExportReboot
{
    
    $resourceGroupName = "PowerShellTest-5"
    $cacheName = "redisteam005"
    $location = "West US"
    $storageName = "redisteam005s"
    $storageContainerName = "exportimport"
    $prefix = "sunny"

    
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    Create-StorageAccount $resourceGroupName $storageName $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Sku Premium -Size P1
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    
    $sasKeyForContainer = ""
    Get-SasForContainer $resourceGroupName $storageName $storageContainerName ([ref]$sasKeyForContainer)

    
    Export-AzRedisCache -Name $cacheName -Prefix $prefix -Container $sasKeyForContainer

    
    $sasKeyForBlob = ""
    Get-SasForBlob $resourceGroupName $storageName $storageContainerName $prefix ([ref]$sasKeyForBlob)

    
    Import-AzRedisCache -Name $cacheName -Files @($sasKeyForBlob) -Force

    
    $rebootType = "PrimaryNode"
    Reset-AzRedisCache -Name $cacheName -RebootType $rebootType -Force
    Start-TestSleep 120000

    
    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-DiagnosticOperations
{
    
    $resourceGroupName = "PowerShellTest-6"
    $cacheName = "redisteam006"
    $location = "West US"
    $storageName = "redisteam006s"

    
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -Location $location -Type "Standard_LRS"
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Sku Premium -Size P1
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    
    Assert-NotNull $storageAccount.Id "Storage Id cannot be null"
    Set-AzRedisCacheDiagnostics -ResourceGroupName $resourceGroupName -Name $cacheName -StorageAccountId $storageAccount.Id

    
    Remove-AzRedisCacheDiagnostics -ResourceGroupName $resourceGroupName -Name $cacheName

    
    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-GeoReplication
{
    
    $resourceGroupName = "PowerShellTest-7"
    $cacheName1 = "redisteam0071"
    $cacheName2 = "redisteam0072"
    $location1 = "West US"
    $location2 = "East US"

    
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location1

    
    $cacheCreated1 = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName1 -Location $location1 -Sku Premium -Size P1
    $cacheCreated2 = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName2 -Location $location2 -Sku Premium -Size P1

    Assert-AreEqual "creating" $cacheCreated1.ProvisioningState
    Assert-AreEqual "creating" $cacheCreated2.ProvisioningState

    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName
        if (([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0) -and ([string]::Compare("succeeded", $cacheGet[1].ProvisioningState, $True) -eq 0))
        {
            break
        }
        Assert-False {$i -eq 60} "Caches are not in succeeded state even after 30 min."
    }

    
    $linkCreated = New-AzRedisCacheLink -PrimaryServerName $cacheName1 -SecondaryServerName $cacheName2
    Assert-AreEqual "creating" $linkCreated.ProvisioningState
    Assert-AreEqual $cacheName1 $linkCreated.PrimaryServerName
    Assert-AreEqual $cacheName2 $linkCreated.SecondaryServerName

    
    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $linkGet = Get-AzRedisCacheLink -PrimaryServerName $cacheName1 -SecondaryServerName $cacheName2
        if ([string]::Compare("succeeded", $linkGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName1 $linkGet[0].PrimaryServerName
            Assert-AreEqual $cacheName2 $linkGet[0].SecondaryServerName
            break
        }
        Assert-False {$i -eq 60} "Geo replication link is not in succeeded state even after 30 min."
    }

    
    $linkGet = Get-AzRedisCacheLink -Name $cacheName1
    Assert-AreEqual $cacheName1 $linkGet[0].PrimaryServerName
    Assert-AreEqual $cacheName2 $linkGet[0].SecondaryServerName
    $linkGet = Get-AzRedisCacheLink -Name $cacheName2
    Assert-AreEqual $cacheName1 $linkGet[0].PrimaryServerName
    Assert-AreEqual $cacheName2 $linkGet[0].SecondaryServerName

    
    $linkGet = Get-AzRedisCacheLink -PrimaryServerName $cacheName1
    Assert-AreEqual $cacheName1 $linkGet[0].PrimaryServerName
    Assert-AreEqual $cacheName2 $linkGet[0].SecondaryServerName
    $linkGet = Get-AzRedisCacheLink -PrimaryServerName $cacheName2
    Assert-True {$linkGet.Count -eq 0}

    
    $linkGet = Get-AzRedisCacheLink -SecondaryServerName $cacheName2
    Assert-AreEqual $cacheName1 $linkGet[0].PrimaryServerName
    Assert-AreEqual $cacheName2 $linkGet[0].SecondaryServerName
    $linkGet = Get-AzRedisCacheLink -SecondaryServerName $cacheName1
    Assert-True {$linkGet.Count -eq 0}

    
    Assert-True {Remove-AzRedisCacheLink -PrimaryServerName $cacheName1 -SecondaryServerName $cacheName2 -PassThru} "Removing geo replication link failed."

    
    for ($i = 0; $i -le 10; $i++)
    {
        Start-TestSleep 30000
        $linkGet1 = Get-AzRedisCacheLink -PrimaryServerName $cacheName1
        $linkGet2 = Get-AzRedisCacheLink -SecondaryServerName $cacheName2
        if (($linkGet1.Count -eq 0) -and ($linkGet2.Count -eq 0))
        {
            
            break
        }
        Assert-False {$i -eq 10} "Geo replication link deletion is not in succeeded state even after 30 min."
    }

    
    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName1 -Force -PassThru} "Remove cache failed."
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName2 -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-FirewallRule
{
    
    $resourceGroupName = "PowerShellTest-8"
    $cacheName = "redisteam008"
    $location = "West US"
    $rule1 = "ruleone"
    $rule1StartIp = "10.0.0.0"
    $rule1EndIp = "10.0.0.32"
    $rule2 = "ruletwo"
    $rule2StartIp = "10.0.0.64"
    $rule2EndIp = "10.0.0.128"
    $rule3 = "rulethree"
    $rule3StartIp = "10.0.0.33"
    $rule3EndIp = "10.0.0.63"

    
    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Sku Premium -Size P1
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState

    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    
    $rule1Created = New-AzRedisCacheFirewallRule -Name $cacheName -RuleName $rule1 -StartIP $rule1StartIp -EndIP $rule1EndIp
    Assert-AreEqual $rule1StartIp $rule1Created.StartIP
    Assert-AreEqual $rule1EndIp $rule1Created.EndIP
    Assert-AreEqual $rule1 $rule1Created.RuleName

    
    $rule2Created = Get-AzRedisCache -Name $cacheName | New-AzRedisCacheFirewallRule -RuleName $rule2 -StartIP $rule2StartIp -EndIP $rule2EndIp
    Assert-AreEqual $rule2StartIp $rule2Created.StartIP
    Assert-AreEqual $rule2EndIp $rule2Created.EndIP
    Assert-AreEqual $rule2 $rule2Created.RuleName

    
    $rule3Created = New-AzRedisCacheFirewallRule -ResourceId $cacheCreated.Id -RuleName $rule3 -StartIP $rule3StartIp -EndIP $rule3EndIp
    Assert-AreEqual $rule3StartIp $rule3Created.StartIP
    Assert-AreEqual $rule3EndIp $rule3Created.EndIP
    Assert-AreEqual $rule3 $rule3Created.RuleName

    
    
    $rule1Get = Get-AzRedisCacheFirewallRule -Name $cacheName -RuleName $rule1
    Assert-AreEqual $rule1StartIp $rule1Get.StartIP
    Assert-AreEqual $rule1EndIp $rule1Get.EndIP
    Assert-AreEqual $rule1 $rule1Get.RuleName

    
    $allRulesGet = Get-AzRedisCacheFirewallRule -Name $cacheName
    for ($i = 0; $i -le 2; $i++)
    {
        if($allRulesGet[$i].RuleName -eq $rule1)
        {
            Assert-AreEqual $rule1StartIp $allRulesGet[$i].StartIP
            Assert-AreEqual $rule1EndIp $allRulesGet[$i].EndIP
        }
        elseif($allRulesGet[$i].RuleName -eq $rule2)
        {
            Assert-AreEqual $rule2StartIp $allRulesGet[$i].StartIP
            Assert-AreEqual $rule2EndIp $allRulesGet[$i].EndIP
        }
        elseif($allRulesGet[$i].RuleName -eq $rule3)
        {
            Assert-AreEqual $rule3StartIp $allRulesGet[$i].StartIP
            Assert-AreEqual $rule3EndIp $allRulesGet[$i].EndIP
        }
        else
        {
            Assert-False $True "unknown firewall rule"
        }
    }
    
    Assert-True {Remove-AzRedisCacheFirewallRule -Name $cacheName -RuleName $rule1 -PassThru} "Removing firewall rule 'ruleone' failed."

    
    $allRulesGet = Get-AzRedisCacheFirewallRule -Name $cacheName
    Assert-AreEqual 2 $allRulesGet.Count

    
    Get-AzRedisCacheFirewallRule -Name $cacheName | Remove-AzRedisCacheFirewallRule -PassThru

    
    $allRulesGet = Get-AzRedisCacheFirewallRule -Name $cacheName
    Assert-AreEqual 0 $allRulesGet.Count

    
    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}


function Test-Zones
{
    
    $resourceGroupName = "PowerShellTest-9"
    $cacheName = "redisteam009"
    $location = "East US 2"

    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    
    $cacheCreated = New-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Location $location -Size P1 -Sku Premium -Zone @("1") -Tag @{"example-key" = "example-value"}

    Assert-AreEqual $cacheName $cacheCreated.Name
    Assert-AreEqual $location $cacheCreated.Location
    Assert-AreEqual $resourceGroupName $cacheCreated.ResourceGroupName
    Assert-AreEqual "creating" $cacheCreated.ProvisioningState
    Assert-AreEqual "6GB" $cacheCreated.Size
    Assert-AreEqual "Premium" $cacheCreated.Sku
    Assert-AreEqual "1" $cacheCreated.Zone[0]
    Assert-AreEqual "example-value" $cacheCreated.Tag.Item("example-key")
    Assert-NotNull $cacheCreated.PrimaryKey "PrimaryKey do not exists"
    Assert-NotNull $cacheCreated.SecondaryKey "SecondaryKey do not exists"

    
    for ($i = 0; $i -le 60; $i++)
    {
        Start-TestSleep 30000
        $cacheGet = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {
            Assert-AreEqual $cacheName $cacheGet[0].Name
            Assert-AreEqual "1" $cacheGet[0].Zone[0]
            Assert-AreEqual "example-value" $cacheGet[0].Tag.Item("example-key")
            break
        }
        Assert-False {$i -eq 60} "Cache is not in succeeded state even after 30 min."
    }

    
    Assert-True {Remove-AzRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName -Force -PassThru} "Remove cache failed."

    
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}



function Start-TestSleep($milliseconds)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        Start-Sleep -Milliseconds $milliseconds
    }
}