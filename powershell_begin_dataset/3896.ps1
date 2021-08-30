














function Test-VolumeCrud
{
    $currentSub = (Get-AzureRmContext).Subscription	
    $subsid = $currentSub.SubscriptionId

    $resourceGroup = Get-ResourceGroupName
    $accName = Get-ResourceName
    $poolName = Get-ResourceName
    $poolName2 = Get-ResourceName
    $volName1 = Get-ResourceName
    $volName2 = Get-ResourceName
    $volName3 = Get-ResourceName
    $volName4 = Get-ResourceName
    $gibibyte = 1024 * 1024 * 1024
    $usageThreshold = 100 * $gibibyte
    $doubleUsage = 2 * $usageThreshold
    $resourceLocation = Get-ProviderLocation "Microsoft.NetApp"
    $subnetName = "default"
    $poolSize = 4398046511104
    $serviceLevel = "Premium"
    $vnetName = $resourceGroup + "-vnet"

    $subnetId = "/subscriptions/$subsId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnetName"

    $rule1 = @{
        RuleIndex = 1
        UnixReadOnly = $false
        UnixReadWrite = $true
        Cifs = $false
        Nfsv3 = $true
        Nfsv41 = $false
        AllowedClients = '0.0.0.0/0'
    }
    $rule2 = @{
        RuleIndex = 2
        UnixReadOnly = $false
        UnixReadWrite = $true
        Cifs = $false
        Nfsv3 = $false
        Nfsv41 = $true
        AllowedClients = '1.2.3.0/24'
    }
    $rule3 = @{
        RuleIndex = 2
        UnixReadOnly = $false
        UnixReadWrite = $true
        Cifs = $false
        Nfsv3 = $true
        Nfsv41 = $false
        AllowedClients = '2.3.4.0/24'
    }
    $rule5 = @{
        RuleIndex = 1
        UnixReadOnly = $false
        UnixReadWrite = $true
        Cifs = $false
        Nfsv3 = $false
        Nfsv41 = $true
        AllowedClients = '1.2.3.0/24'
    }
    $exportPolicy = @{
		Rules = (
			$rule1, $rule2
		)
	}
    
    $exportPolicyv4 = @{
		Rules = (
			$rule5
		)
	}

    $exportPolicyMod = @{
		Rules = (
			$rule3
		)
	}

    
    $protocolTypes = New-Object string[] 1
    $protocolTypes[0] = "NFSv3"

    try
    {
        
        New-AzResourceGroup -Name $resourceGroup -Location $resourceLocation
		
        
        $virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $resourceLocation -Name $vnetName -AddressPrefix 10.0.0.0/16
        $delegation = New-AzDelegation -Name "netAppVolumes" -ServiceName "Microsoft.Netapp/volumes"
        Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $virtualNetwork -AddressPrefix "10.0.1.0/24" -Delegation $delegation | Set-AzVirtualNetwork

        
        $retrievedAcc = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName 
	    
        
        $retrievedPool = New-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -PoolSize $poolSize -ServiceLevel $serviceLevel
        
        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedVolume = New-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName1 -CreationToken $volName1 -UsageThreshold $usageThreshold -ServiceLevel $serviceLevel -SubnetId $subnetId -Tag @{$newTagName = $newTagValue} -ExportPolicy $exportPolicy -ProtocolType $protocolTypes
        Assert-AreEqual "$accName/$poolName/$volName1" $retrievedVolume.Name
        Assert-AreEqual $serviceLevel $retrievedVolume.ServiceLevel
        Assert-AreEqual True $retrievedVolume.Tags.ContainsKey($newTagName)
        Assert-AreEqual "tagValue1" $retrievedVolume.Tags[$newTagName].ToString()
        Assert-NotNull $retrievedVolume.ExportPolicy
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[0].AllowedClients '0.0.0.0/0'
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[1].AllowedClients '1.2.3.0/24'
        Assert-AreEqual $retrievedVolume.ProtocolTypes[0] 'NFSv3'
        Assert-NotNull $retrievedVolume.MountTargets

        
        $protocolTypesv4 = New-Object string[] 1
        $protocolTypesv4[0] = "NFSv4.1"

        
        $retrievedVolume = New-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName2 -CreationToken $volName2 -UsageThreshold $usageThreshold -ServiceLevel $serviceLevel -SubnetId $subnetId -ExportPolicy $exportPolicyv4 -ProtocolType $protocolTypesv4 -Confirm:$false
        Assert-AreEqual "$accName/$poolName/$volName2" $retrievedVolume.Name
        Assert-AreEqual $serviceLevel $retrievedVolume.ServiceLevel
        Assert-AreEqual $retrievedVolume.ProtocolTypes[0] 'NFSv4.1'

        
        $retrievedVolume = New-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName3 -CreationToken $volName2 -UsageThreshold $usageThreshold -ServiceLevel $serviceLevel -SubnetId $subnetId -WhatIf

        
        $retrievedVolume = Get-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName
        
        Assert-True {"$accName/$poolName/$volName1" -eq $retrievedVolume[0].Name -or "$accName/$poolName/$volName2" -eq $retrievedVolume[0].Name}
        Assert-True {"$accName/$poolName/$volName1" -eq $retrievedVolume[1].Name -or "$accName/$poolName/$volName2" -eq $retrievedVolume[1].Name}
        Assert-AreEqual 2 $retrievedVolume.Length

        
        $retrievedVolume = Get-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName1
        Assert-AreEqual "$accName/$poolName/$volName1" $retrievedVolume.Name
		
        
        $retrievedVolumeById = Get-AzNetAppFilesVolume -ResourceId $retrievedVolume.Id
        Assert-AreEqual "$accName/$poolName/$volName1" $retrievedVolumeById.Name
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[0].AllowedClients '0.0.0.0/0'
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[1].AllowedClients '1.2.3.0/24'

        
        $retrievedVolume = Update-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName1 -UsageThreshold $doubleUsage
        Assert-AreEqual $doubleUsage $retrievedVolume.usageThreshold
        
        Assert-AreEqual "Premium" $retrievedVolume.ServiceLevel
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[0].AllowedClients '0.0.0.0/0'
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[1].AllowedClients '1.2.3.0/24'

        $rule4 = @{
            RuleIndex = 3
            UnixReadOnly = $false
            UnixReadWrite = $true
            Cifs = $false
            Nfsv3 = $true
            Nfsv41 = $false
            AllowedClients = '1.2.3.0/24'
        }

        $exportPolicyUpdate = @{
            Rules = (
                $rule2, $rule4
            )
        }

        
        $retrievedVolume = Update-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName -VolumeName $volName1 -ExportPolicy $exportPolicyUpdate
        Assert-AreEqual $retrievedVolume.ExportPolicy.Rules[0].AllowedClients '1.2.3.0/24'

        
        Remove-AzNetAppFilesVolume -ResourceId $retrievedVolumeById.Id

        
        Remove-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -Name $volName2 -WhatIf
        $retrievedVolume = Get-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName
        Assert-AreEqual 1 $retrievedVolume.Length

        Remove-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -VolumeName $volName2
        $retrievedVolume = Get-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName
        Assert-AreEqual 0 $retrievedVolume.Length

        
        
        $retrievedPool = New-AzNetAppFilesPool -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName2 -PoolSize $poolSize -ServiceLevel "Standard"
        
        
        $newTagName = "tag1"
        $newTagValue = "tagValue1"
        $retrievedVolume = New-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName2 -VolumeName $volName4 -CreationToken $volName4 -UsageThreshold $doubleUsage -ServiceLevel "Standard" -SubnetId $subnetId -Tag @{$newTagName = $newTagValue} -ExportPolicy $exportPolicy
        Assert-AreEqual "$accName/$poolName2/$volName4" $retrievedVolume.Name
        Assert-AreEqual "Standard" $retrievedVolume.ServiceLevel
        Assert-AreEqual True $retrievedVolume.Tags.ContainsKey($newTagName)
        Assert-AreEqual "tagValue1" $retrievedVolume.Tags[$newTagName].ToString()
        Assert-NotNull $retrievedVolume.ExportPolicy
        Assert-AreEqual '0.0.0.0/0' $retrievedVolume.ExportPolicy.Rules[0].AllowedClients
        Assert-AreEqual '1.2.3.0/24' $retrievedVolume.ExportPolicy.Rules[1].AllowedClients
        
        Assert-AreEqual $retrievedVolume.ProtocolTypes[0] 'NFSv3'

        
        $retrievedVolume = Update-AzNetAppFilesVolume -ResourceGroupName $resourceGroup -Location $resourceLocation -AccountName $accName -PoolName $poolName2 -VolumeName $volName4 -ExportPolicy $exportPolicyMod
        Assert-AreEqual '2.3.4.0/24' $retrievedVolume.ExportPolicy.Rules[0].AllowedClients
        
        Assert-AreEqual "Standard" $retrievedVolume.ServiceLevel
        Assert-AreEqual $doubleUsage $retrievedVolume.usageThreshold
        Assert-AreEqual True $retrievedVolume.Tags.ContainsKey($newTagName)
        Assert-AreEqual "tagValue1" $retrievedVolume.Tags[$newTagName].ToString()
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}


function Test-VolumePipelines
{
    $currentSub = (Get-AzureRmContext).Subscription	
    $subsid = $currentSub.SubscriptionId

    $resourceGroup = Get-ResourceGroupName
    $accName = Get-ResourceName
    $poolName = Get-ResourceName
    $volName1 = Get-ResourceName
    $volName2 = Get-ResourceName
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

        
        
        $retrievedVolume = Get-AnfPool -ResourceGroupName $resourceGroup -AccountName $accName -Name $poolName | New-AnfVolume -Name $volName1 -CreationToken $volName1 -UsageThreshold $usageThreshold -SubnetId $subnetId -ServiceLevel $serviceLevel
        Assert-AreEqual "$accName/$poolName/$volName1" $retrievedVolume.Name
        Assert-AreEqual "Premium" $retrievedVolume.ServiceLevel
        
        
        
        
        try
        {
            $retrievedVolume = Get-AnfPool -ResourceGroupName $resourceGroup -AccountName $accName -Name $poolName | New-AnfVolume -Name $volName2 -CreationToken $volName2 -UsageThreshold $usageThreshold -ServiceLevel "Standard" -SubnetId $subnetId
            Assert-AreEqual "$accName/$poolName/$volName2" $retrievedVolume.Name
            Assert-AreEqual "Standard" $retrievedVolume.ServiceLevel
            Assert-True { $false }
        }
        catch
        {
            Assert-True { $true }
        }

        
        $retrievedVolume = Get-AnfVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -Name $volName1 | Update-AnfVolume -UsageThreshold $doubleUsage
        Assert-AreEqual "Premium" $retrievedVolume.ServiceLevel  
		Assert-AreEqual $doubleUsage $retrievedVolume.usageThreshold

        
        $retrievedVolume = Get-AnfVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName
        $numVolumes = $retrievedVolume.Length

        
        Get-AnfVolume -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName -Name $volName1 | Remove-AnfVolume

        
        $retrievedVolume = Get-AnfPool -ResourceGroupName $resourceGroup -AccountName $accName -PoolName $poolName | Get-AnfVolume 
        Assert-AreEqual ($numVolumes-1) $retrievedVolume.Length
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroup
    }
}