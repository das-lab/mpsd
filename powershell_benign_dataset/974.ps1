

$SubscriptionId = ''

$sourceResourceGroupName = "mySourceResourceGroup-$(Get-Random)"
$sourceResourceGroupLocation = "westus2"

$targetResourceGroupname = "myTargetResourceGroup-$(Get-Random)"
$targetResourceGroupLocation = "eastus"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$sourceServerName = "source-server-$(Get-Random)"
$targetServerName = "target-server-$(Get-Random)"

$sourceDatabaseName = "mySampleDatabase"
$targetDatabaseName = "CopyOfMySampleDatabase"

$sourceStartIp = "0.0.0.0"
$sourceEndIp = "0.0.0.0"
$targetStartIp = "0.0.0.0"
$targetEndIp = "0.0.0.0"


Set-AzContext -SubscriptionId $subscriptionId 


$sourceResourceGroup = New-AzResourceGroup -Name $sourceResourceGroupName -Location $sourceResourceGroupLocation
$targetResourceGroup = New-AzResourceGroup -Name $targetResourceGroupname -Location $targetResourceGroupLocation


$sourceResourceGroup = New-AzSqlServer -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -Location $sourceResourceGroupLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$targetResourceGroup = New-AzSqlServer -ResourceGroupName $targetResourceGroupname `
    -ServerName $targetServerName `
    -Location $targetResourceGroupLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$sourceServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $sourcestartip -EndIpAddress $sourceEndIp
$targetServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $targetResourceGroupname `
    -ServerName $targetServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $targetStartIp -EndIpAddress $targetEndIp


$sourceDatabase = New-AzSqlDatabase  -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -DatabaseName $sourceDatabaseName -RequestedServiceObjectiveName "S0"


$databaseCopy = New-AzSqlDatabaseCopy -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -DatabaseName $sourceDatabaseName `
    -CopyResourceGroupName $targetResourceGroupname `
    -CopyServerName $targetServerName `
    -CopyDatabaseName $targetDatabaseName 



