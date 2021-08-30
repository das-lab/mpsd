
$SubscriptionId = ''

$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"

$poolName = "MySamplePool"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$serverName = "server-$(Get-Random)"

$firstDatabaseName = "myFirstSampleDatabase"
$secondDatabaseName = "mySecondSampleDatabase"

$startIp = "0.0.0.0"
$endIp = "0.0.0.0"


Set-AzContext -SubscriptionId $subscriptionId 


$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location


$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$elasticPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $poolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50


$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp


$firstDatabase = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $firstDatabaseName `
    -ElasticPoolName $poolName
$secondDatabase = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $secondDatabaseName `
    -ElasticPoolName $poolName


$monitorparameters = @{
  ResourceId = "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/elasticPools/$poolName"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzMetric @monitorparameters -DetailedOutput).MetricValues


$elasticPool = Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $poolName `
    -Edition "Standard" `
    -Dtu 100 `
    -DatabaseDtuMin 20 `
    -DatabaseDtuMax 100


Add-AzMetricAlertRule -ResourceGroup $resourceGroupName `
    -Name "mySampleAlertRule" `
    -Location $location `
    -TargetResourceId "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/elasticPools/$poolName" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Action $(New-AzAlertRuleEmail -SendToServiceOwner)


