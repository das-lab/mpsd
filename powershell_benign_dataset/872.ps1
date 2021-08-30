function Start-PythonExample {
    
    $ErrorActionPreference = "Stop"
    
    
    Connect-AzAccount

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    
    
    $creds=Get-Credential -Message "Enter the login for the cluster" -UserName "admin"
    $clusterInfo = Get-AzHDInsightCluster -ClusterName $clusterName
    $storageInfo = $clusterInfo.DefaultStorageAccount.split('.')
    $defaultStoreageType = $storageInfo[1]
    $defaultStorageName = $storageInfo[0]

    
    $activity="Python MapReduce"
    Write-Progress -Activity $activity -Status "Uploading mapper and reducer..."

    
    switch ($defaultStoreageType)
    {
        "blob" {
            
            $resourceGroup = $clusterInfo.ResourceGroup
            $storageContainer=$clusterInfo.DefaultStorageContainer
            $storageAccountKey=(Get-AzStorageAccountKey `
                -Name $defaultStorageName `
                -ResourceGroupName $resourceGroup)[0].Value
            
            $context = New-AzStorageContext `
                -StorageAccountName $defaultStorageName `
                -StorageAccountKey $storageAccountKey
            
            Set-AzStorageBlobContent `
                -File .\mapper.py `
                -Blob "mapper.py" `
                -Container $storageContainer `
                -Context $context
            
            Set-AzStorageBlobContent `
                -File .\reducer.py `
                -Blob "reducer.py" `
                -Container $storageContainer `
                -Context $context `
        }
        "azuredatalakestore" {
            
            
            $clusterRoot=$clusterInfo.DefaultStorageRootPath
            
            Import-AzDataLakeStoreItem -AccountName $defaultStorageName `
                -Path .\mapper.py `
                -Destination "$clusterRoot/mapper.py" `
                -Force
            Import-AzDataLakeStoreItem -AccountName $defaultStorageName `
                -Path .\reducer.py `
                -Destination "$clusterRoot/reducer.py" `
                -Force
        }
        default {
            Throw "Unknown storage type: $defaultStoreageType"
        }
    }

    
    
    
    
    $jobDefinition = New-AzHDInsightStreamingMapReduceJobDefinition `
        -Files "/mapper.py", "/reducer.py" `
        -Mapper "mapper.py" `
        -Reducer "reducer.py" `
        -InputPath "/example/data/gutenberg/davinci.txt" `
        -OutputPath "/example/wordcountout"

    
    Write-Progress -Activity $activity -Status "Starting the MapReduce job..."
    $job = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    
    Write-Progress -Activity $activity -Status "Waiting for the job to complete..."
    Wait-AzHDInsightJob `
        -JobId $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds

    
    Write-Progress -Activity $activity -Status "Downloading job output..."
    switch ($defaultStoreageType)
    {
        "blob" {
            
            $resourceGroup = $clusterInfo.ResourceGroup
            $storageContainer=$clusterInfo.DefaultStorageContainer
            $storageAccountKey=(Get-AzStorageAccountKey `
                -Name $defaultStorageName `
                -ResourceGroupName $resourceGroup)[0].Value
            
            $context = New-AzStorageContext `
                -StorageAccountName $defaultStorageName `
                -StorageAccountKey $storageAccountKey
            
            Get-AzStorageBlobContent `
                -Container $storageContainer `
                -Blob "example/wordcountout/part-00000" `
                -Context $context `
                -Destination "./output.txt"
            
            Get-Content "./output.txt"
        }
        "azuredatalakestore" {
            
            
            $clusterRoot=$clusterInfo.DefaultStorageRootPath
            
            
            
            $sourcePath=$clusterRoot + "example/wordcountout/part-00000"
            Get-AzDataLakeStoreItemContent -Account $defaultStorageName -Path $sourcePath -Confirm
        }
        default {
            Throw "Unknown storage type: $defaultStoreageType"
        }
        
    }
    
}



function fix-lineending($original_file) {
    
    $text = [IO.File]::ReadAllText($original_file) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($original_file, $text)
}

