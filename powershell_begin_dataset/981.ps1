
$SubscriptionId = ''

$primaryResourceGroupName = "myPrimaryResourceGroup-$(Get-Random)"
$secondaryResourceGroupName = "mySecondaryResourceGroup-$(Get-Random)"
$primaryLocation = "westus2"
$secondaryLocation = "eastus"

$primaryServerName = "primary-server-$(Get-Random)"
$secondaryServerName = "secondary-server-$(Get-Random)"

$adminSqlLgin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$databaseName = "mySampleDatabase"

$primaryStartIp = "0.0.0.0"
$primaryEndIp = "0.0.0.0"
$secondaryStartIp = "0.0.0.0"
$secondaryEndIp = "0.0.0.0"

$primaryPoolName = "PrimaryPool"
$secondarypoolname = "SecondaryPool"


Set-AzContext -SubscriptionId $subscriptionId 


$primaryResourceGroup = New-AzResourceGroup -Name $primaryResourceGroupName -Location $primaryLocation
$secondaryResourceGroup = New-AzResourceGroup -Name $secondaryResourceGroupName -Location $secondaryLocation



$primaryServer = New-AzSqlServer -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLgin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryServer = New-AzSqlServer -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -Location $secondaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLgin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$primaryServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primaryStartIp -EndIpAddress $primaryEndIp
$secondaryServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondaryStartIp -EndIpAddress $secondaryEndIp


$primaryPool = New-AzSqlElasticPool -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -ElasticPoolName $primaryPoolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50
$secondaryPool = New-AzSqlElasticPool -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -ElasticPoolName $secondaryPoolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50


$database = New-AzSqlDatabase  -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -DatabaseName $databaseName `
    -ElasticPoolName $primaryPoolName


$database = Get-AzSqlDatabase -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -DatabaseName $databaseName
$database | New-AzSqlDatabaseSecondary -PartnerResourceGroupName $secondaryResourceGroupName `
    -PartnerServerName $secondaryServerName `
    -SecondaryElasticPoolName $secondaryPoolName `
    -AllowConnections "All"


$database = Get-AzSqlDatabase -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -DatabaseName $databaseName 
$database | Set-AzSqlDatabaseSecondary -PartnerResourceGroupName $primaryResourceGroupName -Failover

    

$database = Get-AzSqlDatabase -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -DatabaseName $databaseName
$database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName `
    -PartnerServerName $primaryServerName



