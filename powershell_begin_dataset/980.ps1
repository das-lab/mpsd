

$SubscriptionId = ''

$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "southcentralus"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$serverName = "server-$(Get-Random)"

$databaseName = "mySampleDatabase"

$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

$storageAccountName = $("sql$(Get-Random)")

$notificationEmailReceipient = "changeto@your.email;changeto@your.email"


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
    -DatabaseName $databaseName -RequestedServiceObjectiveName "S0"
    

$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
    -AccountName $storageAccountName `
    -Location $location `
    -Type "Standard_LRS"


Set-AzSqlDatabaseAuditing -State Enabled `
    -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -StorageAccountName $storageAccountName 


Set-AzSqlDatabaseThreatDetectionPolicy -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -StorageAccountName $storageAccountName `
    -NotificationRecipientsEmails $notificationEmailReceipient `
    -EmailAdmins $False


