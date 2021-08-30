















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