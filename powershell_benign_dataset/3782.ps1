














function Test-CloudEndpoint
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName

        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Trigger change detection by Name"
        Invoke-AzStorageSyncChangeDetection -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName  $syncGroupName -Name $CloudEndpointName -DirectoryPath "" -AsJob | Wait-Job

        Write-Verbose "Trigger change detection by InputObject"
        Invoke-AzStorageSyncChangeDetection -InputObject $cloudEndpoint -DirectoryPath "" -AsJob | Wait-Job

        Write-Verbose "Trigger change detection by ResourceId"
        Invoke-AzStorageSyncChangeDetection -ResourceId $cloudEndpoint.ResourceId  -DirectoryPath "" -AsJob | Wait-Job

        Write-Verbose "Trigger change detection by ResourceId, with Recursive"
        Invoke-AzStorageSyncChangeDetection -ResourceId $cloudEndpoint.ResourceId  -DirectoryPath "" -Recursive -AsJob | Wait-Job

        Write-Verbose "Trigger change detection by ResourceId, with Path"
        Invoke-AzStorageSyncChangeDetection -ResourceId $cloudEndpoint.ResourceId  -Path "a","b","c" -AsJob | Wait-Job

        Write-Verbose "Get CloudEndpoint by Name"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -CloudEndpointName $cloudEndpointName 

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by ParentObject"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ParentObject $syncGroup -Name $cloudEndpointName -Verbose
        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by ParentResourceId"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ParentResourceId $syncGroup.ResourceId -Name $cloudEndpointName -Verbose
        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Executing Piping Scenarios"
        New-AzStorageSyncCloudEndpoint -ParentObject $syncGroup -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId | Remove-AzStorageSyncCloudEndpoint -Force -AsJob | Wait-Job

        New-AzStorageSyncCloudEndpoint -ParentResourceId $syncGroup.ResourceId -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId | Remove-AzStorageSyncCloudEndpoint -Force -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-NewCloudEndpoint
{
  
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"

        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName

        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetCloudEndpoint
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName

        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by Name"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -CloudEndpointName $cloudEndpointName 

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetCloudEndpoints
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by SyncGroup"
        $cloudEndpoints = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName

        Assert-AreEqual $cloudEndpoints.Length 1
        $cloudEndpoint = $cloudEndpoints[0]

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetCloudEndpointParentObject
{
   
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by ParentObject"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ParentObject $syncGroup -Name $cloudEndpointName -Verbose
        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetCloudEndpointParentResourceId
{
   
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by ParentResourceId"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ParentResourceId $syncGroup.ResourceId -Name $cloudEndpointName -Verbose
        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $StorageAccount.Id $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-RemoveCloudEndpoint
{
     
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Validating CloudEndpoint Properties"
        Assert-AreEqual $cloudEndpointName $cloudEndpoint.CloudEndpointName
        Assert-AreEqual $storageAccountResourceId $cloudEndpoint.StorageAccountResourceId
        Assert-AreEqual $StorageAccountTenantId $cloudEndpoint.StorageAccountTenantId

        Write-Verbose "Get CloudEndpoint by Name"
        $cloudEndpoint = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -CloudEndpointName $cloudEndpointName 

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -SyncGroupName $syncGroupName -Name $cloudEndpointName -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-RemoveCloudEndpointInputObject
{
     
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -InputObject $cloudEndpoint -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}



function Test-RemoveCloudEndpointResourceId
{
     
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $cloudEndpointName = Get-ResourceName("cep")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices")
        $AzureFileShareName = "testfs" 
        $StorageAccountName = Get-ResourceName("sa")
        $StorageAccountTenantId = (Get-AzTenant).Id

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Resource: $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        New-AzStorageAccount -StorageAccountName $StorageAccountName -Location $resourceLocation -ResourceGroupName $resourceGroupName -Type Standard_LRS
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
        Write-Verbose "Resource: $StorageAccountName | Key: $($key[0])" 
                
        $context = Create-StorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key[0].Value
        Write-Verbose "Resource: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"

        $azureFileShareName = Create-StorageShare -Name $AzureFileShareName -Context $context
        $storageAccountResourceId = $storageAccount.Id

        Write-Verbose "Resource: $cloudEndpointName | Loc: $resourceLocation | Type : CloudEndpoint"
        $cloudEndpoint = New-AzStorageSyncCloudEndpoint -ResourceGroupName $syncGroup.ResourceGroupName  -StorageSyncServiceName $syncGroup.StorageSyncServiceName -SyncGroupName $syncGroup.SyncGroupName -Name $cloudEndpointName -StorageAccountResourceId $storageAccountResourceId -AzureFileShareName $azureFileShareName -StorageAccountTenantId $StorageAccountTenantId -Verbose

        Write-Verbose "Removing CloudEndpoint: $cloudEndpointName"
        Remove-AzStorageSyncCloudEndpoint -Force -ResourceId $cloudEndpoint.ResourceId -AsJob | Wait-Job

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job

        if(IsLive)
        {
            Write-Verbose "Removing: $AzureFileShareName | Loc: $resourceLocation | Type : AzureStorageShare"
            Remove-StorageShare -Name $AzureFileShareName -Context $context | Out-Null
        }

        Write-Verbose "Removing $StorageAccountName | Loc: $resourceLocation | Type : StorageAccount"
        Remove-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}