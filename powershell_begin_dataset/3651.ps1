














function Test-AddTarget
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		
		Test-AddServerTargetWithDefaultParam $a1
		Test-AddServerTargetWithParentObject $a1
		Test-AddServerTargetWithParentResourceId $a1
		Test-AddServerTargetWithPiping $a1

		
		Test-AddDatabaseTargetWithDefaultParam $a1
		Test-AddDatabaseTargetWithParentObject $a1
		Test-AddDatabaseTargetWithParentResourceId $a1
		Test-AddDatabaseTargetWithPiping $a1

		
		Test-AddElasticPoolTargetWithDefaultParam $a1
		Test-AddElasticPoolTargetWithParentObject $a1
		Test-AddElasticPoolTargetWithParentResourceId $a1
		Test-AddElasticPoolTargetWithPiping $a1

		
		Test-AddShardMapTargetWithDefaultParam $a1
		Test-AddShardMapTargetWithParentObject $a1
		Test-AddShardMapTargetWithParentResourceId $a1
		Test-AddShardMapTargetWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-RemoveTarget
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		
		Test-RemoveServerTargetWithDefaultParam $a1
		Test-RemoveServerTargetWithParentObject $a1
		Test-RemoveServerTargetWithParentResourceId $a1
		Test-RemoveServerTargetWithPiping $a1

		
		Test-RemoveDatabaseTargetWithDefaultParam $a1
		Test-RemoveDatabaseTargetWithParentObject $a1
		Test-RemoveDatabaseTargetWithParentResourceId $a1
		Test-RemoveDatabaseTargetWithPiping $a1

		
		Test-RemoveElasticPoolTargetWithDefaultParam $a1
		Test-RemoveElasticPoolTargetWithParentObject $a1
		Test-RemoveElasticPoolTargetWithParentResourceId $a1
		Test-RemoveElasticPoolTargetWithPiping $a1

		
		Test-RemoveShardMapTargetWithDefaultParam $a1
		Test-RemoveShardMapTargetWithParentObject $a1
		Test-RemoveShardMapTargetWithParentResourceId $a1
		Test-RemoveShardMapTargetWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-AddServerTargetWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"
}


function Test-AddServerTargetWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"
}


function Test-AddServerTargetWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"
}


function Test-AddServerTargetWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$allServers = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName
	$resp = $allServers | Add-AzSqlElasticJobTarget -ParentObject $tg1 -RefreshCredentialName $jc1.CredentialName
	Assert-NotNull $resp
}


function Test-RemoveServerTargetWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName

	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName	$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName $a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveServerTargetWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveServerTargetWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName -Exclude

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveServerTargetWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -RefreshCredentialName $jc1.CredentialName 

	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlServer"

	
	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp

	
	$allServers = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName
	$resp = $allServers | Remove-AzSqlElasticJobTarget -ParentObject $tg1 -RefreshCredentialName $jc1.CredentialName
	Assert-NotNull $resp
}


function Test-AddDatabaseTargetWithDefaultParam ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-DatabaseName $targetDatabaseName1 -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-DatabaseName $targetDatabaseName1 -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"
}


function Test-AddDatabaseTargetWithParentObject ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1 -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1 -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"
}


function Test-AddDatabaseTargetWithParentResourceId ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1 -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1 -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"
}


function Test-AddDatabaseTargetWithPiping ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1 -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1 -Exclude
	Assert-Null $resp

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$allDbs = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName | Get-AzSqlDatabase
	$resp = $allDbs | Add-AzSqlElasticJobTarget -ParentObject $tg1
	Assert-NotNull $resp
}


function Test-RemoveDatabaseTargetWithDefaultParam ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1

	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName	$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName $a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-Null $resp
}


function Test-RemoveDatabaseTargetWithParentObject ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1

	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-Null $resp
}


function Test-RemoveDatabaseTargetWithParentResourceId ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1

	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-Null $resp
}


function Test-RemoveDatabaseTargetWithPiping ($a1)
{
	
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
	$targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName

	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlDatabase"

	
	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -DatabaseName $targetDatabaseName1
	Assert-Null $resp

  
	$allDbs = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName | Get-AzSqlDatabase
	$resp = $allDbs | Remove-AzSqlElasticJobTarget -ParentObject $tg1
	Assert-NotNull $resp
}


function Test-AddElasticPoolTargetWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"
}


function Test-AddElasticPoolTargetWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"
}


function Test-AddElasticPoolTargetWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"
}


function Test-AddElasticPoolTargetWithPiping ($a1)
{
	
	$ep1 = Create-ElasticPoolForTest $a1 
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$allEps = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName | Get-AzSqlElasticPool
	$resp = $allEps | Add-AzSqlElasticJobTarget -ParentObject $tg1 -RefreshCredentialName $jc1.CredentialName
	Assert-NotNull $resp
}


function Test-RemoveElasticPoolTargetWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName

	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName	$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName $a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveElasticPoolTargetWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveElasticPoolTargetWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName -Exclude

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveElasticPoolTargetWithPiping ($a1)
{
	
	$ep1 = Create-ElasticPoolForTest $a1
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetElasticPoolName1 = Get-ElasticPoolName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $ep1.ServerName -ElasticPoolName $ep1.ElasticPoolName -RefreshCredentialName $jc1.CredentialName

	
	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetElasticPoolName $targetElasticPoolName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlElasticPool"

	
	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -ElasticPoolName $targetElasticPoolName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp

	
	$allEps = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName | Get-AzSqlElasticPool
	$resp = $allEps | Remove-AzSqlElasticJobTarget -ParentObject $tg1 -RefreshCredentialName $jc1.CredentialName
	Assert-NotNull $resp
}


function Test-AddShardMapTargetWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName `
		$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 `
		-ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"
}


function Test-AddShardMapTargetWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"
}


function Test-AddShardMapTargetWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = Add-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"
}


function Test-AddShardMapTargetWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude
	Assert-Null $resp

	
	$resp = $tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"
}


function Test-RemoveShardMapTargetWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName

	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName	$a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Remove-AzSqlElasticJobTarget -ResourceGroupName $a1.ResourceGroupName -AgentServerName $a1.ServerName -AgentName $a1.AgentName -TargetGroupName $tg1.TargetGroupName -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveShardMapTargetWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentObject $tg1 -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveShardMapTargetWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName -Exclude

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Exclude"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = Remove-AzSqlElasticJobTarget -ParentResourceId $tg1.ResourceId -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}


function Test-RemoveShardMapTargetWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$targetServerName1 = Get-ServerName
  $targetShardMapName1 = Get-ShardMapName
  $targetDatabaseName1 = Get-DatabaseName

	
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName

	
	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.TargetServerName $targetServerName1
	Assert-AreEqual $resp.TargetShardMapName $targetShardMapName1
	Assert-AreEqual $resp.TargetDatabaseName $targetDatabaseName1
	Assert-AreEqual $resp.RefreshCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.MembershipType "Include"
	Assert-AreEqual $resp.TargetType "SqlShardMap"

	
	$resp = $tg1 | Remove-AzSqlElasticJobTarget -ServerName $targetServerName1 -ShardMapName $targetShardMapName1 -DatabaseName $targetDatabaseName1 -RefreshCredentialName $jc1.CredentialName
	Assert-Null $resp
}