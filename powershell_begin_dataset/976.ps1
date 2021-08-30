

$SubscriptionId = ''

$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westeurope"

$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"

$serverName = "server-$(Get-Random)"

$databaseName = "myImportedDatabase"

$storageAccountName = "sqlimport$(Get-Random)"
$storageContainerName = "importcontainer$(Get-Random)"

$bacpacFilename = "sample.bacpac"

$startip = "0.0.0.0"
$endip = "0.0.0.0"


Set-AzContext -SubscriptionId $subscriptionId 


$resourcegroup = New-AzResourceGroup -Name $resourceGroupName -Location $location


$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
    -AccountName $storageAccountName `
    -Location $location `
    -Type "Standard_LRS"


$storageContainer = New-AzStorageContainer -Name $storageContainerName `
    -Context $(New-AzStorageContext -StorageAccountName $storageAccountName `
        -StorageAccountKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0])


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile $bacpacfilename


Set-AzStorageBlobContent -Container $storagecontainername `
    -File $bacpacFilename `
    -Context $(New-AzStorageContext -StorageAccountName $storageAccountName `
        -StorageAccountKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0])


$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp


$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0] `
    -StorageUri "https://$storageaccountname.blob.core.windows.net/$storageContainerName/$bacpacFilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S3" `
    -AdministratorLogin "$adminSqlLogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $password -AsPlainText -Force)


$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
[Console]::Write("Importing")
while ($importStatus.Status -eq "InProgress")
{
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write(".")
    Start-Sleep -s 10
}
[Console]::WriteLine("")
$importStatus


Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName  `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0"



