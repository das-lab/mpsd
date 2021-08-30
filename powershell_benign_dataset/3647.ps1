














function Test-ElasticPoolRecommendation
{
    $response = Get-AzSqlElasticPoolRecommendation -ResourceGroupName TestRg -ServerName test-srv-v1
    Assert-NotNull $response
    Assert-AreEqual 2 $response.Count

    Assert-AreEqual "ElasticPool2" $response[1].Name
    Assert-AreEqual "Standard" $response[1].Edition
    Assert-AreEqual 1000 $response[1].Dtu
    Assert-AreEqual 100 $response[1].DatabaseDtuMin
    Assert-AreEqual 200 $response[1].DatabaseDtuMax
    Assert-AreEqual 0 $response[1].IncludeAllDatabases
    Assert-AreEqual 1 $response[1].DatabaseCollection.Count
    Assert-AreEqual master $response[1].DatabaseCollection[0]
}