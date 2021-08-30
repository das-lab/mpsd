function Start-MahoutJob {
    
    $ErrorActionPreference = "Stop"

    
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    
    
    

    
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"

    
    $clusterInfo = Get-AzHDInsightCluster -ClusterName $clusterName
    $resourceGroup = $clusterInfo.ResourceGroup
    $storageAccountName = $clusterInfo.DefaultStorageAccount.split('.')[0]
    $container = $clusterInfo.DefaultStorageContainer
    $storageAccountKey = (Get-AzStorageAccountKey `
        -Name $storageAccountName `
    -ResourceGroupName $resourceGroup)[0].Value

    
    $context = New-AzStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

    
    
    $queryString = "!ls /usr/hdp/current/mahout-client"
    $hiveJobDefinition = New-AzHDInsightHiveJobDefinition -Query $queryString
    $hiveJob=Start-AzHDInsightJob -ClusterName $clusterName -JobDefinition $hiveJobDefinition -HttpCredential $creds
    wait-Azhdinsightjob -ClusterName $clusterName -JobId $hiveJob.JobId -HttpCredential $creds > $null
    
    $files=get-Azhdinsightjoboutput -clustername $clusterName -JobId $hiveJob.JobId -DefaultContainer $container -DefaultStorageAccountName $storageAccountName -DefaultStorageAccountKey $storageAccountKey -HttpCredential $creds
    
    $jarFile = $files | select-string "mahout-examples.+job\.jar" | % {$_.Matches.Value}
    
    $jarFile = "file:///usr/hdp/current/mahout-client/$jarFile"

    
    
    
    
    $jobArguments = "-s", "SIMILARITY_COOCCURRENCE", `
                    "--input", "/HdiSamples/HdiSamples/MahoutMovieData/user-ratings.txt",
                    "--output", "/example/out",
                    "--tempDir", "/example/temp"

    
    $jobDefinition = New-AzHDInsightMapReduceJobDefinition `
        -JarFile $jarFile `
        -ClassName "org.apache.mahout.cf.taste.hadoop.item.RecommenderJob" `
        -Arguments $jobArguments

    
    $job = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    
    Write-Host "Wait for the job to complete ..." -ForegroundColor Green
    Wait-AzHDInsightJob `
            -ClusterName $clusterName `
            -JobId $job.JobId `
            -HttpCredential $creds

    
    Write-Host "STDERR"
    Get-AzHDInsightJobOutput `
            -Clustername $clusterName `
            -JobId $job.JobId `
            -HttpCredential $creds `
            -DisplayOutputType StandardError

    
    Get-AzStorageBlobContent `
            -Blob example/out/part-r-00000 `
            -Container $container `
            -Destination output.txt `
            -Context $context
    
    Get-AzStorageBlobContent -blob "HdiSamples/HdiSamples/MahoutMovieData/moviedb.txt" `
            -Container $container `
            -Destination moviedb.txt `
            -Context $context
    Get-AzStorageBlobContent -blob "HdiSamples/HdiSamples/MahoutMovieData/user-ratings.txt" `
            -Container $container `
            -Destination user-ratings.txt `
            -Context $context

}

function Format-MahoutOutput {

    

    Param(
        
        [Parameter(Mandatory = $true)]
        [String]$userId,

        [Parameter(Mandatory = $true)]
        [String]$userDataFile,

        [Parameter(Mandatory = $true)]
        [String]$movieFile,

        [Parameter(Mandatory = $true)]
        [String]$recommendationFile
    )
    
    $movieById = @{}
    foreach($line in Get-Content $movieFile)
    {
        $tokens = $line.Split("|")
        $movieById[$tokens[0]] = $tokens[1]
    }
    
    
    $ratedMovieIds = @{}
    foreach($line in Get-Content $userDataFile)
    {
        $tokens = $line.Split("`t")
        if($tokens[0] -eq $userId)
        {
            
            $ratedMovieIds[$movieById[$tokens[1]]] = $tokens[2]
        }
    }
    
    $recommendations = @{}
    foreach($line in get-content $recommendationFile)
    {
        $tokens = $line.Split("`t")
        if($tokens[0] -eq $userId)
        {
            
            $movieIdAndScores = $tokens[1].TrimStart("[").TrimEnd("]").Split(",")
            foreach($movieIdAndScore in $movieIdAndScores)
            {
                
                $idAndScore = $movieIdAndScore.Split(":")
                $recommendations[$movieById[$idAndScore[0]]] = $idAndScore[1]
            }
            break
        }
    }

    Write-Output "Rated movies" -ForegroundColor Green
    Write-Output "---------------------------" -ForegroundColor Green
    $ratedFormat = @{Expression={$_.Name};Label="Movie";Width=40}, `
                    @{Expression={$_.Value};Label="Rating"}
    $ratedMovieIds | format-table $ratedFormat
    Write-Output "---------------------------" -ForegroundColor Green

    write-Output "Recommended movies" -ForegroundColor Green
    Write-Output "---------------------------" -ForegroundColor Green
    $recommendationFormat = @{Expression={$_.Name};Label="Movie";Width=40}, `
                            @{Expression={$_.Value};Label="Score"}
    $recommendations | format-table $recommendationFormat

}