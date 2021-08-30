














function Test-CreateServerCommunicationLink
{
	
	$locationOverride = "North Europe"
	$serverVersion = "12.0"
	$rg = Create-ResourceGroupForTest $locationOverride
	$server1 = Create-ServerForTest $rg $locationOverride
	$server2 = Create-ServerForTest $rg $locationOverride

	try
	{
		$linkName = Get-ElasticPoolName
		$ep1 = New-AzSqlServerCommunicationLink -ServerName $server1.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-LinkName $linkName -PartnerServer $server2.ServerName

		Assert-NotNull $ep1
		Assert-AreEqual $linkName $ep1.Name
		Assert-AreEqual $server2.ServerName $ep1.PartnerServer
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetServerCommunicationLink
{
	
	$locationOverride = "North Europe"
	$serverVersion = "12.0"
	$rg = Create-ResourceGroupForTest $locationOverride
	$server1 = Create-ServerForTest $rg $locationOverride
	$server2 = Create-ServerForTest $rg $locationOverride

	$linkName = Get-ElasticPoolName
	$job = New-AzSqlServerCommunicationLink -ServerName $server1.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-LinkName $linkName -PartnerServer $server2.ServerName -AsJob
	$job | Wait-Job
	$ep1 = $job.Output

	Assert-NotNull $ep1
	Assert-AreEqual $linkName $ep1.Name
	Assert-AreEqual $server2.ServerName $ep1.PartnerServer
	
	try
	{
		$gep1 = Get-AzSqlServerCommunicationLink -ServerName $server1.ServerName -ResourceGroupName $rg.ResourceGroupName `
			-LinkName $ep1.Name 
		Assert-NotNull $gep1
		Assert-AreEqual $linkName $gep1.Name
		Assert-AreEqual $server2.ServerName $gep1.PartnerServer

		$all = $server1 | Get-AzSqlServerCommunicationLink -LinkName *
		Assert-AreEqual $all.Count 1
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-RemoveServerCommunicationLink
{
	
	$locationOverride = "North Europe"
	$serverVersion = "12.0"
	$rg = Create-ResourceGroupForTest $locationOverride
	$server1 = Create-ServerForTest $rg $locationOverride
	$server2 = Create-ServerForTest $rg $locationOverride

	$linkName = Get-ElasticPoolName
	$ep1 = New-AzSqlServerCommunicationLink -ServerName $server1.ServerName -ResourceGroupName $rg.ResourceGroupName `
		-LinkName $linkName -PartnerServer $server2.ServerName
	Assert-NotNull $ep1
	
	try
	{
		Remove-AzSqlServerCommunicationLink -ServerName $server1.ServerName -ResourceGroupName $rg.ResourceGroupName -LinkName $ep1.Name -Force
		
		$all = $server1 | Get-AzSqlServerCommunicationLink
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}
