














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-VirtualNetworkName
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
    $resourceGroupName = Get-ResourceGroupName
	$rglocation = Get-ProviderLocation "microsoft.compute"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $rglocation
	return $resourceGroup
}


function TestSetup-CreateVirtualNetwork($resourceGroup)
{
    $virtualNetworkName = Get-VirtualNetworkName
	$location = Get-ProviderLocation "microsoft.network/virtualNetworks"
    $virtualNetwork = New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -AddressPrefix "10.0.0.0/8"
	return $virtualNetwork
}

function Get-RandomZoneName
{
	$prefix = getAssetName;
	return $prefix + ".pstest.test" ;
}

function Get-TxtOfSpecifiedLength([int] $length)
{
	$returnValue = "";
	for ($i = 0; $i -lt $length ; $i++)
	{
		$returnValue += "a";
	}
	return $returnValue;
}