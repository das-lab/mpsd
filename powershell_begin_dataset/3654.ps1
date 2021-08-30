















function Test-ExportDatabase
{
	
    $testSuffix = 90063
    $createServer = $true
    $createDatabase = $true
    $createFirewallRule = $true
    $operationName = "Export"
    $succeeded = $true     
   
    Verify-ImportExport $testSuffix $createServer $createDatabase $createFirewallRule $operationName $succeeded
}

function Test-ImportDatabase
{
	
    $testSuffix = 90062
    $createServer = $true
    $createDatabase = $false
    $createFirewallRule = $true
    $operationName = "Import"
    $succeeded = $true

    Verify-ImportExport $testSuffix $createServer $createDatabase $createFirewallRule $operationName $succeeded
}

 function Verify-ImportExport($testSuffix, $createServer, $createDatabase, $createFirewallRule, $operationName, $succeeded)
 {
	
    $params = Get-SqlDatabaseImportExportTestEnvironmentParameters  $testSuffix
    $rg = New-AzResourceGroup -Name $params.rgname -Location $params.location
    $export = "Export"
    $import = "Import"

	try
	{       
        Assert-NotNull $params.storageKey
        Assert-NotNull $params.importBacpacUri
        Assert-NotNull $params.exportBacpacUri

        $password = $params.password
        $secureString = ($password | ConvertTo-SecureString -asPlainText -Force) 
        $credentials = new-object System.Management.Automation.PSCredential($params.userName, $secureString) 	
        if($createServer -eq $true){
            $server = New-AzSqlServer -ResourceGroupName  $params.rgname -ServerName $params.serverName -ServerVersion $params.version -Location $params.location -SqlAdministratorCredentials $credentials       
        }

        if($createDatabase -eq $true){
            $standarddb = New-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
        }
        
        if($createFirewallRule -eq $true){
            New-AzSqlServerFirewallRule -ResourceGroupName  $params.rgname -ServerName $params.serverName -AllowAllAzureIPs
        }

        $operationStatusLink = ""
                
        if($operationName -eq $export){
            
            $exportResponse = New-AzSqlDatabaseExport -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageKeyType $params.storageKeyType -StorageKey $params.storageKey -StorageUri $params.exportBacpacUri -AdministratorLogin $params.userName -AdministratorLoginPassword $secureString -AuthenticationType $params.authType
            Assert-NotNull $exportResponse
            $operationStatusLink = $exportResponse.OperationStatusLink        
            Assert-AreEqual $exportResponse.ResourceGroupName $params.rgname
            Assert-AreEqual $exportResponse.ServerName $params.serverName
            Assert-AreEqual $exportResponse.DatabaseName $params.databaseName
            Assert-AreEqual $exportResponse.StorageKeyType $params.storageKeyType
            Assert-Null $exportResponse.StorageKey
            Assert-AreEqual $exportResponse.StorageUri $params.exportBacpacUri
            Assert-AreEqual $exportResponse.AdministratorLogin $params.userName
            Assert-Null $exportResponse.AdministratorLoginPassword
            Assert-AreEqual $exportResponse.AuthenticationType $params.authType
        }

        if($operationName -eq $import){
            $importResponse = New-AzSqlDatabaseImport -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageKeyType $params.storageKeyType -StorageKey $params.storageKey -StorageUri $params.importBacpacUri -AdministratorLogin $params.userName -AdministratorLoginPassword $secureString -Edition $params.databaseEdition -ServiceObjectiveName $params.serviceObjectiveName -DatabaseMaxSizeBytes $params.databaseMaxSizeBytes -AuthenticationType $params.authType
            Assert-NotNull $importResponse
            $operationStatusLink = $importResponse.OperationStatusLink
            Assert-AreEqual $importResponse.ResourceGroupName $params.rgname
            Assert-AreEqual $importResponse.ServerName $params.serverName
            Assert-AreEqual $importResponse.DatabaseName $params.databaseName
            Assert-AreEqual $importResponse.StorageKeyType $params.storageKeyType
            Assert-Null $importResponse.StorageKey
            Assert-AreEqual $importResponse.StorageUri $params.importBacpacUri
            Assert-AreEqual $importResponse.AdministratorLogin $params.userName
            Assert-Null $importResponse.AdministratorLoginPassword
            Assert-AreEqual $importResponse.AuthenticationType $params.authType
            Assert-AreEqual $importResponse.Edition $params.databaseEdition
            Assert-AreEqual $importResponse.ServiceObjectiveName $params.serviceObjectiveName
            Assert-AreEqual $importResponse.DatabaseMaxSizeBytes $params.databaseMaxSizeBytes
        }
		
        Assert-NotNull $operationStatusLink		

        
        $statusInProgress = "InProgress"
        $statusSucceeded = "Succeeded"
        $status = "InProgress"

        if($succeeded -eq $true){
            Write-Output "Getting Status" 
            while($status -eq $statusInProgress){
                $statusResponse = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationStatusLink
                Write-Output "Import Export Status Message:" + $statusResponse.StatusMessage  
                Assert-AreEqual $statusResponse.OperationStatusLink $operationStatusLink
                $status = $statusResponse.Status
                 if($status -eq $statusInProgress){
                    Assert-NotNull $statusResponse.LastModifiedTime
                    Assert-NotNull $statusResponse.QueuedTime
                    Assert-NotNull $statusResponse.StatusMessage
                 }
            }
            Assert-AreEqual $status $statusSucceeded
            Write-Output "ImportExportStatus:" + $status 
        }      
    }
    finally
    {
       Remove-ResourceGroupForTest $rg
    }
}