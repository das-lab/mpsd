














function Get-SqlAuditingTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-audit-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-audit-cmdlet-server" +$testSuffix;
			  databaseName = "sql-audit-cmdlet-db" + $testSuffix;
			  storageAccount = "auditcmdlets" +$testSuffix
		}
}


function Get-SqlBlobAuditingTestEnvironmentParameters ($testSuffix)
{
	$subscriptionId = (Get-AzContext).Subscription.Id
	return @{ rgname = "blob-audit-cmdlet-test-rg" + $testSuffix;
			  serverName = "blob-audit-cmdlet-server" + $testSuffix;
			  databaseName = "blob-audit-cmdlet-db" + $testSuffix;
			  storageAccount = "blobaudit" + $testSuffix
			  eventHubNamespace = "audit-cmdlet-event-hub-ns" + $testSuffix
			  workspaceName = "audit-cmdlet-workspace" +$testSuffix
			  storageAccountResourceId = "/subscriptions/" + $subscriptionId + "/resourceGroups/" + "blob-audit-cmdlet-test-rg" + $testSuffix + "/providers/Microsoft.Storage/storageAccounts/" + "blobaudit" + $testSuffix
		}
}



function Get-SqlThreatDetectionTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-td-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-td-cmdlet-server" +$testSuffix;
			  databaseName = "sql-td-cmdlet-db" + $testSuffix;
			  storageAccount = "tdcmdlets" +$testSuffix
			  }
}


function Get-SqlDataMaskingTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-dm-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-dm-cmdlet-server" +$testSuffix;
			  databaseName = "sql-dm-cmdlet-db" + $testSuffix;
			  userName = "testuser";
			  loginName = "testlogin";
			  pwd = "testp@ssMakingIt1007Longer";
			  table1="table1";
			  column1 = "column1";
			  columnInt = "columnInt";
			  table2="table2";
			  column2 = "column2";
			  columnFloat = "columnFloat"
			  }
}


function Create-AuditingTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlAuditingTestEnvironmentParameters $testSuffix
	Create-TestEnvironmentWithParams $params $location $serverVersion
}


function Create-BlobAuditingTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	Create-TestEnvironmentWithParams $params $location $serverVersion
	New-AzOperationalInsightsWorkspace -ResourceGroupName $params.rgname -Name $params.workspaceName -Sku "Standard" -Location "eastus"
	New-AzEventHubNamespace -ResourceGroupName $params.rgname -NamespaceName $params.eventHubNamespace -Location $location
}


function Create-AuditingClassicTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlAuditingTestEnvironmentParameters $testSuffix
	Create-ClassicTestEnvironmentWithParams $params $location $serverVersion
}


function Create-BlobAuditingClassicTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	Create-ClassicTestEnvironmentWithParams $params $location $serverVersion
}


function Create-ThreatDetectionTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix
	Create-TestEnvironmentWithParams $params $location $serverVersion
}


function Create-ThreatDetectionClassicTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix
	Create-ClassicTestEnvironmentWithParams $params $location $serverVersion
}


function Create-TestEnvironmentWithParams ($params, $location, $serverVersion)
{
	Create-BasicTestEnvironmentWithParams $params $location $serverVersion
	New-AzStorageAccount -StorageAccountName $params.storageAccount -ResourceGroupName $params.rgname -Location $location -Type Standard_GRS
	Wait-Seconds 10
}


function Create-InstanceTestEnvironmentWithParams ($params, $location)
{
	Create-BasicManagedTestEnvironmentWithParams $params $location

	New-AzureRmStorageAccount -StorageAccountName $params.storageAccount -ResourceGroupName $params.rgname -Location $location -Type Standard_GRS
}


function Create-ClassicTestEnvironmentWithParams ($params, $location, $serverVersion)
{
	Create-BasicTestEnvironmentWithParams $params $location $serverVersion
	try
	{
		New-AzResource -ResourceName $params.storageAccount -ResourceGroupName $params.rgname -ResourceType "Microsoft.ClassicStorage/StorageAccounts" -Location $location -Properties @{ AccountType = "Standard_GRS" } -ApiVersion "2014-06-01" -Force
	}
	catch
	{
		
	}
}


function Create-BasicTestEnvironmentWithParams ($params, $location, $serverVersion)
{
	New-AzResourceGroup -Name $params.rgname -Location $location
	$serverName = $params.serverName
	$serverLogin = "testusername"
	
	$serverPassword = "t357ingP@s5w0rd!Sec"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force))
	New-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName -Location $location -ServerVersion $serverVersion -SqlAdministratorCredentials $credentials
	New-AzSqlDatabase -DatabaseName $params.databaseName -ResourceGroupName $params.rgname -ServerName $params.serverName -Edition Basic
}


function Create-BasicManagedTestEnvironmentWithParams ($params, $location)
{
	New-AzureRmResourceGroup -Name $params.rgname -Location $location

	
	$vnetName = "cl_initial"
	$subnetName = "Cool"
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id
	$credentials = Get-ServerCredential
 	$licenseType = "BasePrice"
  	$storageSizeInGB = 32
 	$vCore = 16
 	$skuName = "GP_Gen4"
	$collation = "SQL_Latin1_General_CP1_CI_AS"

	$managedInstance = New-AzureRmSqlInstance -ResourceGroupName $params.rgname -Name $params.serverName `
 			-Location $location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-Vcore $vCore -SkuName $skuName

	New-AzureRmSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName -Collation $collation
}


function Create-DataMaskingTestEnvironment ($testSuffix)
{
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix
	$password = $params.pwd
    $secureString = ($password | ConvertTo-SecureString -asPlainText -Force)
    $credentials = new-object System.Management.Automation.PSCredential($params.loginName, $secureString)
	New-AzResourceGroup -Name $params.rgname -Location "West Central US"
    New-AzSqlServer -ResourceGroupName  $params.rgname -ServerName $params.serverName -ServerVersion "12.0" -Location "West Central US" -SqlAdministratorCredentials $credentials
	New-AzSqlServerFirewallRule -ResourceGroupName  $params.rgname -ServerName $params.serverName -StartIpAddress 0.0.0.0 -EndIpAddress 255.255.255.255 -FirewallRuleName "ddmRule"
	New-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -eq "Record")
	{
		$fullServerName = $params.serverName + ".database.windows.net"

		$uid = $params.userName
		$login = $params.loginName
		$pwd = $params.pwd

		
		$connectionString = "Server=$fullServerName;uid=$login;pwd=$pwd;Database=master;Integrated Security=False;"

		$connection = New-Object System.Data.SqlClient.SqlConnection
		$connection.ConnectionString = $connectionString
		try
		{
			$connection.Open()

			$query = "CREATE LOGIN $uid WITH PASSWORD = '$pwd';"
			$command = $connection.CreateCommand()
			$command.CommandText = $query
			$command.ExecuteReader()
		}
		catch
		{
			
		}
		finally
		{
			$connection.Close()
		}

		
		$databaseName=$params.databaseName
		$connectionString = "Server=$fullServerName;uid=$login;pwd=$pwd;Database=$databaseName;Integrated Security=False;"

		$connection = New-Object System.Data.SqlClient.SqlConnection
		$connection.ConnectionString = $connectionString
		try
		{
			$connection.Open()

			$table1 = $params.table1
			$column1 = $params.column1
			$columnInt = $params.columnInt

			$table2 = $params.table2
			$column2 = $params.column2
			$columnFloat = $params.columnFloat

			$query = "CREATE TABLE $table1 ($column1 NVARCHAR(20)NOT NULL, $columnInt INT);CREATE TABLE $table2 ($column2 NVARCHAR(20)NOT NULL, $columnFloat DECIMAL(6,3));CREATE USER $uid FOR LOGIN $uid;"
			$command = $connection.CreateCommand()
			$command.CommandText = $query
			$command.ExecuteReader()
		}
		catch
		{
			
		}
		finally
		{
			$connection.Close()
		}
	}
}


function Create-ElasticJobAgentTestEnvironment ()
{
	$location = Get-Location "Microsoft.Sql" "operations" "West US 2"
	$rg1 = Create-ResourceGroupForTest
	$s1 = Create-ServerForTest $rg1 $location
	$s1fw = $s1 | New-AzSqlServerFirewallRule -AllowAllAzureIPs 
	$db1 = Create-DatabaseForTest $s1
	$agent = Create-AgentForTest $db1
	return $agent
}


function Create-ElasticPoolForTest ($server)
{
	$epName = Get-ElasticPoolName
	$ep = New-AzSqlElasticPool -ResourceGroupName  $server.ResourceGroupName -ServerName $server.ServerName -ElasticPoolName $epName
	return $ep
}



function Get-SqlServerKeyVaultKeyTestEnvironmentParameters ()
{
	
	return @{ rgName = Get-ResourceGroupName;
			  serverName = Get-ServerName;
			  databaseName = Get-DatabaseName;
			  keyId = "https://akvtdekeyvaultcl.vault.azure.net/keys/key1/738a177a3b0d45e98d366fdf738840e8";
			  serverKeyName = "akvtdekeyvaultcl_key1_738a177a3b0d45e98d366fdf738840e8";
			  vaultName = "akvtdekeyvaultcl";
			  keyName = "key1"
			  location = "westcentralus";
			  }
}


function Create-ServerKeyVaultKeyTestEnvironment ($params)
{
	
	$rg = New-AzResourceGroup -Name $params.rgname -Location $params.location -Force

	
	$serverLogin = "testusername"
	
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force))
	$server = New-AzSqlServer -ResourceGroupName  $rg.ResourceGroupName -ServerName $params.serverName -Location $params.location -ServerVersion "12.0" -SqlAdministratorCredentials $credentials -AssignIdentity
	Assert-AreEqual $server.ServerName $params.serverName

	
	$db = New-AzSqlDatabase -ResourceGroupName $rg.ResourceGroupName -ServerName $server.ServerName -DatabaseName $params.databaseName
	Assert-AreEqual $db.DatabaseName $params.databaseName

	
	Set-AzKeyVaultAccessPolicy -VaultName $params.vaultName -ObjectId $server.Identity.PrincipalId -PermissionsToKeys get, list, wrapKey, unwrapKey

	
	return $rg
}



function Get-ManagedInstanceForTdeTest ($params)
{
	
	$rg = Create-ResourceGroupForTest
	$vnetName = "cl_initial"
	$subnetName = "Cool"

	
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName $rg.Location
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id

	$managedInstance = Create-ManagedInstanceForTest $rg $subnetId
	Set-AzKeyVaultAccessPolicy -VaultName $params.vaultName -ObjectId $managedInstance.Identity.PrincipalId -PermissionsToKeys get, list, wrapKey, unwrapKey

	return $managedInstance
}


function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ServerName
{
    return getAssetName
}


function Get-UserName
{
	return getAssetName
}


function Get-DatabaseName
{
    return getAssetName
}


function Get-ShardMapName
{
	return getAssetName
}


function Get-AgentName
{
	return getAssetName
}


function Get-TargetGroupName
{
	return getAssetName
}


function Get-JobCredentialName
{
	return getAssetName
}


function Get-JobName
{
	return getAssetName
}


function Get-JobStepName
{
	return getAssetName
}


function Get-SchemaName
{
	return getAssetName
}


function Get-TableName
{
	return getAssetname
}


function Get-ElasticPoolName
{
    return getAssetName
}


function Get-FailoverGroupName
{
    return getAssetName
}


function Get-VirtualNetworkRuleName
{
    return getAssetName
}


function Get-ServerDnsAliasName
{
    return getAssetName
}


function Get-ManagedInstanceName
{
    return getAssetName
}


function Get-ManagedDatabaseName
{
    return getAssetName
}


function Get-VNetName
{
    return getAssetName
}


function Get-SqlTestMode {
    try {
        $testMode = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode;
        $testMode = $testMode.ToString();
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            $testMode = 'Record';
        } else {
            throw;
        }
    }

    return $testMode
}


function Get-ProviderLocation($provider)
{
	if ((Get-SqlTestMode) -ne 'Playback')
	{
		$namespace = $provider.Split("/")[0]
		if($provider.Contains("/"))
		{
			$type = $provider.Substring($namespace.Length + 1)
			$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

			if ($location -eq $null)
			{
				return "East US"
			}
            else
			{
				return $location.Locations[0]
			}
		}

		return "East US"
	}

	return "East US"
}


function Create-ResourceGroupForTest ($location = "westcentralus")
{
	$rgName = Get-ResourceGroupName

	$rg = New-AzResourceGroup -Name $rgName -Location $location

	return $rg
}


function Remove-ResourceGroupForTest ($rg)
{
	Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force
}


function Get-ServerCredential
{
	$serverLogin = "testusername"
	
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force))
	return $credentials
}


function Get-Credential ($serverLogin)
{
	if ($serverLogin -eq $null)
	{
		$serverLogin = Get-UserName
	}
	
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force))
	return $credentials
}


function Create-ServerForTest ($resourceGroup, $location = "Japan East")
{
	$serverName = Get-ServerName
	$credentials = Get-ServerCredential

	$server = New-AzSqlServer -ResourceGroupName  $resourceGroup.ResourceGroupName -ServerName $serverName -Location $location -SqlAdministratorCredentials $credentials
	return $server
}


function Remove-ServerForTest ($server)
{
	$server | Remove-AzSqlServer -Force
}


function Create-DatabaseForTest ($server)
{
	$dbName = Get-DatabaseName
	$db = New-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -DatabaseName $dbName -Edition Standard -MaxSizeBytes 250GB -RequestedServiceObjectiveName S0
	return $db
}


function Create-AgentForTest ($db)
{
	$agentName = Get-AgentName
	return New-AzSqlElasticJobAgent -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName -AgentName $agentName
}


function Create-JobCredentialForTest ($a)
{
	$credentialName = Get-JobCredentialName
	$credential = Get-ServerCredential

	$jobCredential = New-AzSqlElasticJobCredential -ResourceGroupName $a.ResourceGroupName -ServerName $a.ServerName -AgentName $a.AgentName -CredentialName $credentialName -Credential $credential
	return $jobCredential
}


function Create-TargetGroupForTest ($a)
{
	$targetGroupName = Get-TargetGroupName
	$tg = New-AzSqlElasticJobTargetGroup -ResourceGroupName $a.ResourceGroupName -ServerName $a.ServerName -AgentName $a.AgentName -TargetGroupName $targetGroupName
	return $tg
}


function Create-JobForTest ($a, $enabled = $false)
{
	$jobName = Get-JobName
	$job = New-AzSqlElasticJob -ResourceGroupName $a.ResourceGroupName -ServerName $a.ServerName -AgentName $a.AgentName -Name $jobName
	return $job
}


function Create-JobStepForTest ($j, $tg, $c, $ct)
{
	$jobStepName = Get-JobStepName
	$jobStep = Add-AzSqlElasticJobStep -ResourceGroupName $j.ResourceGroupName -ServerName $j.ServerName -AgentName $j.AgentName -JobName $j.jobName -Name $jobStepName -TargetGroupName $tg.TargetGroupName -CredentialName $c.CredentialName -CommandText $ct
	return $jobStep
}



function Remove-ThreatDetectionTestEnvironment ($testSuffix)
{
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix
	Remove-AzResourceGroup -Name $params.rgname -Force
}


function Remove-AuditingTestEnvironment ($testSuffix)
{
	$params = Get-SqlAuditingTestEnvironmentParameters $testSuffix
	Remove-AzResourceGroup -Name $params.rgname -Force
}


function Remove-BlobAuditingTestEnvironment ($testSuffix)
{
	$params = Get-SqlBlobAuditingTestEnvironmentParameters $testSuffix
	Remove-AzResourceGroup -Name $params.rgname -Force
}


function Remove-DataMaskingTestEnvironment ($testSuffix)
{
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix
	Remove-AzResourceGroup -Name $params.rgname -Force
}


function Get-SqlDatabaseImportExportTestEnvironmentParameters ($testSuffix)
{
    $databaseName = "sql-ie-cmdlet-db" + $testSuffix;
    
    $password = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateName("IEp@ssw0rd", "CallSite.Target");
    
    $exportBacpacUri = "http://test.blob.core.windows.net/bacpacs"
    $importBacpacUri = "http://test.blob.core.windows.net/bacpacs/test.bacpac"
    $storageKey = "StorageKey"

    $testMode = [System.Environment]::GetEnvironmentVariable("AZURE_TEST_MODE")
    if($testMode -eq "Record"){
        $exportBacpacUri = [System.Environment]::GetEnvironmentVariable("TEST_EXPORT_BACPAC")
        $importBacpacUri = [System.Environment]::GetEnvironmentVariable("TEST_IMPORT_BACPAC")
        $storageKey = [System.Environment]::GetEnvironmentVariable("TEST_STORAGE_KEY")

       if ([System.string]::IsNullOrEmpty($exportBacpacUri)){
          throw "The TEST_EXPORT_BACPAC environment variable should point to a bacpac that has been uploaded to Azure blob storage ('e.g.' https://test.blob.core.windows.net/bacpacs/empty.bacpac)"
       }
       if ([System.string]::IsNullOrEmpty($importBacpacUri)){
          throw "The  TEST_IMPORT_BACPAC environment variable should point to an Azure blob storage ('e.g.' https://test.blob.core.windows.net/bacpacs)"
       }
       if ([System.string]::IsNullOrEmpty($storageKey)){
          throw "The  TEST_STORAGE_KEY environment variable should point to a valid storage key for an existing Azure storage account"
       }
    }

	return @{
              rgname = "sql-ie-cmdlet-test-rg" +$testSuffix;
              serverName = "sql-ie-cmdlet-server" +$testSuffix;
              databaseName = $databaseName;
              userName = "testuser";
              firewallRuleName = "sql-ie-fwrule" +$testSuffix;
              password = $password;
              storageKeyType = "StorageAccessKey";
              storageKey = $storageKey;
              exportBacpacUri = $exportBacpacUri + "/" + $databaseName + ".bacpac";
              importBacpacUri = $importBacpacUri;
              location = "Australia East";
              version = "12.0";
              databaseEdition = "Standard";
              serviceObjectiveName = "S0";
              databaseMaxSizeBytes = "5000000";
              authType = "Sql";
             }
}


function Get-SyncGroupName
{
    return getAssetName
}


function Get-SyncMemberName
{
    return getAssetName
}


function Get-SyncAgentName
{
    return getAssetName
}


function Get-SqlSyncGroupTestEnvironmentParameters ()
{
    return @{ intervalInSeconds = 300;
              conflictResolutionPolicy = "HubWin";
              }
}


function Get-SqlSyncMemberTestEnvironmentParameters ()
{
     return @{ syncDirection = "Bidirectional";
               databaseType = "AzureSqlDatabase";
               }
}


function Get-DNSNameBasedOnEnvironment ()
{
     $connectingString = [System.Environment]::GetEnvironmentVariable("TEST_CSM_ORGID_AUTHENTICATION")
     $parsedString = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::ParseConnectionString($connectingString)
     $environment = $parsedString[[Microsoft.Rest.ClientRuntime.Azure.TestFramework.ConnectionStringKeys]::EnvironmentKey]
     if ($environment -eq "Dogfood"){
         return ".sqltest-eg1.mscds.com"
     }
     return ".database.windows.net"
}


function Create-ManagedInstanceForTest ($resourceGroup, $subnetId)
{
	$managedInstanceName = Get-ManagedInstanceName
	$credentials = Get-ServerCredential
 	$vCore = 16
 	$skuName = "GP_Gen4"

	$managedInstance = New-AzSqlInstance -ResourceGroupName $resourceGroup.ResourceGroupName -Name $managedInstanceName `
 			-Location $resourceGroup.Location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-Vcore $vCore -SkuName $skuName -AssignIdentity

	return $managedInstance
}


function Create-ManagedInstanceInInstancePoolForTest ($instancePool)
{
    $managedInstanceName = Get-ManagedInstanceName
    $credentials = Get-ServerCredential
    $vCore = 2
    $managedInstance = $instancePool | New-AzSqlInstance -Name $managedInstanceName -VCore $vCore -AdministratorCredential $credentials -StorageSizeInGb 32 -PublicDataEndpointEnabled
    return $managedInstance
}

function Remove-ManagedInstancesInInstancePool($instancePool)
{
    $instancePool | Get-AzSqlInstance | Remove-AzSqlInstance -Force
}


function Get-InstancePoolTestProperties()
{
    $tags = @{ instance="Pools" };
    $instancePoolTestProperties = @{
        resourceGroup = "instancePoolCSSdemo"
        name = "cssinstancepool0"
        subnetName = "InstancePool"
        vnetName = "vnet-cssinstancepool0"
        tags = $tags
        computeGen = "Gen5"
        edition = "GeneralPurpose"
        location = "canadacentral"
        licenseType = "LicenseIncluded"
        vCores = 16
    }
    return $instancePoolTestProperties
}


function Create-InstancePoolForTest()
{
    $props = Get-InstancePoolTestProperties
    $virtualNetwork = CreateAndGetVirtualNetworkForManagedInstance $props.vnetName $props.subnetName $props.location $props.resourceGroup
    $subnetId = $virtualNetwork.Subnets.where({ $_.Name -eq $props.subnetName })[0].Id
    $instancePool = New-AzSqlInstancePool -ResourceGroupName $props.resourceGroup -Name $props.name `
                -Location $props.location -SubnetId $subnetId -VCore $props.vCores `
                -Edition $props.Edition -ComputeGeneration $props.computeGen `
                -LicenseType $props.licenseType -Tag $props.tags
    return $instancePool
}


function CreateAndGetVirtualNetworkForManagedInstance ($vnetName, $subnetName, $location = "westcentralus", $resourceGroupName = "cl_one")
{
	$vNetAddressPrefix = "10.0.0.0/16"
	$defaultSubnetAddressPrefix = "10.0.0.0/24"

	try {
		$getVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
		return $getVnet
	} catch {
		$virtualNetwork = New-AzVirtualNetwork `
							-ResourceGroupName $resourceGroupName `
							-Location $location `
							-Name $vNetName `
							-AddressPrefix $vNetAddressPrefix
 		$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
								-Name $subnetName `
								-AddressPrefix $defaultSubnetAddressPrefix `
								-VirtualNetwork $virtualNetwork
 		$virtualNetwork | Set-AzVirtualNetwork
 		$routeTableMiManagementService = New-AzRouteTable `
								-Name 'myRouteTableMiManagementService' `
								-ResourceGroupName $resourceGroupName `
								-location $location
 		Set-AzVirtualNetworkSubnetConfig `
								-VirtualNetwork $virtualNetwork `
								-Name $subnetName `
								-AddressPrefix $defaultSubnetAddressPrefix `
								-RouteTable $routeTableMiManagementService | `
							Set-AzVirtualNetwork
 		Get-AzRouteTable `
								-ResourceGroupName $resourceGroupName `
								-Name "myRouteTableMiManagementService" `
								| Add-AzRouteConfig `
								-Name "ToManagedInstanceManagementService" `
								-AddressPrefix 0.0.0.0/0 `
								-NextHopType "Internet" `
								| Set-AzRouteTable

		$getVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
		return $getVnet
	}
}