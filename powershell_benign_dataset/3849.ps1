
















function Test-File
{        
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    New-TestResourceGroupAndStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

    try{
        $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue

        $localSrcFile = "localsrcfiletestfile.psd1" 
        New-Item $localSrcFile -ItemType File -Force
        $localDestFile = "localdestfiletestfile1.txt"    

        $objectName1 = "filetest1.txt" 
        $objectName2 = "filetest2.txt"  
        $shareName = "filetestshare" 

        
        New-AzStorageShare $shareName -Context $storageContext
        $Share = Get-AzStorageShare -Name $shareName -Context $storageContext
        Assert-AreEqual $Share.Count 1
        Assert-AreEqual $Share[0].Name $shareName

        $t = Set-AzStorageFileContent -source $localSrcFile -ShareName $shareName -Path $objectName1 -Force -Context $storageContext -asjob
		$t | wait-job
		Assert-AreEqual $t.State "Completed"
		Assert-AreEqual $t.Error $null
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 1
        Assert-AreEqual $file[0].Name $objectName1

		if ($Env:OS -eq "Windows_NT")
		{
			Set-AzStorageFileContent -source $localSrcFile -ShareName $shareName -Path $objectName1  -PreserveSMBAttribute -Force -Context $storageContext
		}
		else
		{
			Set-AzStorageFileContent -source $localSrcFile -ShareName $shareName -Path $objectName1 -Force -Context $storageContext
		}
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 1
        Assert-AreEqual $file[0].Name $objectName1
		if ($Env:OS -eq "Windows_NT")
		{
			$file[0].FetchAttributes()
			$localFileProperties = Get-ItemProperty $localSrcFile
			Assert-AreEqual $localFileProperties.CreationTime.ToUniversalTime().Ticks $file[0].Properties.CreationTime.ToUniversalTime().Ticks
			Assert-AreEqual $localFileProperties.LastWriteTime.ToUniversalTime().Ticks $file[0].Properties.LastWriteTime.ToUniversalTime().Ticks
			Assert-AreEqual $localFileProperties.Attributes.ToString() $file[0].Properties.NtfsAttributes.ToString()
		}

        Start-AzStorageFileCopy -SrcShareName $shareName -SrcFilePath $objectName1 -DestShareName $shareName -DestFilePath $objectName2 -Force -Context $storageContext -DestContext $storageContext
        Get-AzStorageFileCopyState -ShareName $shareName -FilePath $objectName2 -Context $storageContext -WaitForComplete
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 2
        Assert-AreEqual $file[0].Name $objectName1
        Assert-AreEqual $file[1].Name $objectName2

        $t = Get-AzStorageFileContent -ShareName $shareName -Path $objectName1 -Destination $localDestFile -Force -Context $storageContext -asjob
		$t | wait-job
		Assert-AreEqual $t.State "Completed"
		Assert-AreEqual $t.Error $null   
        Assert-AreEqual (Get-FileHash -Path $localDestFile -Algorithm MD5).Hash (Get-FileHash -Path $localSrcFile -Algorithm MD5).Hash
				
		if ($Env:OS -eq "Windows_NT")
		{
			Get-AzStorageFileContent -ShareName $shareName -Path $objectName1 -Destination $localDestFile -PreserveSMBAttribute -Force -Context $storageContext
		}
		else
		{
			Get-AzStorageFileContent -ShareName $shareName -Path $objectName1 -Destination $localDestFile -Force -Context $storageContext
		}
        Assert-AreEqual (Get-FileHash -Path $localDestFile -Algorithm MD5).Hash (Get-FileHash -Path $localSrcFile -Algorithm MD5).Hash
		if ($Env:OS -eq "Windows_NT")
		{
			$file = Get-AzStorageFile -ShareName $shareName -Path $objectName1 -Context $storageContext
			$localFileProperties = Get-ItemProperty $localSrcFile
			Assert-AreEqual $localFileProperties.CreationTime.ToUniversalTime().Ticks $file[0].Properties.CreationTime.ToUniversalTime().Ticks
			Assert-AreEqual $localFileProperties.LastWriteTime.ToUniversalTime().Ticks $file[0].Properties.LastWriteTime.ToUniversalTime().Ticks
			Assert-AreEqual $localFileProperties.Attributes.ToString() $file[0].Properties.NtfsAttributes.ToString()
		}

        Remove-AzStorageFile -ShareName $shareName -Path $objectName1 -Context $storageContext
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 1
        Assert-AreEqual $file[0].Name $objectName2

        $dirName = "filetestdir"
        New-AzStorageDirectory -ShareName $shareName -Path $dirName -Context $storageContext    
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 2
        Assert-AreEqual $file[0].Name $objectName2
        Assert-AreEqual $file[0].GetType().Name "CloudFile"
        Assert-AreEqual $file[1].Name $dirName
        Assert-AreEqual $file[1].GetType().Name "CloudFileDirectory"
        Remove-AzStorageDirectory -ShareName $shareName -Path $dirName -Context $storageContext  
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 1
        Assert-AreEqual $file[0].Name $objectName2
        Assert-AreEqual $file[0].GetType().Name "CloudFile"  

        
        Remove-AzStorageShare -Name $shareName -Force -Context $storageContext
    }
    finally
    {
        Clean-ResourceGroup $ResourceGroupName
    }
    
}


function Test-Blob
{
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    New-TestResourceGroupAndStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

    try{

        $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue

        $localSrcFile = "localsrcblobtestfile.psd1" 
        New-Item $localSrcFile -ItemType File -Force
        $localDestFile = "localdestblobtestfile.txt"
        $localDestFile2 = "localdestblobtestfile2.txt"

        $containerName = "blobtestcontainer"          
        $objectName1 = "blobtest1.txt"
        $objectName2 = "blobtest2.txt"
        $ContentType = "image/jpeg"
        $ContentMD5 = "i727sP7HigloQDsqadNLHw=="
        $StandardBlobTier = "Cool"
        $StandardBlobTier2 = "Hot"

        
        New-AzStorageContainer $containerName -Context $storageContext

        
        $t = Set-AzStorageBlobContent -File $localSrcFile -Container $containerName -Blob $objectName1 -StandardBlobTier $StandardBlobTier -Force -Properties @{"ContentType" = $ContentType; "ContentMD5" = $ContentMD5} -Context $storageContext -asjob
        $t | wait-job
        Assert-AreEqual $t.State "Completed"
        Assert-AreEqual $t.Error $null
        $blob = Get-AzStorageContainer -Name $containerName -Context $storageContext | Get-AzStorageBlob
        Assert-AreEqual $blob.Count 1
        Assert-AreEqual $blob.Name $objectName1
        Assert-AreEqual $blob.ICloudBlob.Properties.ContentType $ContentType
        Assert-AreEqual $blob.ICloudBlob.Properties.ContentMD5 $ContentMD5
        Assert-AreEqual $blob.ICloudBlob.Properties.StandardBlobTier $StandardBlobTier
        $blob.ICloudBlob.SetStandardBlobTier($StandardBlobTier2, "High")
        $blob.ICloudBlob.FetchAttributes()
        Assert-AreEqual $blob.ICloudBlob.Properties.StandardBlobTier $StandardBlobTier2
        Set-AzStorageBlobContent -File $localSrcFile -Container $containerName -Blob $objectName2 -Force -Properties @{"ContentType" = $ContentType; "ContentMD5" = $ContentMD5} -Context $storageContext
        $blob = Get-AzStorageContainer -Name $containerName -Context $storageContext | Get-AzStorageBlob
        Assert-AreEqual $blob.Count 2
        Get-AzStorageBlob -Container $containerName -Blob $objectName2 -Context $storageContext | Remove-AzStorageBlob -Force 

        
        Start-AzStorageBlobCopy -srcContainer $containerName -SrcBlob $objectName1 -DestContainer $containerName -DestBlob $objectName2 -StandardBlobTier $StandardBlobTier -RehydratePriority High -Context $storageContext -DestContext $storageContext
        Get-AzStorageBlobCopyState -Container $containerName -Blob $objectName2 -Context $storageContext
        $blob = Get-AzStorageBlob -Container $containerName -Context $storageContext
        Assert-AreEqual $blob.Count 2
        Assert-AreEqual $blob[0].Name $objectName1
        Assert-AreEqual $blob[1].Name $objectName2
        Assert-AreEqual $blob[1].ICloudBlob.Properties.StandardBlobTier $StandardBlobTier

        
        Get-AzStorageBlobContent -Container $containerName -Blob $objectName2 -Destination $localDestFile -Force -Context $storageContext
        Assert-AreEqual (Get-FileHash -Path $localDestFile -Algorithm MD5).Hash (Get-FileHash -Path $localSrcFile -Algorithm MD5).Hash
        $t = Get-AzStorageBlobContent -Container $containerName -Blob $objectName2 -Destination $localDestFile2 -Force -Context $storageContext -asjob
		$t | wait-job
		Assert-AreEqual $t.State "Completed"
		Assert-AreEqual $t.Error $null
        Assert-AreEqual (Get-FileHash -Path $localDestFile2 -Algorithm MD5).Hash (Get-FileHash -Path $localSrcFile -Algorithm MD5).Hash

        Remove-AzStorageBlob -Container $containerName -Blob $objectName2 -Force -Context $storageContext
        $blob = Get-AzStorageBlob -Container $containerName -Context $storageContext
        Assert-AreEqual $blob.Count 1
        Assert-AreEqual $blob[0].Name $objectName1
        
        $pageBlobName1 = "blobpage1"
        $pageBlobName2 = "blobpage2"
        $b = Set-AzStorageBlobContent -File $localSrcFile -Container $containerName -Blob $pageBlobName1 -Force -BlobType page -Context $storageContext
        $task = $b.ICloudBlob.SnapshotAsync() 
		$task.Wait()
		$snapshot = $task.Result  
        $blob = Get-AzStorageBlob -Container $containerName -Context $storageContext | Where-Object {$_.Name -eq $pageBlobName1}
        Assert-AreEqual $blob.Count 2
        Assert-AreEqual $blob[0].ICloudBlob.IsSnapshot $true
        Assert-AreEqual $blob[1].ICloudBlob.IsSnapshot $false

        
        
        Start-AzStorageBlobIncrementalCopy -srcContainer $containerName -SrcBlob $pageBlobName1 -SrcBlobSnapshotTime $snapshot.SnapshotTime -DestContainer $containerName -DestBlob $pageBlobName2 -Context $storageContext -DestContext $storageContext
        Get-AzStorageBlobCopyState -WaitForComplete -Container $containerName -Blob $pageBlobName2 -Context $storageContext
		$blob = Get-AzStorageBlob -Container $containerName -Context $storageContext | Where-Object {$_.Name -eq $pageBlobName2}
        Assert-AreEqual $blob.Count 2
        Assert-AreEqual $blob[0].ICloudBlob.IsSnapshot $true
        Assert-AreEqual $blob[1].ICloudBlob.IsSnapshot $false
		
		
		Set-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $containerName -ImmutabilityPeriod 1		
        Set-AzStorageBlobContent -File $localSrcFile -Container $containerName -Blob immublob -Force -Properties @{"CacheControl" = "max-age=31536000, private"; "ContentEncoding" = "gzip"; "ContentDisposition" = "123"; "ContentLanguage" = "1234"; "ContentType" = "abc/12345"; } -Metadata @{"tag1" = "value1"; "tag2" = "value22" } -Context $storageContext
		
		$immutabilityPolicy = Get-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $containerName
		Remove-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ContainerName $containerName -Etag $immutabilityPolicy.Etag
		
        
        Remove-AzStorageContainer -Name $containerName -Force -Context $storageContext

    }
    finally
    {
        Clean-ResourceGroup $ResourceGroupName
    }
}


function Test-Queue
{
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    New-TestResourceGroupAndStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

    try
    {
        $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue

        $queueName = "queue-test"
        New-AzStorageQueue -Name $queueName -Context $storageContext
        $queue = Get-AzStorageQueue -Name $queueName -Context $storageContext
        Assert-AreEqual $queue.Count 1
        Assert-AreEqual $queue[0].Name $queueName

		$queueMessage = New-Object -TypeName "Microsoft.Azure.Storage.Queue.CloudQueueMessage" -ArgumentList "This is message 1"
        $queue.CloudQueue.AddMessageAsync($QueueMessage)
        
        $queueCount1 = (Get-AzStorageQueue -Context $storageContext).Count
        Remove-AzStorageQueue -Name $queueName -Force -Context $storageContext
        $queue2 = Get-AzStorageQueue -Context $storageContext 
        if ($null -eq $queue2) { 
            $queueCount2 = 0
        }
        else {
            $queueCount2 = $queue2.Count
        }    
        Assert-AreEqual ($queueCount1-$queueCount2) 1
    }
    finally
    {
        Clean-ResourceGroup $ResourceGroupName
    }
}


function Test-Table
{
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    New-TestResourceGroupAndStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

    try
    {
        $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue
		
        
        $tableName = "tabletest"
        New-AzStorageTable -Name $tableName -Context $storageContext
        $table =Get-AzStorageTable -Name $tableName -Context $storageContext
        Assert-AreEqual $table.Count 1
        Assert-AreEqual $table[0].Name $tableName

        
        $partitionKey = "p123"
        $rowKey = "row123"
        $entity = New-Object -TypeName Microsoft.Azure.Cosmos.Table.DynamicTableEntity -ArgumentList $partitionKey, $rowKey
        $entity.Properties.Add("Name", "name1")
        $entity.Properties.Add("ID", 4567)
        $result = $table.CloudTable.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity)) 
        
        
        $tableSASUri = New-AzureStorageTableSASToken -Name $tablename  -Permission "raud" -ExpiryTime (([DateTime]::UtcNow.AddDays(10))) -FullUri -Context $storageContext
        $uri = [System.Uri]$tableSASUri
        $sasTable = New-Object -TypeName Microsoft.Azure.Cosmos.Table.CloudTable $uri 

        
        $query = New-Object Microsoft.Azure.Cosmos.Table.TableQuery
        
        $list = New-Object System.Collections.Generic.List[string]
        $list.Add("RowKey")
        $list.Add("ID")
        $list.Add("Name")
        
        $query.FilterString = "ID gt 0"
        $query.SelectColumns = $list
        $query.TakeCount = 20
        
        $result = $sasTable.ExecuteQuerySegmentedAsync($query, $null) 
        Assert-AreEqual $result.Result.Results.Count 1

        
        $tableCount1 = (Get-AzStorageTable -Context $storageContext).Count
        Remove-AzStorageTable -Name $tableName -Force -Context $storageContext
        $table2 = Get-AzStorageTable -Context $storageContext
        if ($null -eq $table2) { 
        $tableCount2 = 0
        }
        else {
        $tableCount2 = $table2.Count
        }    
        Assert-AreEqual ($tableCount1-$tableCount2) 1
    }
    finally
    {
        Clean-ResourceGroup $ResourceGroupName
    }
}


function Test-BlobFileCopy
{
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    New-TestResourceGroupAndStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

    try
    {
        $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue
    
        $localSrcFile = "localsrcblobfilecopytestfile.psd1" 
        New-Item $localSrcFile -ItemType File -Force     

        $objectName1 = "blobfilecopytest1.txt"
        $objectName2 = "blobfilecopytest2.txt"
        $objectName3 = "blobfilecopytest3.txt"

        
        $ContentType = "image/jpeg"
        $ContentMD5 = "i727sP7HigloQDsqadNLHw=="
        
        $containerName = "blobfilecopytestcontainer"  
        New-AzStorageContainer $containerName -Context $storageContext
        Set-AzStorageBlobContent -File $localSrcFile -Container $containerName -Blob $objectName1 -Force -Properties @{"ContentType" = $ContentType; "ContentMD5" = $ContentMD5} -Context $storageContext
        $blob = Get-AzStorageContainer -Name $containerName -Context $storageContext |Get-AzStorageBlob
        Assert-AreEqual $blob.Count 1
        Assert-AreEqual $blob.Name $objectName1
        Assert-AreEqual $blob.ICloudBlob.Properties.ContentType $ContentType
        Assert-AreEqual $blob.ICloudBlob.Properties.ContentMD5 $ContentMD5           

        $shareName = "blobfilecopytestshare"
        
        New-AzStorageShare $shareName -Context $storageContext
        $Share = Get-AzStorageShare -Name $shareName -Context $storageContext
        Assert-AreEqual $Share.Count 1
        Assert-AreEqual $Share[0].Name $shareName

        Set-AzStorageFileContent -source $localSrcFile -ShareName $shareName -Path $objectName2 -Force -Context $storageContext
        $file = Get-AzStorageFile -ShareName $shareName -Context $storageContext
        Assert-AreEqual $file.Count 1
        Assert-AreEqual $file[0].Name $objectName2

        
        Start-AzStorageBlobCopy  -SrcShareName $shareName -SrcFilePath $objectName2 -DestContainer $containerName -DestBlob $objectName3 -Force -Context $storageContext -DestContext $storageContext
        Get-AzStorageBlobCopyState -Container $containerName -Blob $objectName3 -Context $storageContext    
        $blob = Get-AzStorageBlob -Container $containerName -Blob $objectName3 -Context $storageContext
        Assert-AreEqual $blob.Count 1
        Assert-AreEqual $blob[0].Name $objectName3

        Start-AzStorageFileCopy  -SrcContainerName $containerName -SrcBlobName $objectName1  -DestShareName $shareName -DestFilePath $objectName3 -Force -Context $storageContext -DestContext $storageContext
        Get-AzStorageFileCopyState -ShareName $shareName -FilePath $objectName3 -Context $storageContext    
        $file = Get-AzStorageFile -ShareName $shareName -Path $objectName3 -Context $storageContext
        Assert-AreEqual $file.Count 1
        Assert-AreEqual $file[0].Name $objectName3

        
        Remove-AzStorageShare -Name $shareName -Force -Context $storageContext
        Remove-AzStorageContainer -Name $containerName -Force -Context $storageContext
    }
    finally
    {
        Clean-ResourceGroup $ResourceGroupName
    }
}


function Test-Common
{
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    New-TestResourceGroupAndStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

    try
    {
        $storageAccountKeyValue = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyValue

        
        $retryTimes = 120
        
        
        $version = "1.0"
        $retentionDays = 2
        $LoggingOperations = "All"

        Set-AzStorageServiceLoggingProperty -ServiceType blob -RetentionDays $retentionDays -Version $version -LoggingOperations $LoggingOperations -Context $storageContext
        $i = 0
		$propertyUpdated = $false
		while (($i -lt $retryTimes ) -and ($propertyUpdated -eq $false))
		{
			$property = Get-AzStorageServiceLoggingProperty -ServiceType blob -Context $storageContext
			if (($property.RetentionDays -eq $retentionDays) -and ($property.Version -eq $version) -and ($property.LoggingOperations -eq $LoggingOperations))
			{
				$propertyUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		} 
		$property = Get-AzStorageServiceLoggingProperty -ServiceType blob -Context $storageContext
		Assert-AreEqual $LoggingOperations $property.LoggingOperations.ToString() 
        Assert-AreEqual $version $property.Version 
        Assert-AreEqual $retentionDays $property.RetentionDays  

        $MetricsLevel = "Service"
        Set-AzStorageServiceMetricsProperty -ServiceType blob -Version $version -MetricsType Hour -RetentionDays $retentionDays -MetricsLevel $MetricsLevel -Context $storageContext
        $i = 0
		$propertyUpdated = $false
		while (($i -lt $retryTimes ) -and ($propertyUpdated -eq $false))
		{
			$property = Get-AzStorageServiceMetricsProperty -ServiceType Blob -MetricsType Hour -Context $storageContext
			if (($property.RetentionDays -eq $retentionDays) -and ($property.Version -eq $version) -and ($property.MetricsLevel.ToString()  -eq $MetricsLevel))
			{
				$propertyUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		} 				
		$property = Get-AzStorageServiceMetricsProperty -ServiceType Blob -MetricsType Hour -Context $storageContext
        Assert-AreEqual $MetricsLevel $property.MetricsLevel.ToString() 
        Assert-AreEqual $version $property.Version 
        Assert-AreEqual $retentionDays $property.RetentionDays 

        Set-AzStorageCORSRule -ServiceType blob -Context $storageContext -CorsRules (@{
            AllowedHeaders=@("x-ms-blob-content-type","x-ms-blob-content-disposition");
            AllowedOrigins=@("*");
            MaxAgeInSeconds=30;
            AllowedMethods=@("Get","Connect")},
            @{
            AllowedOrigins=@("http://www.fabrikam.com","http://www.contoso.com"); 
            ExposedHeaders=@("x-ms-meta-data*","x-ms-meta-customheader"); 
            AllowedHeaders=@("x-ms-meta-target*","x-ms-meta-customheader");
            MaxAgeInSeconds=30;
            AllowedMethods=@("Put")})
		$i = 0
		$corsRuleUpdated = $false
		while (($i -lt $retryTimes ) -and ($corsRuleUpdated -eq $false))
		{
			$cors = Get-AzStorageCORSRule -ServiceType blob -Context $storageContext
			if ($cors.Count -eq 2)
			{
				$corsRuleUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		}
        $cors = Get-AzStorageCORSRule -ServiceType blob -Context $storageContext
        Assert-AreEqual 2 $cors.Count 

        Remove-AzStorageCORSRule -ServiceType blob -Context $storageContext
		$i = 0
		$corsRuleUpdated = $false
		while (($i -lt $retryTimes ) -and ($corsRuleUpdated -eq $false))
		{
			$cors = Get-AzStorageCORSRule -ServiceType blob -Context $storageContext
			if ($cors.Count -eq 0)
			{
				$corsRuleUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		}
        $cors = Get-AzStorageCORSRule -ServiceType blob -Context $storageContext
        Assert-AreEqual 0 $cors.Count    
		
        
        $version = "1.0"
        $retentionDays = 3
        $LoggingOperations = "Delete"

        Set-AzStorageServiceLoggingProperty -ServiceType table -RetentionDays $retentionDays -Version $version -LoggingOperations $LoggingOperations -Context $storageContext
        $i = 0
		$propertyUpdated = $false
		while (($i -lt $retryTimes ) -and ($propertyUpdated -eq $false))
		{
			$property = Get-AzStorageServiceLoggingProperty -ServiceType table -Context $storageContext
			if (($property.RetentionDays -eq $retentionDays) -and ($property.Version -eq $version) -and ($property.LoggingOperations -eq $LoggingOperations))
			{
				$propertyUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		} 
		$property = Get-AzStorageServiceLoggingProperty -ServiceType table -Context $storageContext
		Assert-AreEqual $LoggingOperations $property.LoggingOperations.ToString() 
        Assert-AreEqual $version $property.Version 
        Assert-AreEqual $retentionDays $property.RetentionDays  

        $MetricsLevel = "ServiceAndApi"
        Set-AzStorageServiceMetricsProperty -ServiceType table -Version $version -MetricsType Minute -RetentionDays $retentionDays -MetricsLevel $MetricsLevel -Context $storageContext
        $i = 0
		$propertyUpdated = $false
		while (($i -lt $retryTimes ) -and ($propertyUpdated -eq $false))
		{
			$property = Get-AzStorageServiceMetricsProperty -ServiceType table -MetricsType Minute -Context $storageContext
			if (($property.RetentionDays -eq $retentionDays) -and ($property.Version -eq $version) -and ($property.MetricsLevel.ToString()  -eq $MetricsLevel))
			{
				$propertyUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		} 				
		$property = Get-AzStorageServiceMetricsProperty -ServiceType table -MetricsType Minute -Context $storageContext
        Assert-AreEqual $MetricsLevel $property.MetricsLevel.ToString() 
        Assert-AreEqual $version $property.Version 
        Assert-AreEqual $retentionDays $property.RetentionDays 

        Set-AzStorageCORSRule -ServiceType table -Context $storageContext -CorsRules (@{
            AllowedHeaders=@("x-ms-blob-content-type");
            AllowedOrigins=@("*");
            MaxAgeInSeconds=20;
            AllowedMethods=@("Get","Connect")})
		$i = 0
		$corsRuleUpdated = $false
		while (($i -lt $retryTimes ) -and ($corsRuleUpdated -eq $false))
		{
			$cors = Get-AzStorageCORSRule -ServiceType table -Context $storageContext
			if ($cors.Count -eq 1)
			{
				$corsRuleUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		}
        $cors = Get-AzStorageCORSRule -ServiceType table -Context $storageContext
        Assert-AreEqual 1 $cors.Count 

        Remove-AzStorageCORSRule -ServiceType table -Context $storageContext
		$i = 0
		$corsRuleUpdated = $false
		while (($i -lt $retryTimes ) -and ($corsRuleUpdated -eq $false))
		{
			$cors = Get-AzStorageCORSRule -ServiceType table -Context $storageContext
			if ($cors.Count -eq 0)
			{
				$corsRuleUpdated = $true
			}
			else
			{
				sleep 5
				$i = $i + 5
			}
		}
        $cors = Get-AzStorageCORSRule -ServiceType table -Context $storageContext
        Assert-AreEqual 0 $cors.Count   
    }
    finally
    {
        Clean-ResourceGroup $ResourceGroupName
    }    
}

function New-TestResourceGroupAndStorageAccount
{ 
    Param(
        [Parameter(Mandatory = $True)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $True)]
        [string]
        $ResourceGroupName
    ) 

    $location = Get-ProviderLocation ResourceManagement    
    $storageAccountType = 'Standard_LRS'
    New-AzResourceGroup -Name $ResourceGroupName -Location $location
    New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $ResourceGroupName -Location $location -Type $storageAccountType
}
