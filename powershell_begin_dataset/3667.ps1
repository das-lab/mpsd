














function Test-CreateAgent
{
    
    $location = Get-Location "Microsoft.Sql" "operations" "West US 2"
    $rg1 = Create-ResourceGroupForTest
    $s1 = Create-ServerForTest $rg1 $location
    $db1 = Create-DatabaseForTest $s1
    $db2 = Create-DatabaseForTest $s1
    $db3 = Create-DatabaseForTest $s1
    $db4 = Create-DatabaseForTest $s1

    try
    {
        
        $agentName = Get-AgentName
        $resp = New-AzSqlElasticJobAgent -ResourceGroupName $rg1.ResourceGroupName -ServerName $s1.ServerName -DatabaseName $db1.DatabaseName -AgentName $agentName
        Assert-AreEqual $resp.AgentName $agentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $agentName = Get-AgentName
        $resp = New-AzSqlElasticJobAgent -DatabaseObject $db2 -Name $agentName
        Assert-AreEqual $resp.AgentName $agentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db2.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $agentName = Get-AgentName
        $resp = New-AzSqlElasticJobAgent -DatabaseResourceId $db3.ResourceId -Name $agentName
        Assert-AreEqual $resp.AgentName $agentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db3.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $agentName = Get-AgentName
        $resp = $db4 | New-AzSqlElasticJobAgent -Name $agentName
        Assert-AreEqual $resp.AgentName $agentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db4.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100
    }
    finally
    {
        Remove-ResourceGroupForTest $rg1
    }
}


function Test-UpdateAgent
{
    
    $location = Get-Location "Microsoft.Sql" "operations" "West US 2"
    $rg1 = Create-ResourceGroupForTest
    $s1 = Create-ServerForTest $rg1 $location
    $db1 = Create-DatabaseForTest $s1
    $a1 = Create-AgentForTest $db1
    $agentName = Get-AgentName
    $tags = @{ Octopus="Agent"}

    try
    {
        
        $resp = Set-AzSqlElasticJobAgent -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Tag $tags
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100
        Assert-AreEqual $resp.Tags.Octopus "Agent"

        
        $resp = Set-AzSqlElasticJobAgent -InputObject $a1 -Tag $tags
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100
        Assert-AreEqual $resp.Tags.Octopus "Agent"

        
        $resp = Set-AzSqlElasticJobAgent -ResourceId $a1.ResourceId -Tag $tags
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100
        Assert-AreEqual $resp.Tags.Octopus "Agent"

        
        $resp = $a1 | Set-AzSqlElasticJobAgent -Tag $tags
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100
        Assert-AreEqual $resp.Tags.Octopus "Agent"
    }
    finally
    {
        Remove-ResourceGroupForTest $rg1
    }
}


function Test-GetAgent
{
    
    $location = Get-Location "Microsoft.Sql" "operations" "West US 2"
    $rg1 = Create-ResourceGroupForTest
    $s1 = Create-ServerForTest $rg1 $location
    $s2 = Create-ServerForTest $rg1 $location
    $db1 = Create-DatabaseForTest $s1
    $db2 = Create-DatabaseForTest $s1
    $db3 = Create-DatabaseForTest $s2
    $a1 = Create-AgentForTest $db1
    $a2 = Create-AgentForTest $db2
    $a3 = Create-AgentForTest $db3
    $agentName = Get-AgentName

    try
    {
        
        $resp = Get-AzSqlElasticJobAgent -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = Get-AzSqlElasticJobAgent -ParentObject $s1 -AgentName $a1.AgentName
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = Get-AzSqlElasticJobAgent -ParentResourceId $s1.ResourceId -AgentName $a1.AgentName
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = $s1 | Get-AzSqlElasticJobAgent -Name $a1.AgentName
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $a1.ServerName
        Assert-AreEqual $resp.DatabaseName $a1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
        Assert-AreEqual $resp.Location $a1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = $s1 | Get-AzSqlElasticJobAgent
        Assert-AreEqual $resp.Count 2

        
        $resp = Get-AzSqlServer -ResourceGroupName $rg1.ResourceGroupName | Get-AzSqlElasticJobAgent
        Assert-AreEqual $resp.Count 3
    }
    finally
    {
        Remove-ResourceGroupForTest $rg1
    }
}


function Test-RemoveAgent
{
    
    $location = Get-Location "Microsoft.Sql" "operations" "West US 2"
    $rg1 = Create-ResourceGroupForTest
    $s1 = Create-ServerForTest $rg1 $location
    $db1 = Create-DatabaseForTest $s1
    $db2 = Create-DatabaseForTest $s1
    $db3 = Create-DatabaseForTest $s1
    $db4 = Create-DatabaseForTest $s1
    $a1 = Create-AgentForTest $db1
    $a2 = Create-AgentForTest $db2
    $a3 = Create-AgentForTest $db3
    $a4 = Create-AgentForTest $db4

    try
    {
        
        $resp = Remove-AzSqlElasticJobAgent -ResourceGroupName $rg1.ResourceGroupName -ServerName $s1.ServerName -AgentName $a1.AgentName -Force
        Assert-AreEqual $resp.AgentName $a1.AgentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db1.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = Remove-AzSqlElasticJobAgent -InputObject $a2 -Force
        Assert-AreEqual $resp.AgentName $a2.AgentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db2.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = Remove-AzSqlElasticJobAgent -ResourceId $a3.ResourceId -Force
        Assert-AreEqual $resp.AgentName $a3.AgentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db3.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        $resp = $a4 | Remove-AzSqlElasticJobAgent -Force
        Assert-AreEqual $resp.AgentName $a4.AgentName
        Assert-AreEqual $resp.ServerName $s1.ServerName
        Assert-AreEqual $resp.DatabaseName $db4.DatabaseName
        Assert-AreEqual $resp.ResourceGroupName $rg1.ResourceGroupName
        Assert-AreEqual $resp.Location $s1.Location
        Assert-AreEqual $resp.WorkerCount 100

        
        Assert-Throws { $s1 | Get-AzSqlElasticJobAgent -Name $a1.AgentName }
        Assert-Throws { $s1 | Get-AzSqlElasticJobAgent -Name $a2.AgentName }
        Assert-Throws { $s1 | Get-AzSqlElasticJobAgent -Name $a3.AgentName }
        Assert-Throws { $s1 | Get-AzSqlElasticJobAgent -Name $a4.AgentName }
    }
    finally
    {
        Remove-ResourceGroupForTest $rg1
    }
}