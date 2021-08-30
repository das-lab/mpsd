














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