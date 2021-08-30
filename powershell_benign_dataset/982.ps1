
$SubscriptionId = ''

$primaryResourceGroupName = "myPrimaryResourceGroup-$(Get-Random)"
$primaryLocation = "westus2"

$secondaryResourceGroupName = "mySecondaryResourceGroup-$(Get-Random)"
$secondaryLocation = "eastus"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$primaryServerName = "primary-server-$(Get-Random)"
$secondaryServerName = "secondary-server-$(Get-Random)"

$databasename = "mySampleDatabase"

$primaryStartIp = "0.0.0.0"
$primaryEndIp = "0.0.0.0"
$secondaryStartIp = "0.0.0.0"
$secondaryEndIp = "0.0.0.0"


Set-AzContext -SubscriptionId $subscriptionId 


$primaryResourceGroup = New-AzResourceGroup -Name $primaryResourceGroupName -Location $primaryLocation
$secondaryResourceGroup = New-AzResourceGroup -Name $secondaryResourceGroupName -Location $secondaryLocation


$primaryServer = New-AzSqlServer -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryServer = New-AzSqlServer -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -Location $secondaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$primaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primaryStartIp -EndIpAddress $primaryEndIp
$secondaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondaryStartIp -EndIpAddress $secondaryEndIp


$database = New-AzSqlDatabase  -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"


$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $primaryResourceGroupName -ServerName $primaryServerName
$database | New-AzSqlDatabaseSecondary -PartnerResourceGroupName $secondaryResourceGroupName -PartnerServerName $secondaryServerName -AllowConnections "All"


$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryServerName
$database | Set-AzSqlDatabaseSecondary -PartnerResourceGroupName $primaryResourceGroupName -Failover


$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryServerName
$database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName -PartnerServerName $primaryServerName


$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryServerName
$secondaryLink = $database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName -PartnerServerName $primaryServerName
$secondaryLink | Remove-AzSqlDatabaseSecondary



