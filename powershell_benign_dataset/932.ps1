

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount" 
$tableName = "table1"
$accountResourceName = $accountName + "/table/"
$tableResourceName = $accountName + "/table/" + $tableName
$tableResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/tables"


Read-Host -Prompt "List all tables in an account. Press Enter to continue"

Get-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a table in an account. Press Enter to continue"

Get-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName | Select-Object Properties