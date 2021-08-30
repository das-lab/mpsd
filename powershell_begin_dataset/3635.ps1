














function Test-GetIndexRecommendations
{
    
    $response = Get-AzSqlDatabaseIndexRecommendation -ResourceGroup Group-6 -ServerName witest-eus
    ValidateResponse($response)
    Assert-AreEqual "Active" $response[0].State

    
    $response = Get-AzSqlDatabaseIndexRecommendation -ResourceGroup Group-6 -ServerName witest-eus -DatabaseName witestdb-eus
    ValidateResponse($response)
    Assert-AreEqual "Active" $response[0].State

    
    $response = Get-AzSqlDatabaseIndexRecommendation -ResourceGroup Group-6 -ServerName witest-eus -DatabaseName witestdb-eus -IndexRecommendationName nci_wi_Clusters_034590D0-0378-4AB9-96D5-C144B14F6A9B
    ValidateResponse($response)
    Assert-AreEqual "Active" $response[0].State
}


function Test-CreateIndex
{
    
    $response = Start-AzSqlDatabaseExecuteIndexRecommendation -ResourceGroup Group-6 -ServerName witest-eus -DatabaseName witestdb-eus -IndexRecommendationName nci_wi_Clusters_034590D0-0378-4AB9-96D5-C144B14F6A9B    
    Assert-AreEqual "Pending" $response[0].State

    
    $response = Stop-AzSqlDatabaseExecuteIndexRecommendation -ResourceGroup Group-6 -ServerName witest-eus -DatabaseName witestdb-eus -IndexRecommendationName nci_wi_Clusters_034590D0-0378-4AB9-96D5-C144B14F6A9B
    Assert-AreEqual "Active" $response[0].State
}

function ValidateResponse($response) 
{
    Assert-NotNull $response
    Assert-AreEqual 1 $response.Count        
    Assert-AreEqual "nci_wi_Clusters_034590D0-0378-4AB9-96D5-C144B14F6A9B" $response[0].Name
    Assert-AreEqual "Create" $response[0].Action
    Assert-AreEqual '07/21/2015 17:12:32' $response[0].Created
    Assert-AreEqual "NONCLUSTERED" $response[0].IndexType
    Assert-AreEqual '07/21/2015 17:12:32' $response[0].LastModified
    Assert-AreEqual "dbo" $response[0].Schema    
    Assert-AreEqual "Clusters" $response[0].Table
}