














function Test-CreateSyncAgent
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

    try
    {
        
        $saName = Get-SyncAgentName
        $sa = New-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
                -SyncAgentName $saName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -SyncDatabaseServerName $server.ServerName `
                -SyncDatabaseName $databaseName
        Assert-NotNull $sa
        Assert-AreEqual $saName $sa.SyncAgentName
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-GetAndListSyncAgents
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName

    
    $saName = Get-SyncAgentName
    $sa = New-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -SyncAgentName $saName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -SyncDatabaseServerName $server.ServerName `
            -SyncDatabaseName $databaseName
    try
    {
        
        $sa2 = Get-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -SyncAgentName $saName
        Assert-NotNull $sa2
        Assert-AreEqual $saName $sa2.SyncAgentName

        
        $all = Get-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -SyncAgentName *
        Assert-NotNull $all
        Assert-AreEqual $all.Count 1
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-RemoveSyncAgent
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $saName = Get-SyncAgentName
    $sa = New-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -SyncAgentName $saName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -SyncDatabaseServerName $server.ServerName `
            -SyncDatabaseName $databaseName
    try
    {
        
        Remove-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
         -SyncAgentName $saName -Force

        $all = Get-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName
        Assert-AreEqual $all.Count 0
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-CreateSyncAgentKey
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $saName = Get-SyncAgentName
    $sa = New-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -SyncAgentName $saName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -SyncDatabaseServerName $server.ServerName `
            -SyncDatabaseName $databaseName
    try
    {
        
        $key = New-AzSqlSyncAgentKey -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
         -SyncAgentName $saName

        Assert-NotNull $key
        Assert-NotNull $key.SyncAgentKey
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-ListSyncAgentLinkedDatabase
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $saName = Get-SyncAgentName
    $sa = New-AzSqlSyncAgent -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -SyncAgentName $saName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -SyncDatabaseServerName $server.ServerName `
            -SyncDatabaseName $databaseName
    try
    {
        
        $dbs = Get-AzSqlSyncAgentLinkedDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
         -SyncAgentName $saName
        Assert-Null $dbs
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-CreateSyncGroup
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $credential = Get-ServerCredential
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    $params = Get-SqlSyncGroupTestEnvironmentParameters

    try
    {
        
        $sgName = Get-SyncGroupName
        $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -DatabaseName $databaseName -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
            -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
            $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
        Assert-AreEqual $params.intervalInSeconds $sg.IntervalInSeconds
        Assert-AreEqual $params.conflictResolutionPolicy $sg.ConflictResolutionPolicy
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-UpdateSyncGroup
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $credential = Get-ServerCredential
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
        -DatabaseName $databaseName -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
        -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
        $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    try
    {
        
        $newIntervalInSeconds = 200
        $sg2 = Update-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -DatabaseName $databaseName -SyncGroupName $sgName -IntervalInSeconds $newIntervalInSeconds 
        Assert-AreEqual $newIntervalInSeconds $sg2.IntervalInSeconds
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-GetAndListSyncGroups
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $credential = Get-ServerCredential
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
        -DatabaseName $databaseName -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
        -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
        $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    try
    {
        
        $sg1 = Get-AzSqlSyncGroup -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName -SyncGroupName $sgName
        Assert-AreEqual $params.intervalInSeconds $sg1.IntervalInSeconds
        Assert-AreEqual $params.conflictResolutionPolicy $sg1.ConflictResolutionPolicy

        
        $all = Get-AzSqlSyncGroup -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName -SyncGroupName *
        Assert-AreEqual $all.Count 1
        Assert-AreEqual $params.intervalInSeconds $all[0].IntervalInSeconds
        Assert-AreEqual $params.conflictResolutionPolicy $all[0].ConflictResolutionPolicy
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-RefreshAndGetSyncGroupHubSchema
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $credential = Get-ServerCredential
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
        -DatabaseName $databaseName -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
        -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
        $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    try
    {
        
        Update-AzSqlSyncSchema -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -DatabaseName $databaseName -SyncGroupName $sgName

        
        $schema = Get-AzSqlSyncSchema -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -DatabaseName $databaseName -SyncGroupName $sgName
        Assert-NotNull $schema
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-RemoveSyncGroup
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $credential = Get-ServerCredential
    $databaseName = Get-DatabaseName
    $db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
        -DatabaseName $databaseName -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
        -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
        $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    try
    {
        
        Remove-AzSqlSyncGroup -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName -SyncGroupName $sgName -Force
        
        $all = Get-AzSqlSyncGroup -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName
        Assert-AreEqual $all.Count 0
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-CreateSyncMember
{
    
    $rg = Create-ResourceGroupForTest 
    $server = Create-ServerForTest $rg "West US 2"
    $serverDNS = Get-DNSNameBasedOnEnvironment
    $serverName = $server.ServerName + $serverDNS
    $credential = Get-ServerCredential
    $databaseName1 = Get-DatabaseName
    $db1 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName1
    $databaseName2 = Get-DatabaseName
    $db2 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName2
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
                -DatabaseName $databaseName1 -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
                -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
                $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential

    try
    {
        
        $smParams = Get-SqlSyncMemberTestEnvironmentParameters
        $smName = Get-SyncMemberName
        $sm1 = New-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
            -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName `
            -SyncDirection $smParams.syncDirection -MemberDatabaseType $smParams.databaseType -MemberDatabaseName $databaseName2 `
            -MemberServerName $serverName -MemberDatabaseCredential $credential
        Assert-AreEqual $smParams.syncDirection $sm1.SyncDirection
        Assert-AreEqual $smParams.databaseType $sm1.MemberDatabaseType
        Assert-AreEqual $databaseName2 $sm1.MemberDatabaseName
        Assert-AreEqual $serverName $sm1.MemberServerName
        Assert-Null $sm1.MemberDatabasePassword
        Assert-Null $sm1.SyncAgentId
        Assert-Null $sm1.SqlServerDatabaseId
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-GetAndListSyncMembers
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $serverDNS = Get-DNSNameBasedOnEnvironment
    $serverName = $server.ServerName + $serverDNS
    $credential = Get-ServerCredential
    $databaseName1 = Get-DatabaseName
    $db1 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName1
    $databaseName2 = Get-DatabaseName
    $db2 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName2
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
        
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
                -DatabaseName $databaseName1 -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
                -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
                $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    
    $smParams = Get-SqlSyncMemberTestEnvironmentParameters
    $smName = Get-SyncMemberName
    $sm1 = New-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName `
        -SyncDirection $smParams.syncDirection -MemberDatabaseType $smParams.databaseType -MemberDatabaseName $databaseName2 `
        -MemberServerName $serverName -MemberDatabaseCredential $credential
    try
    {
        
        $sm2 = Get-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sg.SyncGroupName -SyncMemberName $smName
        Assert-AreEqual $smParams.syncDirection $sm1.SyncDirection
        Assert-AreEqual $smParams.databaseType $sm1.MemberDatabaseType
        Assert-AreEqual $databaseName2 $sm1.MemberDatabaseName
        Assert-AreEqual $serverName $sm1.MemberServerName
        Assert-Null $sm1.MemberDatabasePassword
        Assert-Null $sm1.SyncAgentId
        Assert-Null $sm1.SqlServerDatabaseId

        
        $all = Get-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sg.SyncGroupName -SyncMemberName *
        Assert-AreEqual 1 $all.Count
        Assert-AreEqual $smParams.syncDirection $all[0].SyncDirection
        Assert-AreEqual $smParams.databaseType $all[0].MemberDatabaseType
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-UpdateSyncMember
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $serverDNS = Get-DNSNameBasedOnEnvironment
    $serverName = $server.ServerName + $serverDNS
    $credential = Get-ServerCredential
    $databaseName1 = Get-DatabaseName
    $db1 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName1
    $databaseName2 = Get-DatabaseName
    $db2 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName2
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
                -DatabaseName $databaseName1 -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
                -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
                $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    
    $smParams = Get-SqlSyncMemberTestEnvironmentParameters
    $smName = Get-SyncMemberName
    $sm1 = New-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName `
        -SyncDirection $smParams.syncDirection -MemberDatabaseType $smParams.databaseType -MemberDatabaseName $databaseName2 `
        -MemberServerName $serverName -MemberDatabaseCredential $credential
    try
    {
        
        $sm2 = Update-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
            -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName `
            -MemberDatabaseCredential $credential
        Assert-AreEqual $smParams.databaseType $sm2.MemberDatabaseType
        Assert-AreEqual $databaseName2 $sm2.MemberDatabaseName
        Assert-AreEqual $serverName $sm2.MemberServerName
        Assert-Null $sm2.MemberDatabasePassword
        Assert-Null $sm2.SyncAgentId
        Assert-Null $sm2.SqlServerDatabaseId
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}


function Test-RefreshAndGetSyncMemberSchema
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $serverDNS = Get-DNSNameBasedOnEnvironment
    $serverName = $server.ServerName + $serverDNS
    $credential = Get-ServerCredential
    $databaseName1 = Get-DatabaseName
    $db1 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName1
    $databaseName2 = Get-DatabaseName
    $db2 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName2
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
                -DatabaseName $databaseName1 -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
                -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
                $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    
    $smParams = Get-SqlSyncMemberTestEnvironmentParameters
    $smName = Get-SyncMemberName
    $sm1 = New-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName `
        -SyncDirection $smParams.syncDirection -MemberDatabaseType $smParams.databaseType -MemberDatabaseName $databaseName2 `
        -MemberServerName $serverName -MemberDatabaseCredential $credential
    try
    {
        
        Update-AzSqlSyncSchema -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName 

        
        $schema = Get-AzSqlSyncSchema -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
            -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName 
        Assert-NotNull $schema
    }
    finally
    {    
        Remove-ResourceGroupForTest $rg
    }
}


function Test-RemoveSyncMember
{
    
    $rg = Create-ResourceGroupForTest
    $server = Create-ServerForTest $rg "West US 2"
    $serverDNS = Get-DNSNameBasedOnEnvironment
    $serverName = $server.ServerName + $serverDNS
    $credential = Get-ServerCredential
    $databaseName1 = Get-DatabaseName
    $db1 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName1
    $databaseName2 = Get-DatabaseName
    $db2 = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName2
    $syncDatabaseName = Get-DatabaseName
    $syncdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $syncDatabaseName
    
    $params = Get-SqlSyncGroupTestEnvironmentParameters
    $sgName = Get-SyncGroupName
    $sg = New-AzSqlSyncGroup -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
                -DatabaseName $databaseName1 -SyncGroupName $sgName -IntervalInSeconds $params.intervalInSeconds `
                -ConflictResolutionPolicy $params.conflictResolutionPolicy -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName `
                $server.ServerName -SyncDatabaseResourceGroupName $rg.ResourceGroupName -DatabaseCredential $credential
    
    $smParams = Get-SqlSyncMemberTestEnvironmentParameters
    $smName = Get-SyncMemberName
    $sm1 = New-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName `
        -SyncDirection $smParams.syncDirection -MemberDatabaseType $smParams.databaseType -MemberDatabaseName $databaseName2 `
        -MemberServerName $serverName -MemberDatabaseCredential $credential
    try
    {
        
        Remove-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sgName -SyncMemberName $smName -Force
        
        $all = Get-AzSqlSyncMember -ServerName $server.ServerName -ResourceGroupName $rg.ResourceGroupName `
        -DatabaseName $databaseName1 -SyncGroupName $sgName
        Assert-AreEqual $all.Count 0
    }
    finally
    {
        Remove-ResourceGroupForTest $rg
    }
}