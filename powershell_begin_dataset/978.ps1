

$subscriptionId = '<Subscription-ID>'
$randomIdentifier = $(Get-Random)
$resourceGroupName = "myResourceGroup-$randomIdentifier"
$location = "East US"
$adminLogin = "azureuser"
$password = "PWD27!"+(New-Guid).Guid
$serverName = "mysqlserver-$randomIdentifier"
$poolName = "myElasticPool"
$databaseName = "mySampleDatabase"
$drLocation = "West US"
$drServerName = "mysqlsecondary-$randomIdentifier"
$failoverGroupName = "failovergrouptutorial-$randomIdentifier"




$startIp = "0.0.0.0"
$endIp = "0.0.0.0"


Write-host "Resource group name is" $resourceGroupName 
Write-host "Password is" $password  
Write-host "Server name is" $serverName 
Write-host "DR Server name is" $drServerName 
Write-host "Failover group name is" $failoverGroupName



Set-AzContext -SubscriptionId $subscriptionId 


Write-host "Creating resource group..."
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{Owner="SQLDB-Samples"}
$resourceGroup


Write-host "Creating primary logical server..."
New-AzSqlServer -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -Location $location `
   -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
   -ArgumentList $adminLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
Write-host "Primary logical server = " $serverName


Write-host "Configuring firewall for primary logical server..."
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
Write-host "Firewall configured" 


Write-host "Creating a gen5 2 vCore database..."
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -DatabaseName $databaseName `
   -Edition "GeneralPurpose" `
   -VCore 2 `
   -ComputeGeneration Gen5 `
   -MinimumCapacity 1 `
   -SampleName "AdventureWorksLT"
$database


Write-host "Creating elastic pool..."
$elasticPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $poolName `
    -Edition "GeneralPurpose" `
    -vCore 2 `
    -ComputeGeneration Gen5
$elasticPool


Write-host "Creating elastic pool..."
$addDatabase = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -ElasticPoolName $poolName
$addDatabase


Write-host "Creating a secondary logical server in the failover region..."
New-AzSqlServer -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName `
   -Location $drLocation `
   -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
      -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
Write-host "Secondary logical server =" $drServerName


Write-host "Configuring firewall for secondary logical server..."
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName `
   -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
Write-host "Firewall configured" 


Write-host "Creating secondary elastic pool..."
$elasticPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $drServerName `
    -ElasticPoolName $poolName `
    -Edition "GeneralPurpose" `
    -vCore 2 `
    -ComputeGeneration Gen5
$elasticPool



Write-host "Creating failover group..." 
New-AzSqlDatabaseFailoverGroup `
  –ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -PartnerServerName $drServerName  `
   –FailoverGroupName $failoverGroupName `
   –FailoverPolicy Automatic `
   -GracePeriodWithDataLossHours 2
Write-host "Failover group created successfully." 


Write-host "Enumerating databases in elastic pool...." 
$FailoverGroup = Get-AzSqlDatabaseFailoverGroup `
                 -ResourceGroupName $resourceGroupName `
                 -ServerName $serverName `
                 -FailoverGroupName $failoverGroupName
$databases = Get-AzSqlElasticPoolDatabase `
               -ResourceGroupName $resourceGroupName `
               -ServerName $serverName `
               -ElasticPoolName $poolName
Write-host "Adding databases to failover group..." 
$failoverGroup = $failoverGroup | Add-AzSqlDatabaseToFailoverGroup `
                                  -Database $databases 
$failoverGroup


Write-host "Confirming the secondary server is secondary...." 
(Get-AzSqlDatabaseFailoverGroup `
   -FailoverGroupName $failoverGroupName `
   -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName).ReplicationRole


Write-host "Failing over failover group to the secondary..." 
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName `
   -FailoverGroupName $failoverGroupName
Write-host "Failover group failed over to" $drServerName 


Write-host "Confirming the secondary server is now primary" 
(Get-AzSqlDatabaseFailoverGroup `
   -FailoverGroupName $failoverGroupName `
   -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName).ReplicationRole


Write-host "Failing over failover group to the primary...." 
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -FailoverGroupName $failoverGroupName
Write-host "Failover group failed over to" $serverName 





