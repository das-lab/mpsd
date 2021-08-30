














function Test-ListStretchDatabaseRestorePoints
{
	
	$location = Get-ProviderLocation "Microsoft.Sql/servers"
	$serverVersion = "12.0";
	$rg = Create-ResourceGroupForTest $location

	try
	{
		$server = Create-ServerForTest $rg $location

		
		$databaseName = Get-DatabaseName
		$stretchdb = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $databaseName `
			-Edition Stretch -RequestedServiceObjectiveName DS100

		
		$restorePoints = Get-AzSqlDatabaseRestorePoint -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $stretchdb.DatabaseName
		Assert-Null $restorePoints 
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
	}
}