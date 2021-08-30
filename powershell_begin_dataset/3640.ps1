














function Test-CreateJobCredential
{
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-CreateJobCredentialWithDefaultParam $a1
		Test-CreateJobCredentialWithParentObject $a1
		Test-CreateJobCredentialWithParentResourceId $a1
		Test-CreateJobCredentialWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}



function Test-GetJobCredential
{
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-GetJobCredentialWithDefaultParam $a1
		Test-GetJobCredentialWithParentObject $a1
		Test-GetJobCredentialWithParentResourceId $a1
		Test-GetJobCredentialWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-UpdateJobCredential
{
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-UpdateJobCredentialWithDefaultParam $a1
		Test-UpdateJobCredentialWithInputObject $a1
		Test-UpdateJobCredentialWithResourceId $a1
		Test-UpdateJobCredentialWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-RemoveJobCredential
{
	$a1 = Create-ElasticJobAgentTestEnvironment

	try
	{
		Test-RemoveJobCredentialWithDefaultParam $a1
		Test-RemoveJobCredentialWithInputObject $a1
		Test-RemoveJobCredentialWithResourceId $a1
		Test-RemoveJobCredentialWithPiping $a1
	}
	finally
	{
		Remove-ResourceGroupForTest $a1
	}
}


function Test-CreateJobCredentialWithDefaultParam ($a1)
{
	
	$cn1 = Get-JobCredentialName
	$c1 = Get-ServerCredential

	
	$resp = New-AzSqlElasticJobCredential -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $cn1 -Credential $c1
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.CredentialName $cn1
	Assert-AreEqual $resp.UserName $c1.UserName
}


function Test-CreateJobCredentialWithParentObject ($a1)
{
	
	$cn1 = Get-JobCredentialName
	$c1 = Get-ServerCredential

	
	$resp = New-AzSqlElasticJobCredential -ParentObject $a1 -Name $cn1 -Credential $c1
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.CredentialName $cn1
	Assert-AreEqual $resp.UserName $c1.UserName
}


function Test-CreateJobCredentialWithParentResourceId ($a1)
{
	
	$cn1 = Get-JobCredentialName
	$c1 = Get-ServerCredential

	
	$resp = New-AzSqlElasticJobCredential -ParentResourceId $a1.ResourceId -Name $cn1 -Credential $c1
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.CredentialName $cn1
	Assert-AreEqual $resp.UserName $c1.UserName
}


function Test-CreateJobCredentialWithPiping ($a1)
{
	
	$cn1 = Get-JobCredentialName
	$c1 = Get-ServerCredential

	
	$resp = $a1 | New-AzSqlElasticJobCredential -Name $cn1 -Credential $c1
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.CredentialName $cn1
	Assert-AreEqual $resp.UserName $c1.UserName
}


function Test-UpdateJobCredentialWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$newCred = Get-Credential
	$resp = Set-AzSqlElasticJobCredential -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jc1.CredentialName -Credential $newCred
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $newCred.UserName
}


function Test-UpdateJobCredentialWithInputObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$newCred = Get-Credential
	$resp = Set-AzSqlElasticJobCredential -InputObject $jc1 -Credential $newCred
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $newCred.UserName
}


function Test-UpdateJobCredentialWithResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$newCred = Get-Credential
	$resp = Set-AzSqlElasticJobCredential -ResourceId $jc1.ResourceId -Credential $newCred
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $newCred.UserName
}


function Test-UpdateJobCredentialWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$newCred = Get-Credential
	$resp = $jc1 | Set-AzSqlElasticJobCredential -Credential $newCred
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $newCred.UserName
}


function Test-GetJobCredentialWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1

	
	$resp = Get-AzSqlElasticJobCredential -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jc1.CredentialName
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName

	
	$resp = Get-AzSqlElasticJobCredential -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobCredentialWithParentObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1

	
	$resp = Get-AzSqlElasticJobCredential -ParentObject $a1 -Name $jc1.CredentialName

	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName

	
	$resp = Get-AzSqlElasticJobCredential -ParentObject $a1
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobCredentialWithParentResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1

		
	$resp = Get-AzSqlElasticJobCredential -ParentResourceId $a1.ResourceId -Name $jc1.CredentialName
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName

	
	$resp = Get-AzSqlElasticJobCredential -ParentResourceId $a1.ResourceId
	Assert-True { $resp.Count -ge 2 }
}


function Test-GetJobCredentialWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1

		
	$resp = $a1 | Get-AzSqlElasticJobCredential -Name $jc1.CredentialName
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName

	
	$resp = $a1 | Get-AzSqlElasticJobCredential
	Assert-True { $resp.Count -ge 2 }
}


function Test-RemoveJobCredentialWithDefaultParam ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$resp = Remove-AzSqlElasticJobCredential -ResourceGroupName $a1.ResourceGroupName -ServerName $a1.ServerName -AgentName $a1.AgentName -Name $jc1.CredentialName
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName
}


function Test-RemoveJobCredentialWithInputObject ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$resp = Remove-AzSqlElasticJobCredential -InputObject $jc1
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName
}


function Test-RemoveJobCredentialWithResourceId ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1

	
	$resp = Remove-AzSqlElasticJobCredential -ResourceId $jc1.ResourceId
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName
}


function Test-RemoveJobCredentialWithPiping ($a1)
{
	
	$jc1 = Create-JobCredentialForTest $a1
	$jc2 = Create-JobCredentialForTest $a1

	
	$resp = $jc1 | Remove-AzSqlElasticJobCredential
	Assert-AreEqual $resp.ResourceGroupName $a1.ResourceGroupName
	Assert-AreEqual $resp.ServerName $a1.ServerName
	Assert-AreEqual $resp.AgentName $a1.AgentName
	Assert-AreEqual $resp.CredentialName $jc1.CredentialName
	Assert-AreEqual $resp.UserName $jc1.UserName

	
	$all = $a1 | Get-AzSqlElasticJobCredential
	$resp = $all | Remove-AzSqlElasticJobCredential
	Assert-True { $resp.Count -ge 1 }

	
	Assert-Throws { $a1 | Get-AzSqlElasticJobCredential -Name $jc1.CredentialName }
}