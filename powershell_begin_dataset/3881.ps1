














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
