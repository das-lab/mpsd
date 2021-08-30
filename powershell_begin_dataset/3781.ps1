














function Test-SyncGroup
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
         $storageSyncService = New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Get SyncGroup by Name"
        $syncGroup = Get-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -Verbose
         Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Get SyncGroup by ParentObject"
        $syncGroup = Get-AzStorageSyncGroup -ParentObject $storageSyncService -Name $syncGroupName -Verbose
        Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Get SyncGroup by ParentResourceId"
        $syncGroup = Get-AzStorageSyncGroup -ParentResourceId $storageSyncService.ResourceId -Name $syncGroupName -Verbose
        Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -AsJob | Wait-Job

        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName | Get-AzStorageSyncGroup  | Remove-AzStorageSyncGroup -Force -AsJob | Wait-Job

        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName | Remove-AzStorageSyncGroup -Force -AsJob | Wait-Job

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName -AsJob | Wait-Job
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-NewSyncGroup
{
   
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

         Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetSyncGroup
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Get SyncGroup by Name"
        $syncGroup = Get-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName -Verbose
         Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetSyncGroups
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Get SyncGroup by Name"
        $syncGroups = Get-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Verbose

        Assert-AreEqual $syncGroups.Length 1
        $syncGroup = $syncGroups[0]

         Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetSyncGroupParentObject
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        $storageSyncService = New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Get SyncGroup by ParentObject"
        $syncGroup = Get-AzStorageSyncGroup -ParentObject $storageSyncService -Name $syncGroupName -Verbose
        Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-GetSyncGroupParentResourceId
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        $storageSyncService = New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Get SyncGroup by ParentResourceId"
        $syncGroup = Get-AzStorageSyncGroup -ParentResourceId $storageSyncService.ResourceId -Name $syncGroupName -Verbose
        Write-Verbose "Validating SyncGroup Properties"
        Assert-AreEqual $syncGroupName $syncGroup.SyncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-RemoveSyncGroup
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -Force -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName 

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}


function Test-RemoveSyncGroupInputObject
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -InputObject $syncGroup -Force

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}



function Test-RemoveSyncGroupResourceId
{
    
    $resourceGroupName = Get-ResourceGroupName
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    try
    {
        
        $storageSyncServiceName = Get-ResourceName("sss")
        $syncGroupName = Get-ResourceName("sg")
        $resourceGroupLocation = Get-ResourceGroupLocation
        $resourceLocation = Get-StorageSyncLocation("Microsoft.StorageSync/storageSyncServices");

        Write-Verbose "RGName: $resourceGroupName | Loc: $resourceGroupLocation | Type : ResourceGroup"
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation;

        Write-Verbose "Resource: $storageSyncServiceName | Loc: $resourceLocation | Type : StorageSyncService"
        New-AzStorageSyncService -ResourceGroupName $resourceGroupName -Location $resourceLocation -StorageSyncServiceName $storageSyncServiceName

        Write-Verbose "Resource: $syncGroupName | Loc: $resourceLocation | Type : SyncGroup"
        $syncGroup = New-AzStorageSyncGroup -ResourceGroupName $resourceGroupName -StorageSyncServiceName $storageSyncServiceName -Name $syncGroupName

        Write-Verbose "Removing SyncGroup: $syncGroupName"
        Remove-AzStorageSyncGroup -ResourceId $syncGroup.ResourceId -Force

        Write-Verbose "Removing StorageSyncService: $storageSyncServiceName"
        Remove-AzStorageSyncService -Force -ResourceGroupName $resourceGroupName -Name $storageSyncServiceName
    }
    finally
    {
        
        Write-Verbose "Removing ResourceGroup : $resourceGroupName"
        Clean-ResourceGroup $resourceGroupName
    }
}