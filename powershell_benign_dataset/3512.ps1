
function Test-DataLakeAnalyticsJobRelationships
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$location = "West US"
	)
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
		$nowTime = $accountCreated.CreationTime
        
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(30000)
			Assert-False {$i -eq 60} "dataLakeAnalytics accounts not in succeeded state even after 30 min."
		}

		
		
		[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(300000)

		
		$guidForJob = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("relationTest01")
		
		
		$guidForJobRecurrence = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("relationTest02")
		$guidForJobPipeline = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("relationTest03")
		$guidForJobRun = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("relationTest04")
		$pipelineName = getAssetName
		$recurrenceName = getAssetName
		$pipelineUri = "https://begoldsm.contoso.com/jobs"

		[Microsoft.Azure.Commands.DataLakeAnalytics.Models.DataLakeAnalyticsClient]::JobIdQueue.Enqueue($guidForJob)
		$jobInfo = Submit-AdlJob `
			-AccountName $accountName `
			-Name "TestJob" `
			-Script "DROP DATABASE IF EXISTS foo; CREATE DATABASE foo;" `
			-PipelineId $guidForJobPipeline `
			-RecurrenceId $guidForJobRecurrence `
			-RecurrenceName $recurrenceName `
			-PipelineName $pipelineName `
			-PipelineUri $pipelineUri `
			-RunId $guidForJobRun

		
		$jobInfo = Wait-AdlJob -Account $accountName -JobId $jobInfo.JobId
		
		Assert-NotNull {$jobInfo}
		Assert-AreEqual $guidForJobRecurrence $jobInfo.Related.RecurrenceId
		Assert-AreEqual $guidForJobPipeline $jobInfo.Related.PipelineId
		Assert-AreEqual $guidForJobRun $jobInfo.Related.RunId
		Assert-AreEqual $pipelineName $jobInfo.Related.PipelineName
		Assert-AreEqual $recurrenceName $jobInfo.Related.RecurrenceName
		Assert-AreEqual $pipelineUri $jobInfo.Related.PipelineUri

		
		$jobList = Get-AdlJob -Account $accountName -PipelineId $guidForJobPipeline
		Assert-True {$jobList.Count -ge 1}

		$jobList = Get-AdlJob -Account $accountName -RecurrenceId $guidForJobRecurrence
		Assert-True {$jobList.Count -ge 1}

		
		$recurrenceList = Get-AdlJobRecurrence -Account $accountName
		Assert-True {$recurrenceList.Count -ge 1}

		$recurrence = Get-AdlJobRecurrence -Account $accountName -RecurrenceId $guidForJobRecurrence
		Assert-AreEqual $recurrenceName $recurrence.RecurrenceName
		Assert-AreEqual $guidForJobRecurrence $recurrence.RecurrenceId

		$pipelineList = Get-AdlJobPipeline -Account $accountName
		Assert-True {$pipelineList.Count -ge 1}

		$pipeline = Get-AdlJobPipeline -Account $accountName -PipelineId $guidForJobPipeline
		Assert-AreEqual $pipelineName $pipeline.PipelineName
		Assert-AreEqual $guidForJobPipeline $pipeline.PipelineId
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeAnalyticsComputePolicy
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$location = "West US"
	)
	
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlAnalyticsAccount -Name $accountName}

		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location

		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Analytics account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}

		
		$userPolicyObjectId = "8ce05900-7a9e-4895-b3f0-0fbcee507803"
		$userPolicyName = getAssetName
		$groupPolicyObjectId = "0583cfd7-60f5-43f0-9597-68b85591fc69"
		$groupPolicyName = getAssetName

		
		Assert-AreEqual 0 $accountCreated.ComputePolicies.Count 		

		
		Assert-Throws {New-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName  $accountName -Name $userPolicyName -ObjectId $userPolicyObjectId -ObjectType "User"}

		
		New-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName  $accountName -Name $userPolicyName -ObjectId $userPolicyObjectId -ObjectType "User" -MaxDegreeOfParallelismPerJob 2

		
		New-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $groupPolicyName -ObjectId $groupPolicyObjectId -ObjectType "Group" -MaxDegreeOfParallelismPerJob 2 -MinPriorityPerJob 2

		
		$policyResult = Get-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName $accountName

		Assert-AreEqual 2 $policyResult.Count

		
		$singlePolicy = Get-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $userPolicyName
		Assert-AreEqual $userPolicyName $singlePolicy.Name
		Assert-AreEqual 2 $singlePolicy.MaxDegreeOfParallelismPerJob

		
		Assert-Throws {Update-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName  $accountName -Name $userPolicyName}

		
		Update-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName  $accountName -Name $userPolicyName -MinPriorityPerJob 2

		
		$singlePolicy = Get-AdlAnalyticsComputePolicy -ResourceGroupName $resourceGroupName -AccountName $accountName -Name $userPolicyName
		Assert-AreEqual $userPolicyName $singlePolicy.Name
		Assert-AreEqual 2 $singlePolicy.MaxDegreeOfParallelismPerJob
		Assert-AreEqual 2 $singlePolicy.MinPriorityPerJob

		
		Remove-AdlAnalyticsComputePolicy -AccountName $accountName -Name $userPolicyName

		
		Assert-Throws {Get-AdlAnalyticsComputePolicy -AccountName $accountName -Name $userPolicyName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeAnalyticsFirewall
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$location = "West US"
	)
	
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlAnalyticsAccount -Name $accountName}

		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location

		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Analytics account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}

		
		Assert-AreEqual "Disabled" $accountCreated.FirewallState 
		
		
		

		$accountSet = Set-AdlAnalyticsAccount -Name $accountName -FirewallState "Enabled" -AllowAzureIpState "Enabled"

		Assert-AreEqual "Enabled" $accountSet.FirewallState 
		
		
		

		$firewallRuleName = getAssetName
		$startIp = "127.0.0.1"
		$endIp = "127.0.0.2"
		
		Add-AdlAnalyticsFirewallRule -AccountName $accountName -Name $firewallRuleName -StartIpAddress $startIp -EndIpAddress $endIp

		
		$result = Get-AdlAnalyticsFirewallRule -AccountName $accountName -Name $firewallRuleName
		Assert-AreEqual $firewallRuleName $result.Name
		Assert-AreEqual $startIp $result.StartIpAddress
		Assert-AreEqual $endIp $result.EndIpAddress

		
		Remove-AdlAnalyticsFirewallRule -AccountName $accountName -Name $firewallRuleName

		
		Assert-Throws {Get-AdlAnalyticsFirewallRule -AccountName $accountName -Name $firewallRuleName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeAnalyticsAccount
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$secondDataLakeAccountName = (Get-DataLakeStoreAccountName),
		$blobAccountName,
		$blobAccountKey,
		$location = "West US"
	)

    try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlAnalyticsAccount -Name $accountName}

		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location
		New-AdlStore -ResourceGroupName $resourceGroupName -Name $secondDataLakeAccountName -Location $location
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(30000)
			Assert-False {$i -eq 60} "dataLakeAnalytics account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-True {Test-AdlAnalyticsAccount -Name $accountName}

		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		$accountUpdated = Set-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Tag $tagsToUpdate
    
		Assert-AreEqual $accountName $accountUpdated.Name
		Assert-AreEqual $location $accountUpdated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountUpdated.Type
		Assert-True {$accountUpdated.Id -like "*$resourceGroupName*"}
	
		Assert-NotNull $accountUpdated.Tags "Tags do not exists"
		Assert-NotNull $accountUpdated.Tags["TestTag"] "The updated tag 'TestTag' does not exist"

		
		[array]$accountsInResourceGroup = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName
		Assert-True {$accountsInResourceGroup.Count -ge 1}
    
		$found = 0
		for ($i = 0; $i -lt $accountsInResourceGroup.Count; $i++)
		{
			if ($accountsInResourceGroup[$i].Name -eq $accountName)
			{
				$found = 1
				Assert-AreEqual $location $accountsInResourceGroup[$i].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountsInResourceGroup[$i].Type
				Assert-True {$accountsInResourceGroup[$i].Id -like "*$resourceGroupName*"}
				break
			}
		}
		Assert-True {$found -eq 1} "Account created earlier is not found when listing all in resource group: $resourceGroupName."

		
		[array]$accountsInSubscription = Get-AdlAnalyticsAccount
		Assert-True {$accountsInSubscription.Count -ge 1}
		Assert-True {$accountsInSubscription.Count -ge $accountsInResourceGroup.Count}
    
		$found = 0
		for ($i = 0; $i -lt $accountsInSubscription.Count; $i++)
		{
			if ($accountsInSubscription[$i].Name -eq $accountName)
			{
				$found = 1
				Assert-AreEqual $location $accountsInSubscription[$i].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountsInSubscription[$i].Type
				Assert-True {$accountsInSubscription[$i].Id -like "*$resourceGroupName*"}
				break
			}
		}
		Assert-True {$found -eq 1} "Account created earlier is not found when listing all in subscription."

		
		Add-AdlAnalyticsDataSource -Account $accountName -DataLakeStore $secondDataLakeAccountName

		
		$testStoreAdd = Get-AdlAnalyticsAccount -Name $accountName
		Assert-AreEqual 2 $testStoreAdd.DataLakeStoreAccounts.Count

		
		$adlsAccountInfo = Get-AdlAnalyticsDataSource -Account $accountName -DataLakeStore $secondDataLakeAccountName
		Assert-AreEqual $secondDataLakeAccountName $adlsAccountInfo.Name

		
		$adlsAccountInfos = Get-AdlAnalyticsDataSource -Account $accountName
		Assert-AreEqual 2 $adlsAccountInfos.Count

		
		Assert-True {Remove-AdlAnalyticsDataSource -Account $accountName -DataLakeStore $secondDataLakeAccountName -Force -PassThru} "Remove Data Lake Store account failed."

		
		$testStoreAdd = Get-AdlAnalyticsAccount -Name $accountName
		Assert-AreEqual 1 $testStoreAdd.DataLakeStoreAccounts.Count

		
		Add-AdlAnalyticsDataSource -Account $accountName -Blob $blobAccountName -AccessKey $blobAccountKey

		
		$testStoreAdd = Get-AdlAnalyticsAccount -Name $accountName
		Assert-AreEqual 1 $testStoreAdd.StorageAccounts.Count

		
		$blobAccountInfo = Get-AdlAnalyticsDataSource -Account $accountName -Blob $blobAccountName
		Assert-AreEqual $blobAccountName $blobAccountInfo.Name

		
		$blobAccountInfos = Get-AdlAnalyticsDataSource -Account $accountName
		Assert-AreEqual 2 $blobAccountInfos.Count

		
		Assert-True {Remove-AdlAnalyticsDataSource -Account $accountName -Blob $blobAccountName -Force -PassThru} "Remove blob Storage account failed."

		
		$testStoreAdd = Get-AdlAnalyticsAccount -Name $accountName
		Assert-True {$testStoreAdd.StorageAccounts -eq $null -or $testStoreAdd.StorageAccounts.Count -eq 0} "Remove blob storage reported success but failed to remove the account."

		
		Assert-True {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $secondDataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}



function Test-DataLakeAnalyticsAccountTiers
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$location = "West US"
	)

    try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlAnalyticsAccount -Name $accountName}

		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location

		
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
    
		Assert-AreEqual "Consumption" $accountCreated.CurrentTier
		Assert-AreEqual "Consumption" $accountCreated.NewTier

		
		$accountUpdated = Set-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Tier Commitment100AUHours

		Assert-AreEqual "Consumption" $accountUpdated.CurrentTier
		Assert-AreEqual "Commitment100AUHours" $accountUpdated.NewTier

		
		$secondAccountName = (Get-DataLakeAnalyticsAccountName)
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $secondAccountName -Location $location -DefaultDataLakeStore $dataLakeAccountName -Tier Commitment100AUHours
		Assert-AreEqual "Commitment100AUHours" $accountCreated.CurrentTier
		Assert-AreEqual "Commitment100AUHours" $accountCreated.NewTier
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $secondAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeAnalyticsJob
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$location = "West US"
	)
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
		$nowTime = $accountCreated.CreationTime
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(30000)
			Assert-False {$i -eq 60} "dataLakeAnalytics accounts not in succeeded state even after 30 min."
		}

		
		
		[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(300000)

		
		$guidForJob = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("jobTest02")
		[Microsoft.Azure.Commands.DataLakeAnalytics.Models.DataLakeAnalyticsClient]::JobIdQueue.Enqueue($guidForJob)

		$jobInfo = Submit-AdlJob -AccountName $accountName -Name "TestJob" -Script "DROP DATABASE IF EXISTS foo; CREATE DATABASE foo;"
		Assert-NotNull {$jobInfo}

		
		Stop-AdlJob -AccountName $accountName -JobId $jobInfo.JobId -Force
		$cancelledJob = Get-AdlJob -AccountName $accountName -JobId $jobInfo.JobId

		
		Assert-NotNull {$cancelledJob}
	
		
		Assert-True {$cancelledJob.Result -like "*Cancel*"}

		Assert-NotNull {Get-AdlJob -AccountName $accountName}

		$jobsWithDateOffset = Get-AdlJob -AccountName $accountName -SubmittedAfter $([DateTimeOffset]($nowTime).AddMinutes(-10))

		Assert-True {$jobsWithDateOffset.Count -gt 0} "Failed to retrieve jobs submitted after ten miuntes ago"
		
		
		$jobsWithDateOffset = Get-AdlJob -AccountName $accountName -SubmittedBefore $([DateTimeOffset]($nowTime).AddMinutes(10))

		Assert-True {$jobsWithDateOffset.Count -gt 0} "Failed to retrieve jobs submitted before right now"

		
		$guidForJob = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("jobTest04")
		[Microsoft.Azure.Commands.DataLakeAnalytics.Models.DataLakeAnalyticsClient]::JobIdQueue.Enqueue($guidForJob)

		
		$parameters = [ordered]@{}
		$parameters["byte_type"] = [byte]0
		$parameters["sbyte_type"] = [sbyte]1
		$parameters["int_type"] = [int32]2
		$parameters["uint_type"] = [uint32]3
		$parameters["long_type"] = [int64]4
		$parameters["ulong_type"] = [uint64]5
		$parameters["float_type"] = [float]6
		$parameters["double_type"] = [double]7
		$parameters["decimal_type"] = [decimal]8
		$parameters["short_type"] = [int16]9
		$parameters["ushort_type"] = [uint16]10
		$parameters["char_type"] = [char]"a"
		$parameters["string_type"] = "test"
		$parameters["datetime_type"] = [DateTime](Get-Date -Date "2018-01-01 00:00:00")
		$parameters["bool_type"] = $true
		$parameters["guid_type"] = [guid]"8dbdd1e8-0675-4cf2-a7f7-5e376fa43c6d"
		$parameters["bytearray_type"] = [byte[]]@(0, 1, 2)

		
		$expectedScript = "DECLARE @byte_type byte = 0;`nDECLARE @sbyte_type sbyte = 1;`nDECLARE @int_type int = 2;`nDECLARE @uint_type uint = 3;`nDECLARE @long_type long = 4;`nDECLARE @ulong_type ulong = 5;`nDECLARE @float_type float = 6;`nDECLARE @double_type double = 7;`nDECLARE @decimal_type decimal = 8;`nDECLARE @short_type short = 9;`nDECLARE @ushort_type ushort = 10;`nDECLARE @char_type char = 'a';`nDECLARE @string_type string = `"test`";`nDECLARE @datetime_type DateTime = new DateTime(2018, 1, 1, 0, 0, 0, 0);`nDECLARE @bool_type bool = true;`nDECLARE @guid_type Guid = new Guid(`"8dbdd1e8-0675-4cf2-a7f7-5e376fa43c6d`");`nDECLARE @bytearray_type byte[] = new byte[] {`n  0,`n  1,`n  2,`n};`nDROP DATABASE IF EXISTS foo; CREATE DATABASE foo;"

		$jobInfo = Submit-AdlJob -AccountName $accountName -Name "TestJob" -Script "DROP DATABASE IF EXISTS foo; CREATE DATABASE foo;" -ScriptParameter $parameters
		Assert-NotNull {$jobInfo}

		
		$jobInfo = Wait-AdlJob -Account $accountName -JobId $jobInfo.JobId
		Assert-NotNull {$jobInfo}
		Assert-AreEqual "Succeeded" $jobInfo.Result
		Assert-AreEqual $expectedScript $jobInfo.Properties.Script

		
		Assert-True {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}



function Test-NegativeDataLakeAnalyticsAccount
{
    param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$location = "West US",
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$fakeaccountName = "psfakedataLakeAnalyticsaccounttest"
	)
	
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
		
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(30000)
			Assert-False {$i -eq 60} "dataLakeAnalytics accounts not in succeeded state even after 30 min."
		}

		
		Assert-Throws {New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName}

		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		Assert-Throws {Set-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $fakeaccountName -Tag $tagsToUpdate}

		
		Assert-Throws {Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $fakeaccountName}

		
		Assert-True {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru}

		
		Assert-Throws {Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}



function Test-NegativeDataLakeAnalyticsJob
{
   param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$location = "West US"
	)
	
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		New-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Location $location
		$accountCreated = New-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DefaultDataLakeStore $dataLakeAccountName
		$nowTime = $accountCreated.CreationTime
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(30000)
			Assert-False {$i -eq 60} "dataLakeAnalytics accounts not in succeeded state even after 30 min."
		}

		
		Assert-Throws {Stop-AdlJob -AccountName $accountName -JobIdentity [Guid]::Empty}

		
		Assert-Throws {Get-AdlJob -AccountName $accountName -JobIdentity [Guid]::Empty}

		
		Assert-Throws {Get-AdlJobDebugInfo -AccountName $accountName -JobIdentity [Guid]::Empty}

		$jobsWithDateOffset = Get-AdlJob -AccountName $accountName -SubmittedAfter $([DateTimeOffset]$nowTime)

		Assert-True {$jobsWithDateOffset.Count -eq 0} "Retrieval of jobs submitted after right now returned results and should not have"

		
		Assert-True {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeAnalyticsCatalog
{
   param
	(
		$resourceGroupName = (Get-ResourceGroupName),
		$accountName = (Get-DataLakeAnalyticsAccountName),
		$dataLakeAccountName = (Get-DataLakeStoreAccountName),
		$databaseName = (getAssetName),
		$tableName = (getAssetName),
		$tvfName = (getAssetName),
		$viewName = (getAssetName),
		$procName = (getAssetName),
		$credentialName = (getAssetName),
		$secretName = (getAssetName),
		$secretPwd = (getAssetName),
		$location = "West US"
	)
	
	try
	{
		
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		New-AdlStore -Name $dataLakeAccountName -Location $location -ResourceGroupName $resourceGroupName
		$accountCreated = New-AdlAnalyticsAccount -Name $accountName -Location $location -ResourceGroupName $resourceGroupName -DefaultDataLakeStore $dataLakeAccountName
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeAnalytics/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(30000)
			Assert-False {$i -eq 60} "dataLakeAnalytics accounts not in succeeded state even after 30 min."
		}

		
		
		[Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait(300000)
	
		
		$scriptTemplate = @"
	DROP DATABASE IF EXISTS {0}; CREATE DATABASE {0};
	CREATE TABLE {0}.dbo.{1}
	(
			//Define schema of table
			UserId          int, 
			Start           DateTime, 
			Region          string, 
			Query           string, 
			Duration        int, 
			Urls            string, 
			ClickedUrls     string,
		INDEX idx1 //Name of index
		CLUSTERED (Region ASC) //Column to cluster by
		PARTITIONED BY (UserId) HASH (Region) //Column to partition by
	);
	ALTER TABLE {0}.dbo.{1} ADD IF NOT EXISTS PARTITION (1);
	DROP FUNCTION IF EXISTS {0}.dbo.{2};

	//create table weblogs on space-delimited website log data
	CREATE FUNCTION {0}.dbo.{2}()
	RETURNS @result TABLE
	(
		s_date DateTime,
		s_time string,
		s_sitename string,
		cs_method string, 
		cs_uristem string,
		cs_uriquery string,
		s_port int,
		cs_username string, 
		c_ip string,
		cs_useragent string,
		cs_cookie string,
		cs_referer string, 
		cs_host string,
		sc_status int,
		sc_substatus int,
		sc_win32status int, 
		sc_bytes int,
		cs_bytes int,
		s_timetaken int
	)
	AS
	BEGIN

		@result = EXTRACT
			s_date DateTime,
			s_time string,
			s_sitename string,
			cs_method string,
			cs_uristem string,
			cs_uriquery string,
			s_port int,
			cs_username string,
			c_ip string,
			cs_useragent string,
			cs_cookie string,
			cs_referer string,
			cs_host string,
			sc_status int,
			sc_substatus int,
			sc_win32status int,
			sc_bytes int,
			cs_bytes int,
			s_timetaken int
		FROM @"/Samples/Data/WebLog.log"
		USING Extractors.Text(delimiter:' ');

	RETURN;
	END;
	CREATE VIEW {0}.dbo.{3} 
	AS 
		SELECT * FROM 
		(
			VALUES(1,2),(2,4)
		) 
	AS 
	T(a, b);
	CREATE PROCEDURE {0}.dbo.{4}()
	AS BEGIN
	  CREATE VIEW {0}.dbo.{3} 
	  AS 
		SELECT * FROM 
		(
			VALUES(1,2),(2,4)
		) 
	  AS 
	  T(a, b);
	END;
"@
		
		$scriptToRun = [string]::Format($scriptTemplate, $databaseName, $tableName, $tvfName, $viewName, $procName)
		$guidForJob = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::GenerateGuid("catalogCreationJob01")
		[Microsoft.Azure.Commands.DataLakeAnalytics.Models.DataLakeAnalyticsClient]::JobIdQueue.Enqueue($guidForJob)
		$jobInfo = Submit-AdlJob -AccountName $accountName -Name "TestJob" -Script $scriptToRun
		$result = Wait-AdlJob -AccountName $accountName -JobId $jobInfo.JobId
		Assert-AreEqual "Succeeded" $result.Result

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType Database

		Assert-NotNull $itemList "The database list is null"

		Assert-True {$itemList.count -gt 0} "The database list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $databaseName)
			{
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the database $databaseName in the database list"
	
		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType Database -Path $databaseName
		Assert-NotNull $specificItem "Could not retrieve the db by name"
		Assert-AreEqual $databaseName $specificItem.Name

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType Table -Path "$databaseName.dbo"

		Assert-NotNull $itemList "The table list is null"

		Assert-True {$itemList.count -gt 0} "The table list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $tableName)
			{
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the table $tableName in the table list"
		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType Table -Path "$databaseName"

		Assert-NotNull $itemList "The table list is null"

		Assert-True {$itemList.count -gt 0} "The table list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $tableName)
			{
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the table $tableName in the table list"

		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType Table -Path "$databaseName.dbo.$tableName"
		Assert-NotNull $specificItem "Could not retrieve the table by name"
		Assert-AreEqual $tableName $specificItem.Name

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType TablePartition -Path "$databaseName.dbo.$tableName"

		Assert-NotNull $itemList "The table partition list is null"

		Assert-True {$itemList.count -gt 0} "The table partition list is empty"
		
		$itemToFind = $itemList[0]
	
		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType TablePartition -Path "$databaseName.dbo.$tableName.[$($itemToFind.Name)]"
		Assert-NotNull $specificItem "Could not retrieve the table partition by name"
		Assert-AreEqual $itemToFind.Name $specificItem.Name

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType TableValuedFunction -Path "$databaseName.dbo"

		Assert-NotNull $itemList "The TVF list is null"

		Assert-True {$itemList.count -gt 0} "The TVF list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $tvfName)
			{
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the TVF $tvfName in the TVF list"
	
		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType TableValuedFunction -Path "$databaseName"

		Assert-NotNull $itemList "The TVF list is null"

		Assert-True {$itemList.count -gt 0} "The TVF list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $tvfName)
			{
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the TVF $tvfName in the TVF list"

		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType TableValuedFunction -Path "$databaseName.dbo.$tvfName"
		Assert-NotNull $specificItem "Could not retrieve the TVF by name"
		Assert-AreEqual $tvfName $specificItem.Name

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType Procedure -Path "$databaseName.dbo"

		Assert-NotNull $itemList "The procedure list is null"

		Assert-True {$itemList.count -gt 0} "The procedure list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $procName)
			{
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the procedure $procName in the procedure list"
	
		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType Procedure -Path "$databaseName.dbo.$procName"
		Assert-NotNull $specificItem "Could not retrieve the procedure by name"
		Assert-AreEqual $procName $specificItem.Name

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType View -Path "$databaseName.dbo"

		Assert-NotNull $itemList "The view list is null"

		Assert-True {$itemList.count -gt 0} "The view list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $viewName)
			{
				$found = $true
				break
			}
		}
	
		Assert-True {$found} "Could not find the view $viewName in the view list"

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType View -Path "$databaseName"

		Assert-NotNull $itemList "The view list is null"

		Assert-True {$itemList.count -gt 0} "The view list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $viewName)
			{
				$found = $true
				break
			}
		}
	
		Assert-True {$found} "Could not find the view $viewName in the view list"


		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType View -Path "$databaseName.dbo.$viewName"
		Assert-NotNull $specificItem "Could not retrieve the view by name"
		Assert-AreEqual $viewName $specificItem.Name

		
		$pw = ConvertTo-SecureString -String $secretPwd -AsPlainText -Force
		$secret = New-Object System.Management.Automation.PSCredential($secretName,$pw)
		$secretName2 = $secretName + "dup"
		$secret2 = New-Object System.Management.Automation.PSCredential($secretName2,$pw)

		New-AdlCatalogSecret -AccountName $accountName -secret $secret -DatabaseName $databaseName -Uri "https://pstest.contoso.com:443"
		New-AdlCatalogSecret -AccountName $accountName -secret $secret2 -DatabaseName $databaseName -Uri "https://pstest.contoso.com:443"

		
		
		
		$getSecret = Get-AdlCatalogItem -AccountName $accountName -ItemType Secret -Path "$databaseName.$secretName"
		Assert-NotNull $getSecret "Could not retrieve the secret"
    
		
		New-AdlCatalogCredential -AccountName $accountName -DatabaseName $databaseName -CredentialName $credentialName -Credential $secret -Uri "https://fakedb.contoso.com:443"

		
		$itemList = Get-AdlCatalogItem -AccountName $accountName -ItemType Credential -Path $databaseName

		Assert-NotNull $itemList "The credential list is null"

		Assert-True {$itemList.count -gt 0} "The credential list is empty"
		$found = $false
		foreach($item in $itemList)
		{
			if($item.Name -eq $credentialName)
			{
				$found = $true
				break
			}
		}
	
		
		$specificItem = Get-AdlCatalogItem -AccountName $accountName -ItemType Credential -Path "$databaseName.$credentialName"
		Assert-NotNull $specificItem "Could not retrieve the credential by name"
		Assert-AreEqual $credentialName $specificItem.Name

		
		Remove-AdlCatalogCredential -AccountName $accountName -DatabaseName $databaseName -Name $credentialName
		
		
		Assert-Throws {Get-AdlCatalogItem -AccountName $accountName -ItemType Credential -Path "$databaseName.$credentialName"}

		
		New-AdlCatalogCredential -AccountName $accountName -DatabaseName $databaseName -CredentialName $credentialName -Credential $secret -Uri "https://fakedb.contoso.com:443"

		
		Remove-AdlCatalogCredential -AccountName $accountName -DatabaseName $databaseName -Name $credentialName -Recurse -Force
		
		
		Assert-Throws {Get-AdlCatalogItem -AccountName $accountName -ItemType Credential -Path "$databaseName.$credentialName"}

		
		Remove-AdlCatalogSecret -AccountName $accountName -Name $secretName -DatabaseName $databaseName -Force

		
		Assert-Throws {Get-AdlCatalogItem -AccountName $accountName -ItemType Secret -Path "$databaseName.$secretName"}

		
		Remove-AdlCatalogSecret -AccountName $accountName -DatabaseName $databaseName -Force

		
		Assert-Throws {Get-AdlCatalogItem -AccountName $accountName -ItemType Secret -Path "$databaseName.$secretName2"}

		
		$userPrincipalId = "027c28d5-c91d-49f0-98c5-d10134b169b3"
		$groupPrincipalId = "58d2027c-d19c-0f94-5c89-1b43101d3b96"

		
		$aclByDbList = Get-AdlCatalogItemAclEntry -AccountName $accountName -ItemType Database -Path $databaseName
		$aclByDbInitialCount = $aclByDbList.count

		
		$aclList = Get-AdlCatalogItemAclEntry -AccountName $accountName
		$aclInitialCount = $aclList.count

		
		$aclByDbList = Set-AdlCatalogItemAclEntry -AccountName $accountName -User -Id $userPrincipalId -ItemType Database -Path $databaseName -Permissions Read

		Assert-AreEqual $($aclByDbInitialCount+1) $aclByDbList.count
		$found = $false
		foreach($acl in $aclByDbList)
		{
			if($acl.Id -eq $userPrincipalId)
			{
				
				Assert-AreEqual User $acl.Type
				Assert-AreEqual $userPrincipalId $acl.Id
				Assert-AreEqual Read $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for $userPrincipalId in the ACL list of $databaseName"

		
		Assert-True {Remove-AdlCatalogItemAclEntry -AccountName $accountName -User -Id $userPrincipalId -ItemType Database -Path $databaseName -PassThru} "Remove ACE failed."

		$aclByDbList = Get-AdlCatalogItemAclEntry -AccountName $accountName -ItemType Database -Path $databaseName
		Assert-AreEqual $aclByDbInitialCount $aclByDbList.count

		
		$aclByDbList = Set-AdlCatalogItemAclEntry -AccountName $accountName -Group -Id $groupPrincipalId -ItemType Database -Path $databaseName -Permissions Read

		Assert-AreEqual $($aclByDbInitialCount+1) $aclByDbList.count
		$found = $false
		foreach($acl in $aclByDbList)
		{
			if($acl.Id -eq $groupPrincipalId)
			{
				
				Assert-AreEqual Group $acl.Type
				Assert-AreEqual $groupPrincipalId $acl.Id
				Assert-AreEqual Read $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for $groupPrincipalId in the ACL list of $databaseName"

		
		Assert-True {Remove-AdlCatalogItemAclEntry -AccountName $accountName -Group -Id $groupPrincipalId -ItemType Database -Path $databaseName -PassThru} "Remove ACE failed."

		$aclByDbList = Get-AdlCatalogItemAclEntry -AccountName $accountName -ItemType Database -Path $databaseName
		Assert-AreEqual $aclByDbInitialCount $aclByDbList.count

		
		$aclByDbList = Set-AdlCatalogItemAclEntry -AccountName $accountName -Other -ItemType Database -Path $databaseName -Permissions None
		Assert-AreEqual $aclByDbInitialCount $aclByDbList.count
		$found = $false
		foreach($acl in $aclByDbList)
		{
			if($acl.Type -eq "Other")
			{
				
				Assert-AreEqual None $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for Other in the ACL list of $databaseName"

		$aclByDbList = Set-AdlCatalogItemAclEntry -AccountName $accountName -Other -ItemType Database -Path $databaseName -Permissions Read
		Assert-AreEqual $aclByDbInitialCount $aclByDbList.count
		$found = $false
		foreach($acl in $aclByDbList)
		{
			if($acl.Type -eq "Other")
			{
				
				Assert-AreEqual Read $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for Other in the ACL list of $databaseName"

		
		$prevDbOwnerAcl = Get-AdlCatalogItemAclEntry -AccountName $accountName -UserOwner -ItemType Database -Path $databaseName
		Assert-AreNotEqual None $prevDbOwnerAcl.Permissions
		$currentDbOwnerAcl = Set-AdlCatalogItemAclEntry -AccountName $accountName -UserOwner -ItemType Database -Path $databaseName -Permissions None
		Assert-AreEqual None $currentDbOwnerAcl.Permissions
		$prevDbGroupAcl = Get-AdlCatalogItemAclEntry -AccountName $accountName -GroupOwner -ItemType Database -Path $databaseName
		Assert-AreNotEqual None $prevDbGroupAcl.Permissions
		$currentDbGroupAcl = Set-AdlCatalogItemAclEntry -AccountName $accountName -GroupOwner -ItemType Database -Path $databaseName -Permissions None
		Assert-AreEqual None $currentDbGroupAcl.Permissions

		
		$aclList = Set-AdlCatalogItemAclEntry -AccountName $accountName -User -Id $userPrincipalId -Permissions Read
		Assert-AreEqual $($aclInitialCount+1) $aclList.count
		$found = $false
		foreach($acl in $aclList)
		{
			if($acl.Id -eq $userPrincipalId)
			{
				
				Assert-AreEqual User $acl.Type
				Assert-AreEqual $userPrincipalId $acl.Id
				Assert-AreEqual Read $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for $userPrincipalId in the Catalog ACL list"

		
		Assert-True {Remove-AdlCatalogItemAclEntry -AccountName $accountName -User -Id $userPrincipalId -PassThru} "Remove ACE failed."

		$aclList = Get-AdlCatalogItemAclEntry -AccountName $accountName
		Assert-AreEqual $aclInitialCount $aclList.count

		
		$aclList = Set-AdlCatalogItemAclEntry -AccountName $accountName -Group -Id $groupPrincipalId -Permissions Read

		Assert-AreEqual $($aclInitialCount+1) $aclList.count
		$found = $false
		foreach($acl in $aclList)
		{
			if($acl.Id -eq $groupPrincipalId)
			{
				
				Assert-AreEqual Group $acl.Type
				Assert-AreEqual $groupPrincipalId $acl.Id
				Assert-AreEqual Read $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for $groupPrincipalId in the Catalog ACL list"

		
		Assert-True {Remove-AdlCatalogItemAclEntry -AccountName $accountName -Group -Id $groupPrincipalId -PassThru} "Remove ACE failed."

		$aclList = Get-AdlCatalogItemAclEntry -AccountName $accountName
		Assert-AreEqual $aclInitialCount $aclList.count

		
		$aclList = Set-AdlCatalogItemAclEntry -AccountName $accountName -Other -Permissions None
		Assert-AreEqual $aclInitialCount $aclList.count
		$found = $false
		foreach($acl in $aclList)
		{
			if($acl.Type -eq "Other")
			{
				
				Assert-AreEqual None $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for Other in the Catalog ACL list"

		$aclList = Set-AdlCatalogItemAclEntry -AccountName $accountName -Other -Permissions Read
		Assert-AreEqual $aclInitialCount $aclList.count
		$found = $false
		foreach($acl in $aclList)
		{
			if($acl.Type -eq "Other")
			{
				
				Assert-AreEqual Read $acl.Permissions
				$found = $true
				break
			}
		}

		Assert-True {$found} "Could not find the entry for Other in the Catalog ACL list"

		
		$prevCatalogOwnerAcl = Get-AdlCatalogItemAclEntry -AccountName $accountName -UserOwner
		Assert-AreNotEqual None $prevCatalogOwnerAcl.Permissions
		$currentCatalogOwnerAcl = Set-AdlCatalogItemAclEntry -AccountName $accountName -UserOwner -Permissions None
		Assert-AreEqual None $currentCatalogOwnerAcl.Permissions
		$prevCatalogGroupAcl = Get-AdlCatalogItemAclEntry -AccountName $accountName -GroupOwner
		Assert-AreNotEqual None $prevCatalogGroupAcl.Permissions
		$currentCatalogGroupAcl = Set-AdlCatalogItemAclEntry -AccountName $accountName -GroupOwner -Permissions None
		Assert-AreEqual None $currentCatalogGroupAcl.Permissions

		
		Assert-True {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}