function Start-MapReduce {
    
    $ErrorActionPreference = "Stop"
    
    
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -Message "Enter the login for the cluster"

    
    $outputPath="/example/wordcountoutput"

    
    $activity="C
    Write-Progress -Activity $activity -Status "Getting cluster information..."
    
    $clusterInfo = Get-AzHDInsightCluster -ClusterName $clusterName
    $resourceGroup = $clusterInfo.ResourceGroup
    $storageActArr=$clusterInfo.DefaultStorageAccount.split('.')
    $storageAccountName=$storageActArr[0]
    $storageType=$storageActArr[1]
    
    
    
    
    
    $jobDef=New-AzHDInsightStreamingMapReduceJobDefinition `
        -Files "/mapper.exe","/reducer.exe" `
        -Mapper "mapper.exe" `
        -Reducer "reducer.exe" `
        -InputPath "/example/data/gutenberg/davinci.txt" `
        -OutputPath $outputPath

    
    Write-Progress -Activity $activity -Status "Starting MapReduce job..."
    $job=Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDef `
        -HttpCredential $creds

    
    Write-Progress -Activity $activity -Status "Waiting for the job to complete..."
    Wait-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds

    Write-Progress -Activity $activity -Completed

    
    if($storageType -eq 'azuredatalakestore') {
        
        
        $filePath=$clusterInfo.DefaultStorageRootPath + $outputPath + "/part-00000"
        Export-AzDataLakeStoreItem `
            -Account $storageAccountName `
            -Path $filePath `
            -Destination output.txt
    } else {
        
        
        $container=$clusterInfo.DefaultStorageContainer
        
        
        
        $storageAccountKey=(Get-AzStorageAccountKey `
            -Name $storageAccountName `
        -ResourceGroupName $resourceGroup)[0].Value

        
        $context = New-AzStorageContext `
            -StorageAccountName $storageAccountName `
            -StorageAccountKey $storageAccountKey
        
        Get-AzStorageBlobContent `
            -Blob 'example/wordcountoutput/part-00000' `
            -Container $container `
            -Destination output.txt `
            -Context $context
    }
}