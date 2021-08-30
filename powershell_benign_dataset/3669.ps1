














function Test-GetServerServiceObjective
{
	
	$rg = Create-ResourceGroupForTest
	$rg | Out-String | Write-Output

	$server = Create-ServerForTest $rg
	$server | Out-String | Write-Output

	$requestedSlo = "GP_Gen5_2"
	$requestedSloFilter = "GP_Gen*_2"

	try
	{
		
		$o = Get-AzSqlServerServiceObjective $rg.ResourceGroupName $server.ServerName
		Assert-AreNotEqual 0 $o.Length "Expected more than 0 service objectives"

		$o = Get-AzSqlServerServiceObjective $rg.ResourceGroupName $server.ServerName $requestedSlo
		Assert-AreEqual 1 $o.Length "Could not find exactly 1 service objective for $requestedSlo"

		
		$o = Get-AzSqlServerServiceObjective -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ServiceObjectiveName $requestedSlo
		Assert-AreEqual 1 $o.Length "Could not find exactly 1 service objective for $requestedSlo"

		$o = Get-AzSqlServerServiceObjective -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -ServiceObjectiveName $requestedSloFilter
		Assert-True {$o.Length -ge 2} "Expected 2 or more service objectives for $requestedSloFilter, actual $($o.Length)"
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}


function Test-GetServerServiceObjectiveByLocation
{
	
	$location = "Japan East"
	$requestedSlo = "GP_Gen5_2"
	$requestedSloFilter = "GP_Gen*_2"

	
	$o = Get-AzSqlServerServiceObjective -Location $location
	Assert-AreNotEqual 0 $o.Length "Expected more than 0 service objectives"

	
	$o = Get-AzSqlServerServiceObjective -Location $location -ServiceObjectiveName $requestedSlo
	Assert-AreEqual 1 $o.Length "Could not find exactly 1 service objective for $requestedSlo"

	$o = Get-AzSqlServerServiceObjective -Location $location -ServiceObjectiveName $requestedSloFilter
	Assert-True {$o.Length -ge 2} "Expected 2 or more service objectives for $requestedSloFilter, actual $($o.Length)"
}
