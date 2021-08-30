





























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
