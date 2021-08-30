
function Test-AnalysisServicesServer
{
	try
	{  
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		$backupBlobContainerUri = $env:AAS_DEFAULT_BACKUP_BLOB_CONTAINER_URI

		New-AzResourceGroup -Name $resourceGroupName -Location $location

		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'S1' -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net'
    
		Assert-AreEqual $serverName $serverCreated.Name
		Assert-AreEqual $location $serverCreated.Location
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverCreated.Type
		Assert-AreEqual $resourceGroupName $serverCreated.ResourceGroupName
		Assert-AreEqual 2 $serverCreated.AsAdministrators.Count
		Assert-True {$serverCreated.Id -like "*$resourceGroupName*"}
		Assert-True {$serverCreated.ServerFullName -ne $null -and $serverCreated.ServerFullName.Contains("$serverName")}
	    Assert-AreEqual 1 $serverCreated.Sku.Capacity

		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]

		Assert-True {$serverGetItem.ProvisioningState -like "Succeeded"}
		Assert-True {$serverGetItem.State -like "Succeeded"}
		
		Assert-AreEqual $serverName $serverGetItem.Name
		Assert-AreEqual $location $serverGetItem.Location
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverGetItem.Type
		Assert-AreEqual $resourceGroupName $serverGetItem.ResourceGroupName
		Assert-True {$serverGetItem.Id -like "*$resourceGroupName*"}

		
		Assert-True {Test-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName}
		
		Assert-True {Test-AzAnalysisServicesServer -Name $serverName}
		
		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		$serverUpdated = Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Tag $tagsToUpdate -PassThru
		Assert-NotNull $serverUpdated.Tag "Tag do not exists"
		Assert-NotNull $serverUpdated.Tag["TestTag"] "The updated tag 'TestTag' does not exist"
		Assert-AreEqual $serverUpdated.AsAdministrators.Count 2
		Assert-AreEqual 1 $serverUpdated.Sku.Capacity
		Assert-AreEqual $resourceGroupName $serverUpdated.ResourceGroupName

		$serverUpdated = Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Administrator 'aztest1@stabletest.ccsctp.net' -PassThru
		Assert-NotNull $serverUpdated.AsAdministrators "Server Administrator list is empty"
		Assert-AreEqual $serverUpdated.AsAdministrators.Count 1
		Assert-AreEqual 1 $serverUpdated.Sku.Capacity
		Assert-AreEqual $resourceGroupName $serverUpdated.ResourceGroupName

		Assert-AreEqual $serverName $serverUpdated.Name
		Assert-AreEqual $location $serverUpdated.Location
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverUpdated.Type
		Assert-True {$serverUpdated.Id -like "*$resourceGroupName*"}

		
		[array]$serversInResourceGroup = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName
		Assert-True {$serversInResourceGroup.Count -ge 1}

		$found = 0
		for ($i = 0; $i -lt $serversInResourceGroup.Count; $i++)
		{
			if ($serversInResourceGroup[$i].Name -eq $serverName)
			{
				$found = 1
				Assert-AreEqual $location $serversInResourceGroup[$i].Location
				Assert-AreEqual "Microsoft.AnalysisServices/servers" $serversInResourceGroup[$i].Type
				Assert-True {$serversInResourceGroup[$i].Id -like "*$resourceGroupName*"}

				break
			}
		}
		Assert-True {$found -eq 1} "server created earlier is not found when listing all in resource group: $resourceGroupName."

		
		[array]$serversInSubscription = Get-AzAnalysisServicesServer
		Assert-True {$serversInSubscription.Count -ge 1}
		Assert-True {$serversInSubscription.Count -ge $serversInResourceGroup.Count}
    
		$found = 0
		for ($i = 0; $i -lt $serversInSubscription.Count; $i++)
		{
			if ($serversInSubscription[$i].Name -eq $serverName)
			{
				$found = 1
				Assert-AreEqual $location $serversInSubscription[$i].Location
				Assert-AreEqual "Microsoft.AnalysisServices/servers" $serversInSubscription[$i].Type
				Assert-True {$serversInSubscription[$i].Id -like "*$resourceGroupName*"}
    
				break
			}
		}
		Assert-True {$found -eq 1} "Account created earlier is not found when listing all in subscription."

		
		Suspend-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]
		Assert-True {$serverGetItem.State -like "Paused"}
		

		
		Resume-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]
		Assert-True {$serverGetItem.ProvisioningState -like "Succeeded"}
		Assert-True {$serverGetItem.State -like "Succeeded"}
		
		
		Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru

		
		Assert-Throws {Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-AnalysisServicesServerScaleUpDown
{
	try
	{  
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'B1' -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net'
		Assert-AreEqual $serverName $serverCreated.Name
		Assert-AreEqual $location $serverCreated.Location
		Assert-AreEqual $resourceGroupName $serverCreated.ResourceGroupName
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverCreated.Type
		Assert-AreEqual B1 $serverCreated.Sku.Name
		Assert-True {$serverCreated.Id -like "*$resourceGroupName*"}
		Assert-True {$serverCreated.ServerFullName -ne $null -and $serverCreated.ServerFullName.Contains("$serverName")}
	    Assert-AreEqual 1 $serverCreated.Sku.Capacity

		
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]

		Assert-True {$serverGetItem.ProvisioningState -like "Succeeded"}
		Assert-True {$serverGetItem.State -like "Succeeded"}
		
		Assert-AreEqual $serverName $serverGetItem.Name
		Assert-AreEqual $location $serverGetItem.Location
		Assert-AreEqual B1 $serverGetItem.Sku.Name
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverGetItem.Type
		Assert-True {$serverGetItem.Id -like "*$resourceGroupName*"}
		
		
		$serverUpdated = Set-AzAnalysisServicesServer -Name $serverName -Sku S2 -PassThru
		Assert-AreEqual S2 $serverUpdated.Sku.Name

		
		$serverUpdated = Set-AzAnalysisServicesServer -Name $serverName -Sku S1 -PassThru
		Assert-AreEqual S1 $serverUpdated.Sku.Name
		
		
		Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-AnalysisServicesServerFirewall
{
	try
	{  
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		$rule1 = New-AzAnalysisServicesFirewallRule -FirewallRuleName abc1 -RangeStart 0.0.0.0 -RangeEnd 255.255.255.255
        $rule2 = New-AzAnalysisServicesFirewallRule -FirewallRuleName abc2 -RangeStart 6.6.6.6 -RangeEnd 7.7.7.7
        $config = New-AzAnalysisServicesFirewallConfig -FirewallRule $rule1, $rule2
		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'B1' -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net' -FirewallConfig $config
		Assert-AreEqual 1 $serverCreated.Sku.Capacity
		Assert-AreEqual $serverName $serverCreated.Name
		Assert-AreEqual $location $serverCreated.Location
		Assert-AreEqual $resourceGroupName $serverCreated.ResourceGroupName
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverCreated.Type
		Assert-AreEqual B1 $serverCreated.Sku.Name
		Assert-True {$serverCreated.Id -like "*$resourceGroupName*"}
		Assert-True {$serverCreated.ServerFullName -ne $null -and $serverCreated.ServerFullName.Contains("$serverName")}
	    Assert-AreEqual $FALSE $serverCreated.FirewallConfig.EnablePowerBIService
		Assert-AreEqual 2 $serverCreated.FirewallConfig.FirewallRules.Count
		Assert-AreEqual 0.0.0.0 $serverCreated.FirewallConfig.FirewallRules[0].RangeStart
		Assert-AreEqual 255.255.255.255 $serverCreated.FirewallConfig.FirewallRules[0].RangeEnd
		Assert-AreEqual 6.6.6.6 $serverCreated.FirewallConfig.FirewallRules[1].RangeStart
		Assert-AreEqual 7.7.7.7 $serverCreated.FirewallConfig.FirewallRules[1].RangeEnd

		
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]

		Assert-True {$serverGetItem.ProvisioningState -like "Succeeded"}
		Assert-True {$serverGetItem.State -like "Succeeded"}
		
		Assert-AreEqual $serverName $serverGetItem.Name
		Assert-AreEqual $location $serverGetItem.Location
		Assert-AreEqual B1 $serverGetItem.Sku.Name
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverGetItem.Type
		Assert-True {$serverGetItem.Id -like "*$resourceGroupName*"}	
	    Assert-AreEqual $FALSE $serverGetItem.FirewallConfig.EnablePowerBIService
		Assert-AreEqual 2 $serverGetItem.FirewallConfig.FirewallRules.Count
		
		$emptyConfig = @()
		$config = New-AzAnalysisServicesFirewallConfig -EnablePowerBIService -FirewallRule $emptyConfig
		Set-AzAnalysisServicesServer -Name $serverName -FirewallConfig $config
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]
	    Assert-AreEqual $TRUE $serverGetItem.FirewallConfig.EnablePowerBIService
		Assert-AreEqual 0 $serverGetItem.FirewallConfig.FirewallRules.Count
		Assert-AreEqual 1 $serverGetItem.Sku.Capacity

		
		Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-AnalysisServicesServerScaleOutIn
{
	try
	{  
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'S1' -ReadonlyReplicaCount 1 -DefaultConnectionMode 'Readonly' -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net'
		Assert-AreEqual $serverName $serverCreated.Name
		Assert-AreEqual $location $serverCreated.Location
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverCreated.Type
		Assert-AreEqual S1 $serverCreated.Sku.Name
		Assert-AreEqual 2 $serverCreated.Sku.Capacity
		Assert-AreEqual "Readonly" $serverCreated.DefaultConnectionMode		
		Assert-True {$serverCreated.Id -like "*$resourceGroupName*"}
		Assert-True {$serverCreated.ServerFullName -ne $null -and $serverCreated.ServerFullName.Contains("$serverName")}
	
		
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]

		Assert-True {$serverGetItem.ProvisioningState -like "Succeeded"}
		Assert-True {$serverGetItem.State -like "Succeeded"}
		
		Assert-AreEqual $serverName $serverGetItem.Name
		Assert-AreEqual $location $serverGetItem.Location
		Assert-AreEqual S1 $serverGetItem.Sku.Name
		Assert-AreEqual 2 $serverCreated.Sku.Capacity
		Assert-AreEqual "Readonly" $serverCreated.DefaultConnectionMode	
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverGetItem.Type
		Assert-True {$serverGetItem.Id -like "*$resourceGroupName*"}
		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		$serverUpdated = Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Tag $tagsToUpdate -PassThru
		Assert-AreEqual 2 $serverUpdated.Sku.Capacity

		
		$serverUpdated = Set-AzAnalysisServicesServer -Name $serverName -ReadonlyReplicaCount 0 -PassThru
		Assert-AreEqual 1 $serverUpdated.Sku.Capacity
		Assert-AreEqual S1 $serverUpdated.Sku.Name
		
		
		Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-AnalysisServicesServerDisableBackup
{
	try
	{  
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		$backupBlobContainerUri = $env:AAS_DEFAULT_BACKUP_BLOB_CONTAINER_URI
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'B1' -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net' -BackupBlobContainerUri $backupBlobContainerUri
		Assert-AreEqual $serverName $serverCreated.Name
		Assert-AreEqual $location $serverCreated.Location
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverCreated.Type
		Assert-AreEqual B1 $serverCreated.Sku.Name
		Assert-True {$backupBlobContainerUri.Contains($serverCreated.BackupBlobContainerUri)}
		Assert-True {$serverCreated.Id -like "*$resourceGroupName*"}
		Assert-True {$serverCreated.ServerFullName -ne $null -and $serverCreated.ServerFullName.Contains("$serverName")}
	
		
		[array]$serverGet = Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName
		$serverGetItem = $serverGet[0]

		Assert-True {$serverGetItem.ProvisioningState -like "Succeeded"}
		Assert-True {$serverGetItem.State -like "Succeeded"}
		Assert-True {$backupBlobContainerUri.Contains($serverGetItem.BackupBlobContainerUri)}
		
		Assert-AreEqual $serverName $serverGetItem.Name
		Assert-AreEqual $location $serverGetItem.Location
		Assert-AreEqual B1 $serverGetItem.Sku.Name
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverGetItem.Type
		Assert-True {$serverGetItem.Id -like "*$resourceGroupName*"}
		
		
		$backupBlobContainerUriToUpdate = $env:AAS_SECOND_BACKUP_BLOB_CONTAINER_URI
		$serverUpdated = Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -BackupBlobContainerUri "$backupBlobContainerUriToUpdate" -PassThru
		Assert-NotNull $serverUpdated.BackupBlobContainerUri "The backup blob container Uri is empty"
		Assert-True {$backupBlobContainerUriToUpdate.contains($serverUpdated.BackupBlobContainerUri)}
		Assert-AreEqual $serverUpdated.AsAdministrators.Count 2

		
		$serverUpdated = Set-AzAnalysisServicesServer -Name $serverName -DisableBackup -PassThru
		Assert-True {[string]::IsNullOrEmpty($serverUpdated.BackupBlobContainerUri)}
		
		
		Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-NegativeAnalysisServicesServer
{
    param
	(
		$fakeserverName = "psfakeservertest",
		$invalidSku = "INVALID"
	)
	
	try
	{
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'S1' -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net'

		Assert-AreEqual $serverName $serverCreated.Name
		Assert-AreEqual $location $serverCreated.Location
		Assert-AreEqual $resourceGroupName $serverCreated.ResourceGroupName
		Assert-AreEqual "Microsoft.AnalysisServices/servers" $serverCreated.Type
		Assert-True {$serverCreated.Id -like "*$resourceGroupName*"}

		
		Assert-Throws {New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location}

		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		Assert-Throws {Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $fakeserverName -Tag $tagsToUpdate}

		
		Assert-Throws {Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $fakeserverName}

		
		Assert-Throws {New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $fakeserverName -Location $location -Sku $invalidSku -Administrator 'aztest0@stabletest.ccsctp.net,aztest1@stabletest.ccsctp.net'}

		
		Assert-Throws {Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Sku $invalidSku}

		
		Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru

		
		Assert-Throws {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -PassThru}

		
		Assert-Throws {Get-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-AnalysisServicesServerLogExport
{
    param
	(
		$rolloutEnvironment = $env:ASAZURE_TEST_ROLLOUT
	)
    try
    {
        $location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'S1' -Administrators $env:ASAZURE_TEST_ADMUSERS
		Assert-True {$serverCreated.ProvisioningState -like "Succeeded"}
		Assert-True {$serverCreated.State -like "Succeeded"}

		$secpasswd = ConvertTo-SecureString $env:ASAZURE_TESTUSER_PWD -AsPlainText -Force
		$admuser0 = $env:ASAZURE_TEST_ADMUSERS.Split(',')[0]
		$cred = New-Object System.Management.Automation.PSCredential ($admuser0, $secpasswd)
		$asAzureProfile = Login-AzAsAccount -RolloutEnvironment $rolloutEnvironment -Credential $cred
		Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"

        $tempFile = [System.IO.Path]::GetTempFileName()
        Export-AzAnalysisServicesInstanceLog -Instance $serverName -OutputPath $tempFile
        Assert-Exists $tempFile
        $logContent = [System.IO.File]::ReadAllText($tempFile)
        Assert-False { [string]::IsNullOrEmpty($logContent); }
    }
    finally
    {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile
        }
        Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
    }
}


function Test-AnalysisServicesServerRestart
{
    param
	(
		$rolloutEnvironment = $env:ASAZURE_TEST_ROLLOUT
	)
	try
	{
		
		$location = Get-AnalysisServicesLocation
		$resourceGroupName = Get-ResourceGroupName
		$serverName = Get-AnalysisServicesServerName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		$serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'S1' -Administrator $env:ASAZURE_TEST_ADMUSERS
		Assert-True {$serverCreated.ProvisioningState -like "Succeeded"}
		Assert-True {$serverCreated.State -like "Succeeded"}

		$asAzureProfile = Login-AzAsAccount -RolloutEnvironment $rolloutEnvironment
		Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"

		$secpasswd = ConvertTo-SecureString $env:ASAZURE_TESTUSER_PWD -AsPlainText -Force
		$admuser0 = $env:ASAZURE_TEST_ADMUSERS.Split(',')[0]
		$cred = New-Object System.Management.Automation.PSCredential ($admuser0, $secpasswd)

		$asAzureProfile = Login-AzAsAccount -RolloutEnvironment $rolloutEnvironment -Credential $cred
		Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"
		Assert-True { Restart-AzAsInstance -Instance $serverName -PassThru }

		$rolloutEnvironment = 'asazure-int.windows.net'
		$asAzureProfile = Login-AzAsAccount $rolloutEnvironment
		Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"

		$rolloutEnvironment = 'asazure.windows.net'
		$asAzureProfile = Login-AzAsAccount $rolloutEnvironment
		Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"

	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}



function Test-AnalysisServicesServerSynchronizeSingle
{
    param
	(
		$rolloutEnvironment = $env.ASAZURE_TEST_ROLLOUT
	)
	try
	{
		
        $location = Get-AnalysisServicesLocation
        $resourceGroupName = Get-ResourceGroupName
        $serverName = Get-AnalysisServicesServerName
        New-AzResourceGroup -Name $resourceGroupName -Location $location

        $serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku 'S1' -Administrators $env.ASAZURE_TESTUSER
        Assert-True {$serverCreated.ProvisioningState -like "Succeeded"}
        Assert-True {$serverCreated.State -like "Succeeded"}

        $asAzureProfile = Login-AzAsAccount -RolloutEnvironment $rolloutEnvironment
        Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"

        $secpasswd = ConvertTo-SecureString $env.ASAZURE_TESTUSER_PWD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($env.ASAZURE_TESTUSER, $secpasswd)

		Synchronize-AzAsInstance -Instance $serverName -Database $env.ASAZURE_TESTDATABASE -PassThru
		
		Assert-NotNull $asAzureProfile "Login-AzAsAccount $rolloutEnvironment must not return null"
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-AnalysisServicesServerLoginWithSPN
{
    param
	(
		$rolloutEnvironment = $env.ASAZURE_TEST_ROLLOUT
	)
	try
	{
		
		$SecurePassword = ConvertTo-SecureString -String $env.ASAZURE_TESTAPP1_PWD -AsPlainText -Force
		$Credential_SPN = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $env.ASAZURE_TESTAPP1_ID, $SecurePassword
		$asAzureProfile = Login-AzAsAccount -RolloutEnvironment $rolloutEnvironment -ServicePrincipal -Credential $Credential_SPN -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47"
		Assert-NotNull $asAzureProfile "Login-AzAsAccount with Service Principal and password must not return null"
		$token = [Microsoft.Azure.Commands.AnalysisServices.Dataplane.AsAzureClientSession]::TokenCache.ReadItems()[0]
		Assert-NotNull $token "Login-AzAsAccount with Service Principal and password must not return null"

		
		$asAzureProfile = Login-AzAsAccount -RolloutEnvironment $rolloutEnvironment -ServicePrincipal -ApplicationId $env.ASAZURE_TESTAPP1_ID -CertificateThumbprint $env.ASAZURE_TESTAPP2_CERT_THUMBPRINT -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47"
		Assert-NotNull $asAzureProfile "Login-AzAsAccount with Service Principal and certificate thumbprint must not return null"
		$token = [Microsoft.Azure.Commands.AnalysisServices.Dataplane.AsAzureClientSession]::TokenCache.ReadItems()[0]
		Assert-NotNull $token "Login-AzAsAccount with Service Principal and certificate thumbprint must not return null"
	}
	finally
	{

	}
}


function Test-AnalysisServicesServerGateway
{
    try
    {
        
        $location = Get-AnalysisServicesLocation
        $resourceGroupName = Get-ResourceGroupName
        $serverName = Get-AnalysisServicesServerName
        $gatewayName = $env:GATEWAY_NAME
        $gateway = Get-AzResource -ResourceName $gatewayName -ResourceGroupName $resourceGroupName
        $serverCreated = New-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -Location $location -Sku S0 -GatewayResourceId $gateway.ResourceId -PassThru

        Assert-True {$serverCreated.ProvisioningState -like "Succeeded"}
        Assert-True {$serverCreated.State -like "Succeeded"}
        Assert-AreEqual $gateway.ResourceId $serverCreated.GatewayDetails.GatewayResourceId

        
        $serverUpdated = Set-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -DisassociateGateway -PassThru
        Assert-True {[string]::IsNullOrEmpty($serverUpdated.GatewayDetails.GatewayResourceId)}
    }
    finally
    {
        
        Invoke-HandledCmdlet -Command {Remove-AzAnalysisServicesServer -ResourceGroupName $resourceGroupName -Name $serverName -ErrorAction SilentlyContinue} -IgnoreFailures
        Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
    }
}