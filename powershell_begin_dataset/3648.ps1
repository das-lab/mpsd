














function Test-CreateServer
{
	
	$rg = Create-ResourceGroupForTest
	 	
	$serverName = Get-ServerName
	$version = "12.0"
	$serverLogin = "testusername"
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force)) 

	try
	{
		
		$job = New-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $serverName `
			-Location $rg.Location -ServerVersion $version -SqlAdministratorCredentials $credentials -AsJob
		$job | Wait-Job
		$server1 = $job.Output

		Assert-AreEqual $server1.ServerName $serverName
		Assert-AreEqual $server1.ServerVersion $version
		Assert-AreEqual $server1.SqlAdministratorLogin $serverLogin
		Assert-StartsWith ($server1.ServerName + ".") $server1.FullyQualifiedDomainName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateServer
{
	
	$rg = Create-ResourceGroupForTest
	$server = Create-ServerForTest $rg

	try
	{
		
		$serverPassword = "n3wc00lP@55w0rd"
		$secureString = ConvertTo-SecureString $serverPassword -AsPlainText -Force

		$server1 = Set-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName `
			-SqlAdministratorPassword $secureString
		
		Assert-AreEqual $server1.ServerName $server.ServerName
		Assert-AreEqual $server1.ServerVersion $server.ServerVersion
		Assert-AreEqual $server1.SqlAdministratorLogin $server.SqlAdministratorLogin
		Assert-StartsWith ($server1.ServerName + ".") $server1.FullyQualifiedDomainName
		
		
		$serverPassword = "n3wc00lP@55w0rd!!!"
		$secureString = ConvertTo-SecureString $serverPassword -AsPlainText -Force

		$server2 = $server | Set-AzSqlServer -SqlAdministratorPassword $secureString
		Assert-AreEqual $server2.ServerName $server.ServerName
		Assert-AreEqual $server2.ServerVersion $server.ServerVersion
		Assert-AreEqual $server2.SqlAdministratorLogin $server.SqlAdministratorLogin
		Assert-StartsWith ($server1.ServerName + ".") $server1.FullyQualifiedDomainName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetServer
{
	
	$rg = Create-ResourceGroupForTest
	$rg1 = Create-ResourceGroupForTest
	$server1 = Create-ServerForTest $rg
	$server2 = Create-ServerForTest $rg
	$server3 = Create-ServerForTest $rg1

	try
	{
		
		$resp1 = Get-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $server1.ServerName
		Assert-AreEqual $server1.ServerName $resp1.ServerName
		Assert-AreEqual $server1.SqlAdministratorLogin $resp1.SqlAdministratorLogin
		Assert-StartsWith ($server1.ServerName + ".") $server1.FullyQualifiedDomainName
		
		
		$resp2 = $server2 | Get-AzSqlServer
		Assert-AreEqual $server2.ServerName $resp2.ServerName
		Assert-AreEqual $server2.SqlAdministratorLogin $resp2.SqlAdministratorLogin
		Assert-StartsWith ($server1.ServerName + ".") $server1.FullyQualifiedDomainName
		
		$all = Get-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -Name *
		Assert-AreEqual 2 $all.Count

		
		$all2 = Get-AzSqlServer -ResourceGroupName *

		
		
		($server1, $server2, $server3) | ForEach-Object { Assert-True {$_.ServerName -in $all2.ServerName} }
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		Remove-ResourceGroupForTest $rg1
	}
}


function Test-RemoveServer
{
	
	$rg = Create-ResourceGroupForTest
	$server1 = Create-ServerForTest $rg
	$server2 = Create-ServerForTest $rg

	try
	{
		
		Remove-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $server1.ServerName -Force
		
		
		$server2 | Remove-AzSqlServer -Force

		$all = Get-AzSqlServer -ResourceGroupName $rg.ResourceGroupName
		Assert-AreEqual $all.Count 0
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-CreateServerWithIdentity
{
	
	$rg = Create-ResourceGroupForTest
	 	
	$serverName = Get-ServerName
	$serverLogin = "testusername"
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force)) 

	try
	{
		$server1 = New-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $serverName -Location "northeurope" -SqlAdministratorCredentials $credentials -AssignIdentity
		Assert-AreEqual $server1.ServerName $serverName
		Assert-AreEqual $server1.Identity.Type SystemAssigned
		Assert-NotNull $server1.Identity.PrincipalId
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateServerWithIdentity
{
	
	$rg = Create-ResourceGroupForTest
	$location = "westeurope"
	$server = Create-ServerForTest $rg $location

	try
	{
		$serverPassword = "n3wc00lP@55w0rd"
		$secureString = ConvertTo-SecureString $serverPassword -AsPlainText -Force

		$server1 = Set-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -SqlAdministratorPassword $secureString -AssignIdentity
		Assert-AreEqual $server1.ServerName $server.ServerName
		Assert-AreEqual $server1.Identity.Type SystemAssigned
		Assert-NotNull $server1.Identity.PrincipalId
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-UpdateServerWithoutIdentity
{
	
	$rg = Create-ResourceGroupForTest
	 	
	$serverName = Get-ServerName
	$serverLogin = "testusername"
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force)) 

	try
	{
		
		$server1 = New-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $serverName -Location "northeurope" -SqlAdministratorCredentials $credentials -AssignIdentity
		Assert-AreEqual $server1.ServerName $serverName
		Assert-AreEqual $server1.Identity.Type SystemAssigned
		Assert-NotNull $server1.Identity.PrincipalId

		
		$newPassword = "n3wc00lP@55w0rd"
		$secureString = ConvertTo-SecureString $newPassword -AsPlainText -Force
		$server2 = Set-AzSqlServer -ResourceGroupName $rg.ResourceGroupName -ServerName $server1.ServerName -SqlAdministratorPassword $secureString
		Assert-AreEqual $server2.Identity.Type SystemAssigned
		Assert-NotNull $server2.Identity.PrincipalId
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}