function add-pythonfiles {
    
    $ErrorActionPreference = "Stop"

    
    
    $sub = Get-AzSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Connect-AzAccount
    }

    
    $pathToStreamingFile = ".\hiveudf.py"

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"

    $clusterInfo = Get-AzHDInsightCluster -ClusterName $clusterName
    $resourceGroup = $clusterInfo.ResourceGroup
    $storageAccountName=$clusterInfo.DefaultStorageAccount.split('.')[0]
    $container=$clusterInfo.DefaultStorageContainer
    $storageAccountKey=(Get-AzStorageAccountKey `
       -ResourceGroupName $resourceGroup `
       -Name $storageAccountName)[0].Value

    
    $context = New-AzStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

    
    Set-AzStorageBlobContent `
        -File $pathToStreamingFile `
        -Blob "hiveudf.py" `
        -Container $container `
        -Context $context
}

function start-hivejob {
    
    $ErrorActionPreference = "Stop"

    
    
    $sub = Get-AzSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Connect-AzAccount
    }

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"

    $HiveQuery = "add file wasbs:///hiveudf.py;" +
                    "SELECT TRANSFORM (clientid, devicemake, devicemodel) " +
                    "USING 'python hiveudf.py' AS " +
                    "(clientid string, phoneLabel string, phoneHash string) " +
                    "FROM hivesampletable " +
                    "ORDER BY clientid LIMIT 50;"

    
    $jobDefinition = New-AzHDInsightHiveJobDefinition `
        -Query $HiveQuery

    
    $activity="Hive query"

    
    Write-Progress -Activity $activity -Status "Starting query..."

    

    $job = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    
    Write-Progress -Activity $activity -Status "Waiting on query to complete..."

    
    Wait-AzHDInsightJob `
        -JobId $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds

    
    

    
    Write-Progress -Activity $activity -Status "Retrieving output..."

    
    Get-AzHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds
}

function start-pigjob {
    
    $ErrorActionPreference = "Stop"

    
    
    $sub = Get-AzSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Connect-AzAccount
    }

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"


    $PigQuery = "Register wasbs:///pigudf.py using jython as myfuncs;" +
                "LOGS = LOAD 'wasbs:///example/data/sample.log' as (LINE:chararray);" +
                "LOG = FILTER LOGS by LINE is not null;" +
                "DETAILS = foreach LOG generate myfuncs.create_structure(LINE);" +
                "DUMP DETAILS;"

    
    $jobDefinition = New-AzHDInsightPigJobDefinition -Query $PigQuery

    
    $activity="Pig job"

    
    Write-Progress -Activity $activity -Status "Starting job..."


    
    $job = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    
    Write-Progress -Activity $activity -Status "Waiting for the Pig job to complete..."

    
    Wait-AzHDInsightJob `
        -Job $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds

    
    

    
    Write-Progress -Activity $activity "Retrieving output..."

    
    Get-AzHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds
}

function fix-lineending($original_file) {
    
    $text = [IO.File]::ReadAllText($original_file) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($original_file, $text)
}
