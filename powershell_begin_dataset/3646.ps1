














function Test-CreateJob
{

	try
	{
		
		$a1 = Create-ElasticJobAgentTestEnvironment

		Test-CreateJobWithDefaultParam $a1
		Test-CreateJobWithParentObject $a1
		Test-CreateJobWithParentResourceId $a1
		Test-CreateJobWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-GetJob
{
	try
	{
			
		$a1 = Create-ElasticJobAgentTestEnvironment

		Test-GetJobWithDefaultParam $a1
		Test-GetJobWithParentObject $a1
		Test-GetJobWithParentResourceId $a1
		Test-GetJobWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-UpdateJob
{
	try
	{
		
		$a1 = Create-ElasticJobAgentTestEnvironment

		Test-UpdateJobWithDefaultParam $a1
		Test-UpdateJobWithInputObject $a1
		Test-UpdateJobWithResourceId $a1
		Test-UpdateJobWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-RemoveJob
{
	try
	{
			
		$a1 = Create-ElasticJobAgentTestEnvironment

		Test-RemoveJobWithDefaultParam $a1
		Test-RemoveJobWithInputObject $a1
		Test-RemoveJobWithResourceId $a1
		Test-RemoveJobWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-CreateJobWithDefaultParam($a1)
{
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Enable
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Description $jn1 -RunOnce
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Description $jn1 -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Interval "PT1M"

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Description $jn1 -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Description $jn1 -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Description $jn1 -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jn1 -Description $jn1 -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
	Assert-AreEqual $resp.Enabled $false 
}


function Test-CreateJobWithParentObject($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Enable
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Description $jn1 -RunOnce
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Description $jn1 -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Interval "PT1M"

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Description $jn1 -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Description $jn1 -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Description $jn1 -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentObject $a1 -Name $jn1 -Description $jn1 -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
	Assert-AreEqual $resp.Enabled $false 
}


function Test-CreateJobWithParentResourceId($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Enable
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Description $jn1 -RunOnce
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Description $jn1 -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Interval "PT1M"

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Description $jn1 -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Description $jn1 -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Description $jn1 -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = New-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $jn1 -Description $jn1 -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
	Assert-AreEqual $resp.Enabled $false 
}


function Test-CreateJobWithPiping($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Enable
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Description $jn1 -RunOnce
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Once"   
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Description $jn1 -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Interval "PT1M"

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Description $jn1 -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Description $jn1 -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Description $jn1 -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"
	Assert-AreEqual $resp.Enabled $false 

	
	$jn1 = Get-JobName
	$resp = $a1 | New-AzSqlElasticJob -Name $jn1 -Description $jn1 -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $jn1
	Assert-AreEqual $resp.Description $jn1
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
	Assert-AreEqual $resp.Enabled $false 
}


function Test-GetJobWithDefaultParam($a1)
{
	
	$j1 = Create-JobForTest $a1
	$j2 = Create-JobForTest $a1

	
	$resp = Get-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval

	
	$resp = Get-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobWithParentObject($a1)
{
	
	$j1 = Create-JobForTest $a1
	$j2 = Create-JobForTest $a1

	
	$resp = Get-AzSqlElasticJob -ParentObject $a1 -Name $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval

	
	$resp = Get-AzSqlElasticJob -ParentObject $a1
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobWithParentResourceId($a1)
{
	
	$j1 = Create-JobForTest $a1
	$j2 = Create-JobForTest $a1
	$j2 = Create-JobForTest $a1

	
	$resp = Get-AzSqlElasticJob -ParentResourceId $a1.ResourceId -Name $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval

	
	$resp = Get-AzSqlElasticJob -ParentResourceId $a1.ResourceId
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobWithPiping($a1)
{
	
	$j1 = Create-JobForTest $a1
	$j2 = Create-JobForTest $a1

	
	$resp = $a1 | Get-AzSqlElasticJob -Name $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval

	
	$resp = $a1 | Get-AzSqlElasticJob
	Assert-True { $resp.Count -ge 2 }
}


function Test-UpdateJobWithDefaultParam($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s
	$j1 = Create-JobForTest $a1

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Enable
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -StartTime $startTimeIso8601 -EndTime $endTimeIso8601
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	$respStartTimeIso8601 = Get-Date $resp.StartTime -format s
	$respEndTimeIso8601 = Get-Date $resp.EndTime -format s
	Assert-AreEqual $respStartTimeIso8601 $startTimeIso8601
	Assert-AreEqual $respEndTimeIso8601 $endTimeIso8601
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Description $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -RunOnce
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1M"

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Description $j1.JobName -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Description $j1.JobName -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Description $j1.JobName -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"

	
	$resp = Set-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Description $j1.JobName -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
}


function Test-UpdateJobWithInputObject($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s
	$j1 = Create-JobForTest $a1

		
	$resp = Set-AzSqlElasticJob -InputObject $j1 -Enable
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$resp = Set-AzSqlElasticJob -InputObject $j1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -StartTime $startTimeIso8601 -EndTime $endTimeIso8601
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	$respStartTimeIso8601 = Get-Date $resp.StartTime -format s
	$respEndTimeIso8601 = Get-Date $resp.EndTime -format s
	Assert-AreEqual $respStartTimeIso8601 $startTimeIso8601
	Assert-AreEqual $respEndTimeIso8601 $endTimeIso8601
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -Description $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -RunOnce
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1M"

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -Description $j1.JobName -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -Description $j1.JobName -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -Description $j1.JobName -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"

	
	$resp = Set-AzSqlElasticJob -InputObject $j1 -Description $j1.JobName -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
}


function Test-UpdateJobWithResourceId($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s

	$j1 = Create-JobForTest $a1

	
	$resp = $j1 | Set-AzSqlElasticJob -Enable
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$resp = $j1 | Set-AzSqlElasticJob
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = $j1 | Set-AzSqlElasticJob -StartTime $startTimeIso8601 -EndTime $endTimeIso8601
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	$respStartTimeIso8601 = Get-Date $resp.StartTime -format s
	$respEndTimeIso8601 = Get-Date $resp.EndTime -format s
	Assert-AreEqual $respStartTimeIso8601 $startTimeIso8601
	Assert-AreEqual $respEndTimeIso8601 $endTimeIso8601
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName

	
	$resp = $j1 | Set-AzSqlElasticJob -RunOnce
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 

	
	$resp = $j1 | Set-AzSqlElasticJob -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1M"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
}


function Test-UpdateJobWithPiping($a1)
{
	
	$startTime = Get-Date "2018-05-31T23:58:57"
	$endTime = $startTime.AddHours(5)
	$startTimeIso8601 =  Get-Date $startTime -format s
	$endTimeIso8601 =  Get-Date $endTime -format s
	$j1 = Create-JobForTest $a1

	
	$resp = $j1 | Set-AzSqlElasticJob -Enable
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $true 
	Assert-AreEqual $resp.Description ""

	
	$resp = $j1 | Set-AzSqlElasticJob
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = $j1 | Set-AzSqlElasticJob -StartTime $startTimeIso8601 -EndTime $endTimeIso8601
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	$respStartTimeIso8601 = Get-Date $resp.StartTime -format s
	$respEndTimeIso8601 = Get-Date $resp.EndTime -format s
	Assert-AreEqual $respStartTimeIso8601 $startTimeIso8601
	Assert-AreEqual $respEndTimeIso8601 $endTimeIso8601
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description ""

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName

	
	$resp = $j1 | Set-AzSqlElasticJob -RunOnce
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 

	
	$resp = $j1 | Set-AzSqlElasticJob -IntervalType Minute -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false 
	Assert-AreEqual $resp.Description $j1.JobName 
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1M"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Hour -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "PT1H"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Day -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1D"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Week -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1W"

	
	$resp = $j1 | Set-AzSqlElasticJob -Description $j1.JobName -IntervalType Month -IntervalCount 1
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Description $j1.JobName
	Assert-AreEqual $resp.ScheduleType "Recurring"
	Assert-AreEqual $resp.Interval "P1M"
}


function Test-RemoveJobWithDefaultParam($a1)
{
	$j1 = Create-JobForTest $a1

	
	$resp = Remove-AzSqlElasticJob -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $j1.JobName -Force
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval
}


function Test-RemoveJobWithInputObject($a1)
{
	$j1 = Create-JobForTest $a1

	
	$resp = Remove-AzSqlElasticJob -InputObject $j1 -Force
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval
}


function Test-RemoveJobWithResourceId($a1)
{
	$j1 = Create-JobForTest $a1

	
	$resp = Remove-AzSqlElasticJob -ResourceId $j1.ResourceId -Force
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval
}


function Test-RemoveJobWithPiping($a1)
{
	$j1 = Create-JobForTest $a1

	
	$resp = $j1 | Remove-AzSqlElasticJob -Force
	Assert-AreEqual $resp.JobName $j1.JobName
	Assert-AreEqual $resp.Enabled $false
	Assert-AreEqual $resp.ScheduleType "Once"
	Assert-Null $resp.Interval

	
	Assert-Throws { $a1 | Get-AzSqlElasticJob -Name $j1.JobName }
}