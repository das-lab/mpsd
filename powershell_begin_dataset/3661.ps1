














function Test-StartJob
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	
	$script = "SELECT 1"
	$s1 = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName
	$credential = Get-Credential $s1.SqlAdministratorLogin
	$jc1 = $a1 | New-AzSqlElasticJobCredential -Name (Get-UserName) -Credential $credential
	$tg1 = $a1 | New-AzSqlElasticJobTargetGroup -Name (Get-TargetGroupName)
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName
	$j1 = Create-JobForTest $a1
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $script

	try
	{
		
		$je = Start-AzSqlElasticJob -ResourceGroupName $j1.ResourceGroupName -ServerName $j1.ServerName -AgentName $j1.AgentName -JobName $j1.JobName
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId
		Assert-AreEqual 1 $je.JobVersion
		Assert-AreEqual Created $je.Lifecycle
		Assert-AreEqual Created $je.ProvisioningState

		
		$je = Start-AzSqlElasticJob -ParentObject $j1
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId
		Assert-AreEqual 1 $je.JobVersion
		Assert-AreEqual Created $je.Lifecycle
		Assert-AreEqual Created $je.ProvisioningState

		
		$je = Start-AzSqlElasticJob -ParentResourceId $j1.ResourceId
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId
		Assert-AreEqual 1 $je.JobVersion
		Assert-AreEqual Created $je.Lifecycle
		Assert-AreEqual Created $je.ProvisioningState

		
		$je = $j1 | Start-AzSqlElasticJob
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId
		Assert-AreEqual 1 $je.JobVersion
		Assert-AreEqual Created $je.Lifecycle
		Assert-AreEqual Created $je.ProvisioningState
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}

}


function Test-StartJobWait
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	
	$script = "SELECT 1"
	$s1 = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName
	$credential = Get-Credential $s1.SqlAdministratorLogin
	$jc1 = $a1 | New-AzSqlElasticJobCredential -Name (Get-UserName) -Credential $credential
	$tg1 = $a1 | New-AzSqlElasticJobTargetGroup -Name (Get-TargetGroupName)
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName
	$j1 = Create-JobForTest $a1
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $script

	try
	{
		
		$je = $j1 | Start-AzSqlElasticJob -Wait
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId
		Assert-AreEqual 1 $je.JobVersion
		Assert-AreEqual Succeeded $je.Lifecycle
		Assert-AreEqual Succeeded $je.ProvisioningState
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-StopJob
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	$script = "WAITFOR DELAY '00:10:00'"
	$s1 = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName
	$credential = Get-Credential $s1.SqlAdministratorLogin
	$jc1 = $a1 | New-AzSqlElasticJobCredential -Name (Get-UserName) -Credential $credential
	$tg1 = $a1 | New-AzSqlElasticJobTargetGroup -Name (Get-TargetGroupName)
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName
	$j1 = Create-JobForTest $a1
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $script

	
	$je = $j1 | Start-AzSqlElasticJob

	try
	{
		
		$resp = Stop-AzSqlElasticJob -ResourceGroupName $je.ResourceGroupName -ServerName $je.ServerName `
			-AgentName $je.AgentName -JobName $j1.JobName -JobExecutionId $je.JobExecutionId
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId

		
		$resp = Stop-AzSqlElasticJob -ParentObject $je
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId

		
		$resp = Stop-AzSqlElasticJob -ParentResourceId $je.ResourceId
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId

		
		$resp = $je | Stop-AzSqlElasticJob
		Assert-AreEqual $je.ResourceGroupName $j1.ResourceGroupName
		Assert-AreEqual $je.ServerName $j1.ServerName
		Assert-AreEqual $je.AgentName $j1.AgentName
		Assert-AreEqual $je.JobName $j1.JobName
		Assert-NotNull $je.JobExecutionId
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}

}


function Test-GetJobExecution
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	$script = "SELECT 1"
	$s1 = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName
	$credential = Get-Credential $s1.SqlAdministratorLogin
	$jc1 = $a1 | New-AzSqlElasticJobCredential -Name (Get-UserName) -Credential $credential
	$tg1 = $a1 | New-AzSqlElasticJobTargetGroup -Name (Get-TargetGroupName)
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName
	$j1 = Create-JobForTest $a1
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $script
	$je = $j1 | Start-AzSqlElasticJob -Wait

	try
	{
		
		$allExecutions = Get-AzSqlElasticJobExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName `
			-AgentName $a1.AgentName -Count 10
		$jobExecutions = Get-AzSqlElasticJobExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName `
			-AgentName $a1.AgentName -JobName $j1.JobName -Count 10
		$jobExecution = Get-AzSqlElasticJobExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName `
			-AgentName $a1.AgentName -JobName $j1.JobName -JobExecutionId $je.JobExecutionId

		
		Assert-AreEqual $je.ResourceGroupName $jobExecution.ResourceGroupName
		Assert-AreEqual $je.ServerName $jobExecution.ServerName
		Assert-AreEqual $je.AgentName $jobExecution.AgentName
		Assert-AreEqual $je.JobName $jobExecution.JobName
		Assert-AreEqual $je.JobExecutionId $jobExecution.JobExecutionId
		Assert-AreEqual $je.Lifecycle $jobExecution.Lifecycle
		Assert-AreEqual $je.ProvisioningState $jobExecution.ProvisioningState
		Assert-AreEqual $je.LastMessage $jobExecution.LastMessage
		Assert-AreEqual $je.CurrentAttemptStartTime $jobExecution.CurrentAttemptStartTime
		Assert-AreEqual $je.StartTime $jobExecution.StartTime
		Assert-AreEqual $je.EndTime $jobExecution.EndTime
		Assert-AreEqual $je.JobVersion $jobExecution.JobVersion

		
		$allExecutions = Get-AzSqlElasticJobExecution -ParentObject $a1 -Count 10
		$jobExecutions = Get-AzSqlElasticJobExecution -ParentObject $a1 -JobName $j1.JobName -Count 10
		$jobExecution = Get-AzSqlElasticJobExecution -ParentObject $a1 -JobName $j1.JobName -JobExecutionId $je.JobExecutionId

		
		Assert-AreEqual $je.ResourceGroupName $jobExecution.ResourceGroupName
		Assert-AreEqual $je.ServerName $jobExecution.ServerName
		Assert-AreEqual $je.AgentName $jobExecution.AgentName
		Assert-AreEqual $je.JobName $jobExecution.JobName
		Assert-AreEqual $je.JobExecutionId $jobExecution.JobExecutionId
		Assert-AreEqual $je.Lifecycle $jobExecution.Lifecycle
		Assert-AreEqual $je.ProvisioningState $jobExecution.ProvisioningState
		Assert-AreEqual $je.LastMessage $jobExecution.LastMessage
		Assert-AreEqual $je.CurrentAttemptStartTime $jobExecution.CurrentAttemptStartTime
		Assert-AreEqual $je.StartTime $jobExecution.StartTime
		Assert-AreEqual $je.EndTime $jobExecution.EndTime
		Assert-AreEqual $je.JobVersion $jobExecution.JobVersion

		
		$allExecutions = Get-AzSqlElasticJobExecution -ParentResourceId $a1.ResourceId -Count 10
		$jobExecutions = Get-AzSqlElasticJobExecution -ParentResourceId $a1.ResourceId -JobName $j1.JobName -Count 10
		$jobExecution = Get-AzSqlElasticJobExecution -ParentResourceId $a1.ResourceId -JobName $j1.JobName -JobExecutionId $je.JobExecutionId

		
		Assert-AreEqual $je.ResourceGroupName $jobExecution.ResourceGroupName
		Assert-AreEqual $je.ServerName $jobExecution.ServerName
		Assert-AreEqual $je.AgentName $jobExecution.AgentName
		Assert-AreEqual $je.JobName $jobExecution.JobName
		Assert-AreEqual $je.JobExecutionId $jobExecution.JobExecutionId
		Assert-AreEqual $je.Lifecycle $jobExecution.Lifecycle
		Assert-AreEqual $je.ProvisioningState $jobExecution.ProvisioningState
		Assert-AreEqual $je.LastMessage $jobExecution.LastMessage
		Assert-AreEqual $je.CurrentAttemptStartTime $jobExecution.CurrentAttemptStartTime
		Assert-AreEqual $je.StartTime $jobExecution.StartTime
		Assert-AreEqual $je.EndTime $jobExecution.EndTime
		Assert-AreEqual $je.JobVersion $jobExecution.JobVersion

		
		$allExecutions = $a1 | Get-AzSqlElasticJobExecution -Count 10
		$jobExecutions = $a1 | Get-AzSqlElasticJobExecution -JobName $j1.JobName -Count 10
		$jobExecution = $a1 | Get-AzSqlElasticJobExecution -JobName $j1.JobName -JobExecutionId $je.JobExecutionId

		
		Assert-AreEqual $je.ResourceGroupName $jobExecution.ResourceGroupName
		Assert-AreEqual $je.ServerName $jobExecution.ServerName
		Assert-AreEqual $je.AgentName $jobExecution.AgentName
		Assert-AreEqual $je.JobName $jobExecution.JobName
		Assert-AreEqual $je.JobExecutionId $jobExecution.JobExecutionId
		Assert-AreEqual $je.Lifecycle $jobExecution.Lifecycle
		Assert-AreEqual $je.ProvisioningState $jobExecution.ProvisioningState
		Assert-AreEqual $je.LastMessage $jobExecution.LastMessage
		Assert-AreEqual $je.CurrentAttemptStartTime $jobExecution.CurrentAttemptStartTime
		Assert-AreEqual $je.StartTime $jobExecution.StartTime
		Assert-AreEqual $je.EndTime $jobExecution.EndTime
		Assert-AreEqual $je.JobVersion $jobExecution.JobVersion

		
		$allExecutions = $a1 | Get-AzSqlElasticJobExecution -Count 10 -CreateTimeMin "2018-05-31T23:58:57" -CreateTimeMax "2018-07-31T23:58:57" -EndTimeMin "2018-06-30T23:58:57" -EndTimeMax "2018-07-31T23:58:57" -Active
		$jobExecutions = $a1 | Get-AzSqlElasticJobExecution -Count 10 -CreateTimeMin "2018-05-31T23:58:57" -CreateTimeMax "2018-07-31T23:58:57" -EndTimeMin "2018-06-30T23:58:57" -EndTimeMax "2018-07-31T23:58:57" -Active
		Assert-Null $allExecutions
		Assert-Null $jobExecutions
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-GetJobStepExecution
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	$script = "SELECT 1"
	$s1 = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName
	$credential = Get-Credential $s1.SqlAdministratorLogin
	$jc1 = $a1 | New-AzSqlElasticJobCredential -Name (Get-UserName) -Credential $credential
	$tg1 = $a1 | New-AzSqlElasticJobTargetGroup -Name (Get-TargetGroupName)
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName
	$j1 = Create-JobForTest $a1
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $script
	$je = $j1 | Start-AzSqlElasticJob -Wait

	try
	{
		
		$allStepExecutions = Get-AzSqlElasticJobStepExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -JobName $j1.JobName -JobExecutionId $je.JobExecutionId
		$stepExecution = Get-AzSqlElasticJobStepExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -JobName $j1.JobName -JobExecutionId $je.JobExecutionId -StepName $js1.StepName

		
		Assert-AreEqual $stepExecution.ResourceGroupName $a1.ResourceGroupName
		Assert-AreEqual $stepExecution.ServerName $a1.ServerName
		Assert-AreEqual $stepExecution.AgentName $a1.AgentName
		Assert-AreEqual $stepExecution.JobName $j1.JobName
		Assert-AreEqual $stepExecution.JobExecutionId $je.JobExecutionId
		Assert-AreEqual $stepExecution.StepName $js1.StepName

		
		$allStepExecutions = Get-AzSqlElasticJobStepExecution -ParentObject $je
		$stepExecution = Get-AzSqlElasticJobStepExecution -ParentObject $je -StepName $js1.StepName

		
		Assert-AreEqual $stepExecution.ResourceGroupName $a1.ResourceGroupName
		Assert-AreEqual $stepExecution.ServerName $a1.ServerName
		Assert-AreEqual $stepExecution.AgentName $a1.AgentName
		Assert-AreEqual $stepExecution.JobName $j1.JobName
		Assert-AreEqual $stepExecution.JobExecutionId $je.JobExecutionId
		Assert-AreEqual $stepExecution.StepName $js1.StepName


		
		$allStepExecutions = Get-AzSqlElasticJobStepExecution -ParentResourceId $je.ResourceId
		$stepExecution = Get-AzSqlElasticJobStepExecution -ParentResourceId $je.ResourceId -StepName $js1.StepName

		
		Assert-AreEqual $stepExecution.ResourceGroupName $a1.ResourceGroupName
		Assert-AreEqual $stepExecution.ServerName $a1.ServerName
		Assert-AreEqual $stepExecution.AgentName $a1.AgentName
		Assert-AreEqual $stepExecution.JobName $j1.JobName
		Assert-AreEqual $stepExecution.JobExecutionId $je.JobExecutionId
		Assert-AreEqual $stepExecution.StepName $js1.StepName

		
		$allStepExecutions = $je | Get-AzSqlElasticJobStepExecution
		$stepExecution = $je | Get-AzSqlElasticJobStepExecution -StepName $js1.StepName

		
		Assert-AreEqual $stepExecution.ResourceGroupName $a1.ResourceGroupName
		Assert-AreEqual $stepExecution.ServerName $a1.ServerName
		Assert-AreEqual $stepExecution.AgentName $a1.AgentName
		Assert-AreEqual $stepExecution.JobName $j1.JobName
		Assert-AreEqual $stepExecution.JobExecutionId $je.JobExecutionId
		Assert-AreEqual $stepExecution.StepName $js1.StepName

		
		$allStepExecutions = $je | Get-AzSqlElasticJobStepExecution -CreateTimeMin "2018-05-31T23:58:57" `
			-CreateTimeMax "2018-07-31T23:58:57" -EndTimeMin "2018-06-30T23:58:57" -EndTimeMax "2018-07-31T23:58:57" -Active
		Assert-Null $allStepExecutions
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-GetJobTargetExecution
{
	
	$a1 = Create-ElasticJobAgentTestEnvironment

	$script = "SELECT 1"
	$s1 = Get-AzSqlServer -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName
	$credential = Get-Credential $s1.SqlAdministratorLogin
	$jc1 = $a1 | New-AzSqlElasticJobCredential -Name (Get-UserName) -Credential $credential
	$tg1 = $a1 | New-AzSqlElasticJobTargetGroup -Name (Get-TargetGroupName)
	$tg1 | Add-AzSqlElasticJobTarget -ServerName $a1.ServerName -DatabaseName $a1.DatabaseName
	$j1 = Create-JobForTest $a1
	$js1 = Create-JobStepForTest $j1 $tg1 $jc1 $script
	$je = $j1 | Start-AzSqlElasticJob -Wait

	try
	{
		
		$allTargetExecutions = Get-AzSqlElasticJobTargetExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName `
			-AgentName $a1.AgentName -JobName $j1.JobName -JobExecutionId $je.JobExecutionId -Count 10
		$stepTargetExecutions = Get-AzSqlElasticJobTargetExecution -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName `
			-AgentName $a1.AgentName -JobName $j1.JobName -JobExecutionId $je.JobExecutionId -StepName $js1.StepName -Count 10

		
		$allTargetExecutions = Get-AzSqlElasticJobTargetExecution -ParentObject $je -Count 10
		$stepTargetExecutions = Get-AzSqlElasticJobTargetExecution -ParentObject $je -StepName $js1.StepName -Count 10

		
		$allTargetExecutions = Get-AzSqlElasticJobTargetExecution -ParentResourceId $je.ResourceId -Count 10
		$stepTargetExecutions = Get-AzSqlElasticJobTargetExecution -ParentResourceId $je.ResourceId -StepName $js1.StepName -Count 10

		
		$allTargetExecutions = $je | Get-AzSqlElasticJobTargetExecution -Count 10
		$stepTargetExecutions = $je | Get-AzSqlElasticJobTargetExecution -StepName $js1.StepName -Count 10

		$targetExecution = $stepTargetExecutions[0]

		
		Assert-AreEqual $targetExecution.ResourceGroupName $a1.ResourceGroupName
		Assert-AreEqual $targetExecution.ServerName $a1.ServerName
		Assert-AreEqual $targetExecution.AgentName $a1.AgentName
		Assert-AreEqual $targetExecution.JobName $j1.JobName
		Assert-NotNull  $targetExecution.JobExecutionId
		Assert-NotNull 	$targetExecution.StepName
		Assert-AreEqual $targetExecution.TargetServerName $a1.ServerName
		Assert-AreEqual $targetExecution.TargetDatabaseName $a1.DatabaseName

		
		$allTargetExecutions = $je | Get-AzSqlElasticJobTargetExecution -Count 10 -CreateTimeMin "2018-05-31T23:58:57" -CreateTimeMax "2018-07-31T23:58:57" -EndTimeMin "2018-06-30T23:58:57" -EndTimeMax "2018-07-31T23:58:57" -Active
		$stepTargetExecutions = $je | Get-AzSqlElasticJobTargetExecution -StepName $js1.StepName -Count 10 -CreateTimeMin "2018-05-31T23:58:57" -CreateTimeMax "2018-07-31T23:58:57" -EndTimeMin "2018-06-30T23:58:57" -EndTimeMax "2018-07-31T23:58:57" -Active
		Assert-Null $allTargetExecutions
		Assert-Null $stepTargetExecutions
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}