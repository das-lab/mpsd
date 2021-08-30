
function Test-DataLakeStoreTrustedIdProvider
{
    param
    (
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }
	
	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlStore -Name $accountName}

		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -Encryption ServiceManaged
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}

		$trustedIdName = getAssetName
		$trustedIdEndpoint = "https://sts.windows.net/6b04908c-b91f-40ce-8024-7ee8a4fd6150"

		
		Assert-AreEqual "Disabled" $accountCreated.TrustedIdProviderState

		$accountSet = Set-AdlStore -Name $accountName -TrustedIdProviderState Enabled
		Assert-AreEqual "Enabled" $accountSet.TrustedIdProviderState
		
		
		Add-AdlStoreTrustedIdProvider -AccountName $accountName -Name $trustedIdName -ProviderEndpoint $trustedIdEndpoint

		
		$result = Get-AdlStoreTrustedIdProvider -AccountName $accountName -Name $trustedIdName
		Assert-AreEqual $trustedIdName $result.Name
		Assert-AreEqual $trustedIdEndpoint $result.IdProvider

		
		Remove-AdlStoreTrustedIdProvider -AccountName $accountName -Name $trustedIdName

		
		Assert-Throws {Get-AdlStoreTrustedIdProvider -AccountName $accountName -Name $trustedIdName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeStoreFirewall
{
    param
    (
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }
	
	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlStore -Name $accountName}

		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -Encryption ServiceManaged
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}

		
		Assert-AreEqual "Disabled" $accountCreated.FirewallState 
		
		
		

		$accountSet = Set-AdlStore -Name $accountName -FirewallState "Enabled" -AllowAzureIpState "Enabled"

		Assert-AreEqual "Enabled" $accountSet.FirewallState
		
		
		

		$firewallRuleName = getAssetName
		$startIp = "127.0.0.1"
		$endIp = "127.0.0.2"
		
		Add-AdlStoreFirewallRule -AccountName $accountName -Name $firewallRuleName -StartIpAddress $startIp -EndIpAddress $endIp

		
		$result = Get-AdlStoreFirewallRule -AccountName $accountName -Name $firewallRuleName
		Assert-AreEqual $firewallRuleName $result.Name
		Assert-AreEqual $startIp $result.StartIpAddress
		Assert-AreEqual $endIp $result.EndIpAddress

		
		Remove-AdlStoreFirewallRule -AccountName $accountName -Name $firewallRuleName

		
		Assert-Throws {Get-AdlStoreFirewallRule -AccountName $accountName -Name $firewallRuleName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeStoreVirtualNetwork
{
    param
    (
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }
	
	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlStore -Name $accountName}

		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -Encryption ServiceManaged
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}

		
		Assert-AreEqual "Disabled" $accountCreated.FirewallState 

		$accountSet = Set-AdlStore -Name $accountName -FirewallState "Enabled" -AllowAzureIpState "Enabled"

		Assert-AreEqual "Enabled" $accountSet.FirewallState

		$virtualNetworkRuleName = getAssetName
		
		$vnetName1 = "vnet1"
		$virtualNetwork1 = CreateAndGetVirtualNetwork $resourceGroupName $vnetName1 $location
		$virtualNetworkSubnetId1 = $virtualNetwork1.Subnets[0].Id

		$vnetName2 = "vnet2"
		$virtualNetwork2 = CreateAndGetVirtualNetwork $resourceGroupName $vnetName2 $location
		$virtualNetworkSubnetId2 = $virtualNetwork2.Subnets[0].Id

		
		Add-AdlStoreVirtualNetworkRule -Account $accountName -Name $vnetName1 -SubnetId $virtualNetworkSubnetId1

		
		$result = Get-AdlStoreVirtualNetworkRule -Account $accountName -Name $vnetName1
		Assert-AreEqual $vnetName1 $result.VirtualNetworkRuleName
		Assert-AreEqual $virtualNetworkSubnetId1 $result.VirtualNetworkSubnetId

		
		Remove-AdlStoreVirtualNetworkRule -Account $accountName -Name $vnetName1

		
		Assert-Throws {Get-AdlStoreVirtualNetworkRule -Account $accountName -Name $vnetName1}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeStoreAccountTiers
{
    param
    (
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }
	
	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		$secondAccountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlStore -Name $accountName}

		
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}
		Assert-AreEqual "Consumption" $accountCreated.CurrentTier
		Assert-AreEqual "Consumption" $accountCreated.NewTier

		
		$accountUpdated = Set-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Tier Commitment1TB

		Assert-AreEqual "Consumption" $accountUpdated.CurrentTier
		Assert-AreEqual "Commitment1TB" $accountUpdated.NewTier

		
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $secondAccountName -Location $location -Tier Commitment1TB
		
		Assert-AreEqual "Commitment1TB" $accountCreated.CurrentTier
		Assert-AreEqual "Commitment1TB" $accountCreated.NewTier
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $secondAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeStoreAccount
{
    param
    (
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }
	
	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location

		
		Assert-False {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-False {Test-AdlStore -Name $accountName}

		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -Encryption ServiceManaged
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				Assert-True {$accountGet[0].Identity -ne $null}
				Assert-True {$accountGet[0].EncryptionConfig -ne $null}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}

		
		Assert-True {Test-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
		
		Assert-True {Test-AdlStore -Name $accountName}

		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		$accountUpdated = Set-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Tag $tagsToUpdate
    
		Assert-AreEqual $accountName $accountUpdated.Name
		Assert-AreEqual $location $accountUpdated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountUpdated.Type
		Assert-True {$accountUpdated.Id -like "*$resourceGroupName*"}
	
		Assert-NotNull $accountUpdated.Tags "Tags do not exists"
		Assert-NotNull $accountUpdated.Tags["TestTag"] "The updated tag 'TestTag' does not exist"

		
		[array]$accountsInResourceGroup = Get-AdlStore -ResourceGroupName $resourceGroupName
		Assert-True {$accountsInResourceGroup.Count -ge 1}
    
		$found = 0
		for ($i = 0; $i -lt $accountsInResourceGroup.Count; $i++)
		{
			if ($accountsInResourceGroup[$i].Name -eq $accountName)
			{
				$found = 1
				Assert-AreEqual $location $accountsInResourceGroup[$i].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountsInResourceGroup[$i].Type
				Assert-True {$accountsInResourceGroup[$i].Id -like "*$resourceGroupName*"}

				break
			}
		}
		Assert-True {$found -eq 1} "Account created earlier is not found when listing all in resource group: $resourceGroupName."

		
		[array]$accountsInSubscription = Get-AdlStore
		Assert-True {$accountsInSubscription.Count -ge 1}
		Assert-True {$accountsInSubscription.Count -ge $accountsInResourceGroup.Count}
    
		$found = 0
		for ($i = 0; $i -lt $accountsInSubscription.Count; $i++)
		{
			if ($accountsInSubscription[$i].Name -eq $accountName)
			{
				$found = 1
				Assert-AreEqual $location $accountsInSubscription[$i].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountsInSubscription[$i].Type
				Assert-True {$accountsInSubscription[$i].Id -like "*$resourceGroupName*"}
    
				break
			}
		}
		Assert-True {$found -eq 1} "Account created earlier is not found when listing all in subscription."

		
		$secondAccountName = Get-DataLakeStoreAccountName
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $secondAccountName -Location $location
		Assert-True {$accountCreated.EncryptionConfig -ne $null}
		Assert-AreEqual "ServiceManaged" $accountCreated.EncryptionConfig.Type
		Assert-AreEqual "Enabled" $accountCreated.EncryptionState

		
		Assert-Throws {Enable-AdlStoreKeyVault -ResourceGroupName $resourceGroupName -Account $secondAccountName}
		

		
		$thirdAccountName = Get-DataLakeStoreAccountName
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $thirdAccountName -Location $location -DisableEncryption
		Assert-True {[string]::IsNullOrEmpty(($accountCreated.EncryptionConfig.Type))}
		Assert-AreEqual "Disabled" $accountCreated.EncryptionState

		
		Assert-True {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $secondAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $thirdAccountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeStoreFileSystem
{
	param
    (
        $fileToCopy,
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }

	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DisableEncryption
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}

		
		$encodingFolder="/encodingFolder"
		$folderToCreate = "/adlspstestfolder"
		$emptyFilePath = "$folderToCreate\emptyfile.txt" 
		$contentFilePath = "$folderToCreate/contentfile.txt"
		$unicodeContentFilePath="$encodingFolder/unicodecontentfile.txt"
		$unicodetext="I am unicode text"
		$utf32ContentFilePath="$encodingFolder/utf32contentfile.txt"
		$utf32text="I am utf32 text"
		$concatFile = "$folderToCreate/concatfile.txt"
		$moveFile = "$folderToCreate/movefile.txt"
		$movefolder = "/adlspstestmovefolder"
		$importFile = "$folderToCreate/importfile.txt"
		$content = "Test file content! @ Azure PsTest01?"
		$summaryFolder="/adlspstestsummaryfolder"
		$subFolderToCreate = "$summaryFolder/Folder0"
		$subSubFolderToCreate = "$summaryFolder/Folder0/SubFolder0"
		$subFileToCreate = "$summaryFolder/File0"

		
		$result = New-AdlStoreItem -Account $accountName -path $folderToCreate -Folder
		Assert-NotNull $result "No value was returned on folder creation"
		$result = Get-AdlStoreItem -Account $accountName -path $folderToCreate
		Assert-NotNull $result "No value was returned on folder get"
		Assert-AreEqual "Directory" $result.Type

		
		$result = New-AdlStoreItem -Account $accountName -path $emptyFilePath
		Assert-NotNull $result "No value was returned on empty file creation"
		$result = Get-AdlStoreItem -Account $accountName -path $emptyFilePath
		$emptyFileCreationDate=$result.LastWriteTime 
		Assert-NotNull $result "No value was returned on empty file get"
		Assert-AreEqual "File" $result.Type
		Assert-AreEqual 0 $result.Length

		
		$result = New-AdlStoreItem -Account $accountName -path $contentFilePath -Value $content
		Assert-NotNull $result "No value was returned on content file creation"
		$result = Get-AdlStoreItem -Account $accountName -path $contentFilePath
		Assert-NotNull $result "No value was returned on content file get"
		Assert-AreEqual "File" $result.Type
		Assert-AreEqual $content.length $result.Length
		
		
		$result = New-AdlStoreItem -Account $accountName -path $unicodeContentFilePath
		Assert-NotNull $result "No value was returned on content file creation"
		Add-AdlStoreItemContent -Account $accountName -Path $unicodeContentFilePath -Value $unicodetext -Encoding Unicode
		$retrievedContent = Get-AdlStoreItemContent -Account $accountName -Path $unicodeContentFilePath -Encoding Unicode
		Assert-AreEqual $unicodetext $retrievedContent

		
		$result = New-AdlStoreItem -Account $accountName -path $utf32ContentFilePath -Value $utf32text -Encoding UTF32
		Assert-NotNull $result "No value was returned on content file creation"
		$retrievedContent = Get-AdlStoreItemContent -Account $accountName -Path $utf32ContentFilePath -Encoding UTF32
		Assert-AreEqual $utf32text $retrievedContent

		
		Assert-True {253402300800000 -ge $result.ExpirationTime -or 0 -le $result.ExpirationTime} 
		[DateTimeOffset]$timeToUse = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::GetVariable("absoluteTime", [DateTimeOffset]::UtcNow.AddSeconds(120))
		$result = Set-AdlStoreItemExpiry -Account $accountName -path $contentFilePath -Expiration $timeToUse
		Assert-NumAreInRange $timeToUse.UtcTicks $result.Expiration.UtcTicks 500000 
		
		
		$result = Set-AdlStoreItemExpiry -Account $accountName -path $contentFilePath
		Assert-True {253402300800000 -ge $result.ExpirationTime -or 0 -le $result.ExpirationTime} 

		
		$result = Get-AdlStoreChildItem -Account $accountName -path $folderToCreate
		Assert-NotNull $result "No value was returned on folder list"
		Assert-AreEqual 2 $result.length
		
		
		Add-AdlStoreItemContent -Account $accountName -Path $emptyFilePath -Value $content
		$result = Get-AdlStoreItem -Account $accountName -path $emptyFilePath
		Assert-NotNull $result "No value was returned on empty file get with content added"
		Assert-AreEqual "File" $result.Type
		Assert-AreEqual $content.length $result.Length
		
		
		$result = Join-AdlStoreItem -Account $accountName -Paths $emptyFilePath,$contentFilePath -Destination $concatFile
		Assert-NotNull $result "No value was returned on concat file"
		$result = Get-AdlStoreItem -Account $accountName -path $concatFile
		Assert-NotNull $result "No value was returned on concat file get"
		Assert-AreEqual "File" $result.Type
		Assert-AreEqual $($content.length*2) $result.Length
	
		
		$previewContent = Get-AdlStoreItemContent -Account $accountName -Path $concatFile
		Assert-AreEqual $($content.length*2) $previewContent.Length

		
		$previewContent = Get-AdlStoreItemContent -Account $accountName -Path $concatFile -Offset 2
		Assert-AreEqual $(($content.length*2) - 2) $previewContent.Length

		
		$previewContent = Get-AdlStoreItemContent -Account $accountName -Path $concatFile -Offset 2 -Length $content.Length
		Assert-AreEqual $content.length $previewContent.Length

		
		$previewHeadTailFile = "/headtail/filetest.txt"
		$headTailContent = @"
1
2
3
4
"@
		New-AdlStoreItem -Account $accountName -Path $previewHeadTailFile -Force -Value $headTailContent
		
		
		$headTailResult = Get-AdlStoreItemContent -Account $accountName -Path $previewHeadTailFile -Head 2
		Assert-AreEqual 2 $headTailResult.Length
		Assert-AreEqual 1 $headTailResult[0]
		Assert-AreEqual 2 $headTailResult[1]

		
		$headTailResult = Get-AdlStoreItemContent -Account $accountName -Path $previewHeadTailFile -Tail 2
		Assert-AreEqual 2 $headTailResult.Length
		Assert-AreEqual 3 $headTailResult[0]
		Assert-AreEqual 4 $headTailResult[1]

		
		$localFileInfo = Get-ChildItem $fileToCopy
		$result = Import-AdlStoreItem -Account $accountName -Path $fileToCopy -Destination $importFile
		Assert-NotNull $result "No value was returned on import file"
		$result = Get-AdlStoreItem -Account $accountName -path $importFile
		Assert-NotNull $result "No value was returned on import file get"
		Assert-AreEqual "File" $result.Type
		Assert-AreEqual $localFileInfo.length $result.Length
		
		
		$currentDir = Split-Path $fileToCopy
		$targetFile = Join-Path $currentDir "adlspstestdownload.txt"
		if(Test-Path $targetFile)
		{
			Remove-Item -path $targetFile -force -confirm:$false
		}

		Export-AdlStoreItem -Account $accountName -Path $concatFile -Destination $targetFile
		$downloadedFileInfo = Get-ChildItem $targetFile
		Assert-AreEqual $($content.length*2) $downloadedFileInfo.length
		Remove-Item -path $targetFile -force -confirm:$false

		
		$result = Move-AdlStoreItem -Account $accountName -Path $concatFile -Destination $moveFile
		Assert-NotNull $result "No value was returned on move file"
		$result = Get-AdlStoreItem -Account $accountName -path $moveFile
		Assert-NotNull $result "No value was returned on move file get"
		Assert-AreEqual "File" $result.Type
		Assert-AreEqual $($content.length*2) $result.Length
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $concatFile}
		
		
		$result = Move-AdlStoreItem -Account $accountName -Path $folderToCreate -Destination $moveFolder
		Assert-NotNull $result "No value was returned on move folder"
		$result = Get-AdlStoreItem -Account $accountName -path $moveFolder
		Assert-NotNull $result "No value was returned on move folder get"
		Assert-AreEqual "Directory" $result.Type
		Assert-AreEqual 0 $result.Length
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $folderToCreate}
		
		
		$result = New-AdlStoreItem -Account $accountName -path $summaryFolder -Folder
		Assert-NotNull $result "No value was returned on folder creation"
		$result = New-AdlStoreItem -Account $accountName -path $subFolderToCreate -Folder
		Assert-NotNull $result "No value was returned on folder creation"
		$result = New-AdlStoreItem -Account $accountName -path $subSubFolderToCreate -Folder
		Assert-NotNull $result "No value was returned on folder creation"
		New-AdlStoreItem -Account $accountName -Path $subFileToCreate -Force -Value $content
		$result = Get-AdlStoreChildItemSummary -Account $accountName -Path $summaryFolder
		Assert-AreEqual $result.Length $content.Length
		
		Assert-AreEqual $result.FileCount 1

		
		$targetFile = Join-Path $currentDir "DuOutputAlias"
		Export-AdlStoreChildItemProperties -Account $accountName -Path $summaryFolder -OutputPath $targetFile -GetDiskUsage -IncludeFile
		$result = Get-Item -Path $targetFile
		Assert-NotNull $result "No file was created on export properties"
        Remove-Item -Path $targetFile

		
		Assert-True {Remove-AdlStoreItem -Account $accountName -paths "$moveFolder/movefile.txt" -force -passthru } "Remove File Failed"
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $moveFile}

		
		Assert-True {Remove-AdlStoreItem -Account $accountName -paths $moveFolder -force -recurse -passthru} "Remove folder failed"
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $moveFolder}
    	Assert-True {Remove-AdlStoreItem -Account $accountName -paths $summaryFolder -force -recurse -passthru} "Remove folder failed"
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $summaryFolder}
		Assert-True {Remove-AdlStoreItem -Account $accountName -paths $encodingFolder -force -recurse -passthru} "Remove folder failed"
    
		
		Assert-True {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-DataLakeStoreFileSystemPermissions
{
	param
    (
        $location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }

	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location -DisableEncryption
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}
		
		
		$folderToCreate = "/aclRecurseFolder"

		
		$aceUserId = "027c28d5-c91d-49f0-98c5-d10134b169b3"

		
        New-AdlStoreItem -Account $accountName -Path "/temp"
        $prevOwner=Get-AdlStoreItemOwner -Account $accountName -Path "/temp" -Type User
        $prevGroup=Get-AdlStoreItemOwner -Account $accountName -Path "/temp" -Type Group
        $currentOwner=Set-AdlStoreItemOwner -Account $accountName -Path "/temp" -Type User -Id $aceUserId -PassThru
        $currentGroup=Get-AdlStoreItemOwner -Account $accountName -Path "/temp" -Type Group
        Assert-AreEqual $aceUserId $currentOwner
        Assert-AreNotEqual $prevOwner $currentOwner
        Assert-AreEqual $prevGroup $currentGroup
        Remove-AdlStoreItem -Account $accountName -paths "/temp" -force

		
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-NotNull $result "Did not get any result from ACL get" 
		Assert-True {$result.Count -ge 0} "UserAces is negative or null"
 		$currentCount = $result.Count
 		$result.Add("user:$aceUserId`:rwx")
 		$toRemove = $result[$result.Count -1]
		Assert-AreEqual $aceUserId $toRemove.Id

		Set-AdlStoreItemAcl -Account $accountName -path "/" -Acl $result
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		
		Assert-AreEqual $($currentCount+1) $result.Count
 		$found = $false
 		for($i = 0; $i -lt $result.Count; $i++)
 		{
 			if($result[$i].Id -like $aceUserId)
 			{
 				$found = $true
 				$result.RemoveAt($i)
 				break
 			}
 		}
 
 		Assert-True { $found } "Failed to remove the element: $($toRemove.Entry)"

		Set-AdlStoreItemAcl -Account $accountName -path "/" -Acl $result
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount) $result.Count

		
		Set-AdlStoreItemAclEntry -Account $accountName -path "/" -AceType User -Id $aceUserId -Permissions All
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount+1) $result.Count
		
		
		Remove-AdlStoreItemAclEntry -Account $accountName -path "/" -AceType User -Id $aceUserId
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount) $result.Count
		
		
		Set-AdlStoreItemAclEntry -Account $accountName -path "/" -Acl $([string]::Format("user:{0}:rwx", $aceUserId))
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount+1) $result.Count
		
		
		Remove-AdlStoreItemAclEntry -Account $accountName -path "/" -Acl $([string]::Format("user:{0}:---", $aceUserId))
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount) $result.Count

		
		$result = New-AdlStoreItem -Account $accountName -path $folderToCreate -Folder
		Assert-NotNull $result "No value was returned on folder creation"
		
		
		Set-AdlStoreItemAclEntry -Account $accountName -path "/" -AceType User -Permissions All -Id $aceUserId -Recurse
		$result = Get-AzDataLakeStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount+1) $result.Count

		
		$targetFile = "./ScenarioTests/acloutput"
		Export-AdlStoreChildItemProperties -Account $accountName -Path "/" -OutputPath $targetFile -GetAcl -IncludeFile
        $result = Get-Item -Path $targetFile
		Assert-NotNull $result "No file was created on export properties"
        Remove-Item -Path $targetFile

		
		Remove-AdlStoreItemAclEntry -Account $accountName -path "/" -AceType User -Id $aceUserId -Recurse
		$result = Get-AzDataLakeStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual $($currentCount) $result.Count

		
		Remove-AdlStoreItemAcl -Account $accountName -Path "/" -Force -Default
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual 4 $result.Count
		Remove-AdlStoreItemAcl -Account $accountName -Path "/" -Force
		$result = Get-AdlStoreItemAclEntry -Account $accountName -path "/"
		Assert-AreEqual 3 $result.Count

		
		$permission = Get-AdlStoreItemPermission -Account $accountName -path "/"
		Assert-AreEqual 770 $permission
		Set-AdlStoreItemPermission -Account $accountName -path "/" -Permission 777 | Out-Null
		$permission = Get-AdlStoreItemPermission -Account $accountName -path "/"
		Assert-AreEqual 777 $permission

		
		Assert-True {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function Test-NegativeDataLakeStoreAccount
{
    param
    (
        $location,
        $fakeaccountName = "psfakedataLakeaccounttest"
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }
	
	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName
		New-AzResourceGroup -Name $resourceGroupName -Location $location
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location
    
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
        
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account not in succeeded state even after 30 min."
		}

		
		Assert-Throws {New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location}

		
		$tagsToUpdate = @{"TestTag" = "TestUpdate"}
		Assert-Throws {Set-AdlStore -ResourceGroupName $resourceGroupName -Name $fakeaccountName -Tag $tagsToUpdate}

		
		Assert-Throws {Get-AdlStore -ResourceGroupName $resourceGroupName -Name $fakeaccountName}

		
		Assert-True {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru}

		
		Assert-Throws {Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}


function CreateAndGetVirtualNetwork ($resourceGroupName, $vnetName, $location = "westcentralus")
{
	$subnetName = "Public"

	$addressPrefix = "10.0.0.0/24"
	$serviceEndpoint = "Microsoft.AzureActiveDirectory"

	$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $addressPrefix -ServiceEndpoint $serviceEndpoint
	$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

	$getVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName

	return $getVnet
}


function Test-AdlsEnumerateAndRestoreDeletedItem
{
	param
    (
        $fileToCopy,
		$location
    )

    if ([string]::IsNullOrEmpty($location))
    {
        $location = Get-Location -providerNamespace "Microsoft.CognitiveServices" -resourceType "accounts" -preferredLocation "West US";
    }

	try
	{
		
		$resourceGroupName = Get-ResourceGroupName
		$accountName = Get-DataLakeStoreAccountName + "-c12" 
		New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
		$accountCreated = New-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Location $location
		Assert-AreEqual $accountName $accountCreated.Name
		Assert-AreEqual $location $accountCreated.Location
		Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountCreated.Type
		Assert-True {$accountCreated.Id -like "*$resourceGroupName*"}

		
		for ($i = 0; $i -le 60; $i++)
		{
			[array]$accountGet = Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName
			if ($accountGet[0].ProvisioningState -like "Succeeded")
			{
				Assert-AreEqual $accountName $accountGet[0].Name
				Assert-AreEqual $location $accountGet[0].Location
				Assert-AreEqual "Microsoft.DataLakeStore/accounts" $accountGet[0].Type
				Assert-True {$accountGet[0].Id -like "*$resourceGroupName*"}
				break
			}

			Write-Host "account not yet provisioned. current state: $($accountGet[0].ProvisioningState)"
			[Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(30000)
			Assert-False {$i -eq 60} " Data Lake Store account is not in succeeded state even after 30 min."
		}

		
		
		$folderToCreate1 = "/adlfolderTest1"
		$folderToCreate2 = "/adlfolderTest2"
		$fileToCreate1 = "/adlfolderTest1/adlfile1"
		$fileToCreate2 = "/adlfolderTest2/adlfile2"

		
		$result = New-AdlStoreItem -Account $accountName -path $folderToCreate1 -Folder
		Assert-NotNull $result "No value was returned on folder creation"

		$result = New-AdlStoreItem -Account $accountName -path $folderToCreate2 -Folder
		Assert-NotNull $result "No value was returned on folder creation"
		
		
		$result = New-AdlStoreItem -Account $accountName -path $fileToCreate1
		Assert-NotNull $result "No value was returned on empty file creation"
		$result = New-AdlStoreItem -Account $accountName -path $fileToCreate2
		Assert-NotNull $result "No value was returned on empty file creation"
		
	    
		Assert-True {Remove-AdlStoreItem -Account $accountName -paths $fileToCreate1 -force -passthru } "Remove File Failed"
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $fileToCreate1}
		Assert-True {Remove-AdlStoreItem -Account $accountName -paths $fileToCreate2 -force -passthru } "Remove File Failed"
		Assert-Throws {Get-AdlStoreItem -Account $accountName -path $fileToCreate2}
		
		
		$out = Get-AdlStoreDeletedItem -Account $accountName -filter "adlfolderTest1" -Count 1000
		foreach($item in $out)
		{
			Assert-True { Restore-AdlStoreDeletedItem -Account $accountName -Path $item.TrashDirPath -Destination $item.OriginalPath -Type "file" -Force -Passthru}
		}

		$out = Get-AdlStoreDeletedItem -Account $accountName -filter "adlfolderTest2" -Count 1000
		foreach($item in $out)
		{
			Assert-True { Restore-AdlStoreDeletedItem -Account $accountName $item -Force -Passthru}
		}
    
		
		Assert-True {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -PassThru} "Remove Account failed."

		
		Assert-Throws {Get-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName}
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AdlStore -ResourceGroupName $resourceGroupName -Name $accountName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}