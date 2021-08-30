

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


