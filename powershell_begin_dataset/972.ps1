

$SubscriptionId = ''

$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$serverName = "server-$(Get-Random)"

$databaseName = "mySampleDatabase"

$startIp = "0.0.0.0"
$endIp = "0.0.0.0"


Set-AzContext -SubscriptionId $subscriptionId 


$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location


$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp


$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"


$MonitorParameters = @{
  ResourceId = "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/databases/$databaseName"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzMetric @MonitorParameters -DetailedOutput).MetricValues


$database = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $servername `
    -DatabaseName $databasename `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S1"


Add-AzMetricAlertRule -ResourceGroup $resourceGroupName `
    -Name "MySampleAlertRule" `
    -Location $location `
    -TargetResourceId "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/databases/$databaseName" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Action $(New-AzAlertRuleEmail -SendToServiceOwner)


