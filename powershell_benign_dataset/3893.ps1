














function Test-SnapshotCrud
{
    $currentSub = (Get-AzureRmContext).Subscription	
    $subsid = $currentSub.SubscriptionId

    $resourceGroup = Get-ResourceGroupName
    $accName = Get-ResourceName
    $poolName = Get-ResourceName
    $volName = Get-ResourceName
    $snName1 = Get-ResourceName
    $snName2 = Get-ResourceName
    $gibibyte = 1024 * 1024 * 1024
    $usageThreshold = 100 * $gibibyte
    $doubleUsage = 2 * $usageThreshold
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    $subnetName = "default"
    $standardPoolSize = 4398046511104
    $serviceLevel = "Premium"
    $vnetName = $resourceGroup + "-vnet"

    $subnetId = "/subscriptions/$subsId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnetName"

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation
		
        
        $virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $vnetName -AddressPrefix 10.0.0.0/16
        $delegation = New-AzDelegation -Name "netAppVolumes" -ServiceName "Microsoft.Netapp/volumes"
        Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $virtualNetwork -AddressPrefix "10.0.1.0/24" -Delegation $delegation | Set-AzVirtualNetwork

        
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceLocation

        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName

        $retrievedPool = New-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -PoolSize $standardPoolSize -ServiceLevel $serviceLevel
		
        $retrievedVolume = New-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName -CreationToken $volName -UsageThreshold $usageThreshold -ServiceLevel $serviceLevel -SubnetId $subnetId
        Assert-AreEqual "$accName/$poolName/$volName" $retrievedVolume.Name
        Assert-AreEqual $serviceLevel $retrievedVolume.ServiceLevel

        
        $retrieveSn = New-AzNetAppFilesSnapshot -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName -SnapshotName $snName1 -FileSystemId $retrievedVolume.FileSystemId
        Assert-AreEqual "$accName/$poolName/$volName/$snName1" $retrieveSn.Name
        
        Assert-NotNull $retrieveSn.Created

        
        $retrieveSn = New-AzNetAppFilesSnapshot -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName -SnapshotName $snName2
        Assert-AreEqual "$accName/$poolName/$volName/$snName2" $retrieveSn.Name

        
        $retrievedSnapshot = Get-AzNetAppFilesSnapshot -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName
        Assert-AreEqual "$accName/$poolName/$volName/$snName1" $retrievedSnapshot[0].Name
        Assert-AreEqual "$accName/$poolName/$volName/$snName2" $retrievedSnapshot[1].Name
        Assert-AreEqual 2 $retrievedSnapshot.Length

        
        $retrievedSnapshot = Get-AzNetAppFilesSnapshot -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName -SnapshotName $snName1
        Assert-AreEqual "$accName/$poolName/$volName/$snName1" $retrievedSnapshot.Name
		
        
        $retrievedSnapshotById = Get-AzNetAppFilesSnapshot -ResourceId $retrievedSnapshot.Id
        Assert-AreEqual "$accName/$poolName/$volName/$snName1" $retrievedSnapshotById.Name

        

        
        Remove-AzNetAppFilesSnapshot -ResourceId $retrievedSnapshotById.Id
        Remove-AzNetAppFilesSnapshot -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName -SnapshotName $snName2
        $retrievedSnapshot = Get-AzNetAppFilesSnapshot -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName
        Assert-AreEqual 0 $retrievedSnapshot.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}


function Test-SnapshotPipelines
{
    $currentSub = (Get-AzureRmContext).Subscription	
    $subsid = $currentSub.SubscriptionId

    $resourceGroup = Get-ResourceGroupName
    $accName = Get-ResourceName
    $poolName = Get-ResourceName
    $volName = Get-ResourceName
    $snName1 = Get-ResourceName
    $snName2 = Get-ResourceName
    $gibibyte = 1024 * 1024 * 1024
    $usageThreshold = 100 * $gibibyte
    $doubleUsage = 2 * $usageThreshold
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    $subnetName = "default"
    $poolSize = 4398046511104
    $serviceLevel = "Premium"
    $vnetName = $resourceGroup + "-vnet"

    $subnetId = "/subscriptions/$subsId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnetName"

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation
		
        
        $virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $vnetName -AddressPrefix 10.0.0.0/16
        $delegation = New-AzDelegation -Name "netAppVolumes" -ServiceName "Microsoft.Netapp/volumes"
        Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $virtualNetwork -AddressPrefix "10.0.1.0/24" -Delegation $delegation | Set-AzVirtualNetwork

        
        $retrievedAcc = New-AnfAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName 

        New-AnfPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -Name $poolName -PoolSize $poolSize -ServiceLevel $serviceLevel

        $retrievedVolume = New-AnfVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName -CreationToken $volName -UsageThreshold $usageThreshold -ServiceLevel $serviceLevel -SubnetId $subnetId
        
        
        $retrieveSn = Get-AnfVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName | New-AnfSnapshot -SnapshotName $snName1
        Assert-AreEqual "$accName/$poolName/$volName/$snName1" $retrieveSn.Name
        
        
        Get-AnfSnapshot -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName -Name $snName1 | Remove-AnfSnapshot

        
        $retrievedSnapshot = Get-AnfVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -Name $volName | Get-AnfSnapshot 
        Assert-AreEqual 0 $retrievedSnapshot.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}