














function Test-GetUpgradeDatabaseHint
{
    $response = Get-AzSqlDatabaseUpgradeHint -ResourceGroupName TestRg -ServerName test-srv-v1 -DatabaseName *
    Assert-NotNull $response
    Assert-AreEqual 1 $response.Count
    Assert-AreEqual test-db-v1 $response[0].Name
    Assert-AreEqual Premium $response[0].TargetEdition
    Assert-AreEqual P2 $response[0].TargetServiceLevelObjective

    $response = Get-AzSqlDatabaseUpgradeHint -ResourceGroupName TestRg -ServerName test-srv-v1 -DatabaseName test-db-v1 
    Assert-NotNull $response
    Assert-AreEqual 1 $response.Count
    Assert-AreEqual test-db-v1 $response[0].Name
    Assert-AreEqual Standard $response[0].TargetEdition
    Assert-AreEqual S0 $response[0].TargetServiceLevelObjective

    $response = Get-AzSqlDatabaseUpgradeHint -ResourceGroupName TestRg -ServerName test-srv-v1 -ExcludeElasticPoolCandidates 1
    Assert-NotNull $response
    Assert-AreEqual 1 $response.Count
    Assert-AreEqual test-db-v1 $response[0].Name
    Assert-AreEqual Premium $response[0].TargetEdition
    Assert-AreEqual P2 $response[0].TargetServiceLevelObjective

    $response = Get-AzSqlDatabaseUpgradeHint -ResourceGroupName TestRg -ServerName test-srv-v1 -DatabaseName test-db-v1 -ExcludeElasticPoolCandidates 1
    Assert-NotNull $response
     Assert-AreEqual 1 $response.Count
    Assert-AreEqual test-db-v1 $response[0].Name
    Assert-AreEqual Standard $response[0].TargetEdition
    Assert-AreEqual S0 $response[0].TargetServiceLevelObjective
}


function Test-GetUpgradeServerHint
{
    $response = Get-AzSqlServerUpgradeHint -ResourceGroupName TestRg -ServerName test-srv-v1
    Assert-NotNull $response
    Assert-AreEqual 1 $response.Databases.Count
    Assert-AreEqual test-db-v1 $response.Databases[0].Name
    Assert-AreEqual Standard $response.Databases[0].TargetEdition
    Assert-AreEqual S0 $response.Databases[0].TargetServiceLevelObjective

    $response = Get-AzSqlServerUpgradeHint -ResourceGroupName TestRg -ServerName test-srv-v1 -ExcludeElasticPools 1
    Assert-NotNull $response
    Assert-AreEqual 1 $response.Databases.Count
    Assert-AreEqual test-db-v1 $response.Databases[0].Name
    Assert-AreEqual Standard $response.Databases[0].TargetEdition
    Assert-AreEqual S0 $response.Databases[0].TargetServiceLevelObjective
}