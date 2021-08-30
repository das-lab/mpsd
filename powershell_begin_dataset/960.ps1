
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$collectionName = "collection1"
$databaseThroughputResourceName = $accountName + "/mongodb/" + $databaseName + "/throughput"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$collectionThroughputResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName + "/throughput"
$collectionThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections/settings"


Get-AzResource -ResourceType $databaseThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseThroughputResourceName  | Select-Object Properties


Get-AzResource -ResourceType $collectionThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $collectionThroughputResourceName  | Select-Object Properties
