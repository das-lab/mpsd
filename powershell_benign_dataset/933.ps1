

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$tableName = "table1"
$tableThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/tables/settings"
$tableThroughputResourceName = $accountName + "/table/" + $tableName + "/throughput"


Get-AzResource -ResourceType $tableThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableThroughputResourceName | Select-Object Properties
