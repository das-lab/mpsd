














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-ProviderLocation($provider)
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = $provider.Split("/")[0]  
		if($provider.Contains("/"))  
		{  
			$type = $provider.Substring($namespace.Length + 1)  
			$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}  
  
			if ($location -eq $null) 
			{  
				return "West US"  
			} else 
			{  
				return $location.Locations[0]  
			}  
		}
		
		return "West US"
	}

	return "WestUS"
}


function TestSetup-CreateResourceGroup
{
    $resourceGroupName = getAssetName
	$rglocation = Get-ProviderLocation "North Europe"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $rglocation -Force
	return $resourceGroup
}


function TestSetup-CreateProfile($profileName, $resourceGroupName, $routingMethod = "Performance")
{
	$relativeName = getAssetName

	$profile = New-AzTrafficManagerProfile -Name $profileName -ResourceGroupName $resourceGroupName -RelativeDnsName $relativeName -Ttl 50 -TrafficRoutingMethod $routingMethod -MonitorProtocol "HTTP" -MonitorPort 80 -MonitorPath "/testpath.asp" -ProfileStatus "Enabled"

	return $profile
}


function TestSetup-AddEndpoint($endpointName, $profile)
{
	$profile = Add-AzTrafficManagerEndpointConfig -EndpointName $endpointName -TrafficManagerProfile $profile -Type "ExternalEndpoints" -Target "www.contoso.com" -EndpointStatus "Enabled" -EndpointLocation "North Europe"

	return $profile
}


function TestCleanup-RemoveResourceGroup($rgname)
{
    Remove-AzResourceGroup -Name $rgname -Force
}
