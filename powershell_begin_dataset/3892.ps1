














function Test-PoolCrud
{
    $resourceGroup = Get-ResourceGroupName
    $accName = Get-ResourceName
    $poolName1 = Get-ResourceName 
    $poolName2 = Get-ResourceName 
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    $poolSize = 4398046511104
    $serviceLevel = "Premium"
    
    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName 
	    
        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedPool = New-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName1 -PoolSize $poolSize -ServiceLevel $serviceLevel -Tag @{$newTagName = $newTagValue}
        Assert-AreEqual "$accName/$poolName1" $retrievedPool.Name
        Assert-AreEqual $serviceLevel $retrievedPool.ServiceLevel
        Assert-AreEqual True $retrievedPool.Tags.ContainsKey($newTagName)
        Assert-AreEqual "tagValue1" $retrievedPool.Tags[$newTagName].ToString()

        
        $retrievedPool = New-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName2 -PoolSize $poolSize -ServiceLevel $serviceLevel -Confirm:$false
        Assert-AreEqual "$accName/$poolName2" $retrievedPool.Name
		
        
        $retrievedPool = New-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName2 -PoolSize $poolSize -ServiceLevel $serviceLevel -WhatIf

        
        $retrievedPool = Get-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName
        
        Assert-True {"$accName/$poolName1" -eq $retrievedPool[0].Name -or "$accName/$poolName2" -eq $retrievedPool[0].Name}
        Assert-True {"$accName/$poolName1" -eq $retrievedPool[1].Name -or "$accName/$poolName2" -eq $retrievedPool[1].Name}
        Assert-AreEqual 2 $retrievedPool.Length

        
        $retrievedPool = Get-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName1
        Assert-AreEqual "$accName/$poolName1" $retrievedPool.Name

        
        $retrievedPoolById = Get-AzNetAppFilesPool -ResourceId $retrievedPool.Id
        Assert-AreEqual "$accName/$poolName1" $retrievedPoolById.Name

        
        
        $retrievedPool = Update-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName1 -ServiceLevel "Standard"
        Assert-AreEqual "$accName/$poolName1" $retrievedPool.Name
        Assert-AreEqual "Standard" $retrievedPool.ServiceLevel

        
        $retrievedPool = Update-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName1
        Assert-AreEqual "$accName/$poolName1" $retrievedPool.Name
        Assert-AreEqual "Standard" $retrievedPool.ServiceLevel

        
        Remove-AzNetAppFilesPool -ResourceId $retrievedPoolById.Id

        
        Remove-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName2 -WhatIf
        $retrievedPool = Get-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName
        Assert-AreEqual 1 $retrievedPool.Length

        Remove-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName2
        $retrievedPool = Get-AzNetAppFilesPool -ResourceGroupName $resourceGroup -AccountName $accName
        Assert-AreEqual 0 $retrievedPool.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}



function Test-PoolPipelines
{
    $resourceGroup = Get-ResourceGroupName
    $accName = Get-ResourceName
    $poolName1 = Get-ResourceName
    $poolName2 = Get-ResourceName
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    $poolSize = 4398046511104
    $serviceLevel = "Premium"
    
    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation

        
        New-AnfAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $accName | New-AnfPool -Name $poolName1 -PoolSize $poolSize -ServiceLevel $serviceLevel
		
        
        $retrievedPool = Get-AnfPool -ResourceGroupName $resourceGroup -AccountName $accName -Name $poolName1 | Update-AnfPool -ServiceLevel "Standard"
        Assert-AreEqual "Standard" $retrievedPool.ServiceLevel
		
        
        $retrievedPool = Get-AnfAccount -ResourceGroupName $resourceGroup -Name $accName | Update-AnfPool -Name $poolName1 -PoolSize $poolSize -ServiceLevel "Premium"
        Assert-AreEqual "Premium" $retrievedPool.ServiceLevel

        
        Get-AnfAccount -ResourceGroupName $resourceGroup -Name $accName | Remove-AnfPool -Name $poolName1 

        
        New-AnfPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -Name $PoolName1 -PoolSize $poolSize -ServiceLevel $serviceLevel

        
        Get-AnfAccount -ResourceGroupName $resourceGroup -Name $accName | New-AnfPool -PoolName $poolName2 -PoolSize $poolSize -ServiceLevel $serviceLevel

        
        Get-AnfPool -ResourceGroupName $resourceGroup -AccountName $accName -Name $poolName1 | Remove-AzNetAppFilesPool

        $retrievedPool = Get-AnfAccount -ResourceGroupName $resourceGroup -AccountName $accName | Get-AnfPool 
		Assert-AreEqual 1 $retrievedPool.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}