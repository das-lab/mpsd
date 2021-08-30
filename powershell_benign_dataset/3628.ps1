















function Test-CreateServerDNSAlias
{
	
	$location = "East US 2 EUAP"
	$rg = Create-ResourceGroupForTest $location 	
	$server = Create-ServerForTest $rg $location

	$serverDnsAliasName = Get-ServerDnsAliasName

	try
	{
		$job = New-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName -AsJob
		$job | Wait-Job
		$serverDnsAlias = $job.Output

		Assert-AreEqual $serverDnsAlias.ServerName $server.ServerName
		Assert-AreEqual $serverDnsAlias.DnsAliasName $serverDnsAliasName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-GetServerDNSAlias
{
	
	$location = "East US 2 EUAP"
	$rg = Create-ResourceGroupForTest $location 	
	$server = Create-ServerForTest $rg $location

	$serverDnsAliasName = Get-ServerDnsAliasName
	$serverDnsAliasName2 = Get-ServerDnsAliasName

	try
	{
		
		$serverDnsAlias = New-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName
		Assert-AreEqual $serverDnsAlias.ServerName $server.ServerName
		Assert-AreEqual $serverDnsAlias.DnsAliasName $serverDnsAliasName

		
		$serverDnsAlias = New-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName2
		Assert-AreEqual $serverDnsAlias.ServerName $server.ServerName
		Assert-AreEqual $serverDnsAlias.DnsAliasName $serverDnsAliasName2

		
		$resp = Get-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName
		Assert-AreEqual $resp.ServerName $server.ServerName
		Assert-AreEqual $resp.DnsAliasName $serverDnsAliasName

		
		$resp = Get-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName *
		Assert-AreEqual $resp.Count 2
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-RemoveServerDNSAlias
{
	
	$location = "East US 2 EUAP"
	$rg = Create-ResourceGroupForTest $location 	
	$server = Create-ServerForTest $rg $location

	$serverDnsAliasName = Get-ServerDnsAliasName

	try
	{
		
		$serverDnsAlias = New-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName
		Assert-AreEqual $serverDnsAlias.ServerName $server.ServerName
		Assert-AreEqual $serverDnsAlias.DnsAliasName $serverDnsAliasName

		
		$job = Remove-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName -Force -AsJob
		$job | Wait-Job
		$resp = $job.Output

		$all = Get-AzSqlServerDNSAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}



function Test-UpdateServerDNSAlias
{
	
	$location = "East US 2 EUAP"
	$rg = Create-ResourceGroupForTest $location 	
	$server = Create-ServerForTest $rg $location
	$server2 = Create-ServerForTest $rg $location

	$serverDnsAliasName = Get-ServerDnsAliasName

	try
	{
		
		$serverDnsAlias = New-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DnsAliasName $serverDnsAliasName
		Assert-AreEqual $serverDnsAlias.ServerName $server.ServerName
		Assert-AreEqual $serverDnsAlias.DnsAliasName $serverDnsAliasName

		
		$subId = (Get-AzContext).Subscription.Id

		
		$job = Set-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -SourceServerName $server.ServerName -DnsAliasName $serverDnsAliasName `
			-TargetServerName $server2.ServerName -SourceServerResourceGroupName $rg.ResourceGroupName -SourceServerSubscriptionId $subId -AsJob
		$job | Wait-Job

		$resp = Get-AzSqlServerDnsAlias -ResourceGroupName $rg.ResourceGroupName -ServerName $server2.ServerName -DnsAliasName $serverDnsAliasName
		Assert-AreEqual $resp.ServerName $server2.ServerName
		Assert-AreEqual $resp.DnsAliasName $serverDnsAliasName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}