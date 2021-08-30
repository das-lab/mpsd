














function Test-CreateTargetGroup
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-CreateTargetGroupWithDefaultParam $a1
		Test-CreateTargetGroupWithParentObject $a1
		Test-CreateTargetGroupWithParentResourceId $a1
		Test-CreateTargetGroupWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-GetTargetGroup
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-GetTargetGroupWithDefaultParam $a1
		Test-GetTargetGroupWithParentObject $a1
		Test-GetTargetGroupWithParentResourceId $a1
		Test-GetTargetGroupWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-RemoveTargetGroup
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-RemoveTargetGroupWithDefaultParam $a1
		Test-RemoveTargetGroupWithInputObject $a1
		Test-RemoveTargetGroupWithResourceId $a1
		Test-RemoveTargetGroupWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-CreateTargetGroupWithDefaultParam ($a1)
{
    $tgName = Get-TargetGroupName

    
    $resp = New-AzSqlElasticJobTargetGroup -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $tgName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tgName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-CreateTargetGroupWithParentObject ($a1)
{
    $tgName = Get-TargetGroupName

    
    $resp = New-AzSqlElasticJobTargetGroup -ParentObject $a1 -Name $tgName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tgName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-CreateTargetGroupWithParentResourceId ($a1)
{
    $tgName = Get-TargetGroupName

    
    $resp = New-AzSqlElasticJobTargetGroup -ParentResourceId $a1.ResourceId -Name $tgName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tgName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-CreateTargetGroupWithPiping ($a1)
{
    $tgName = Get-TargetGroupName

    
    $resp = $a1 | New-AzSqlElasticJobTargetGroup -Name $tgName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tgName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-GetTargetGroupWithDefaultParam ($a1)
{
    $tg = Create-TargetGroupForTest $a1
    $tg2 = Create-TargetGroupForTest $a1

    
    $resp = Get-AzSqlElasticJobTargetGroup -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $tg.TargetGroupName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0

    
    $resp = Get-AzSqlElasticJobTargetGroup -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName
    Assert-True { $resp.Count -ge 2 }
}


function Test-GetTargetGroupWithParentObject ($a1)
{
    $tg = Create-TargetGroupForTest $a1
    $tg2 = Create-TargetGroupForTest $a1

    
    $resp = Get-AzSqlElasticJobTargetGroup -ParentObject $a1 -Name $tg.TargetGroupName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0

    
    $resp = Get-AzSqlElasticJobTargetGroup -ParentObject $a1
    Assert-True { $resp.Count -ge 2 }
}


function Test-GetTargetGroupWithParentResourceId ($a1)
{
    $tg = Create-TargetGroupForTest $a1
    $tg2 = Create-TargetGroupForTest $a1

    
    $resp = Get-AzSqlElasticJobTargetGroup -ParentResourceId $a1.ResourceId -Name $tg.TargetGroupName
    Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
    Assert-AreEqual $resp.AgentName $a1.AgentName
    Assert-AreEqual $resp.ServerName $a1.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0

    
    $resp = Get-AzSqlElasticJobTargetGroup -ParentResourceId $a1.ResourceId
    Assert-True { $resp.Count -ge 2 }
}


function Test-GetTargetGroupWithPiping ($a1)
{
    $tg = Create-TargetGroupForTest $a1

    
    $resp = $a1 | Get-AzSqlElasticJobTargetGroup -Name $tg.TargetGroupName
    Assert-AreEqual $resp.ResourceGroupName $tg.ResourceGroupName
    Assert-AreEqual $resp.AgentName $tg.AgentName
    Assert-AreEqual $resp.ServerName $tg.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-RemoveTargetGroupWithDefaultParam ($a1)
{
    $tg = Create-TargetGroupForTest $a1

    
    $resp = Remove-AzSqlElasticJobTargetGroup -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $tg.TargetGroupName
    Assert-AreEqual $resp.ResourceGroupName $tg.ResourceGroupName
    Assert-AreEqual $resp.AgentName $tg.AgentName
    Assert-AreEqual $resp.ServerName $tg.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-RemoveTargetGroupWithInputObject ($a1)
{
    $tg = Create-TargetGroupForTest $a1

    
    $resp = Remove-AzSqlElasticJobTargetGroup -InputObject $tg
    Assert-AreEqual $resp.ResourceGroupName $tg.ResourceGroupName
    Assert-AreEqual $resp.AgentName $tg.AgentName
    Assert-AreEqual $resp.ServerName $tg.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-RemoveTargetGroupWithResourceId ($a1)
{
    $tg = Create-TargetGroupForTest $a1

    
    $resp = Remove-AzSqlElasticJobTargetGroup -ResourceId $tg.ResourceId
    Assert-AreEqual $resp.ResourceGroupName $tg.ResourceGroupName
    Assert-AreEqual $resp.AgentName $tg.AgentName
    Assert-AreEqual $resp.ServerName $tg.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0
}


function Test-RemoveTargetGroupWithPiping ($a1)
{
    $tg = Create-TargetGroupForTest $a1
    $tg2 = Create-TargetGroupForTest $a1

    
    $resp = $tg | Remove-AzSqlElasticJobTargetGroup
    Assert-AreEqual $resp.ResourceGroupName $tg.ResourceGroupName
    Assert-AreEqual $resp.AgentName $tg.AgentName
    Assert-AreEqual $resp.ServerName $tg.ServerName
    Assert-AreEqual $resp.TargetGroupName $tg.TargetGroupName
    Assert-AreEqual $resp.Members.Count 0

    
    $all = $a1 | Get-AzSqlElasticJobTargetGroup
    $resp = $all | Remove-AzSqlElasticJobTargetGroup
    Assert-True { $resp.Count -ge 1 }

    
    Assert-Throws { $a1 | Get-AzSqlElasticJobTargetGroup -Name $tg.TargetGroupName }
}