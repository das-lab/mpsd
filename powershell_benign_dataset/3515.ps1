














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


function TestSetup-CreateResourceGroup
{
    $resourceGroupName = Get-ResourceGroupName
	$rglocation = "West US"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $rglocation
	return $resourceGroup
}


function TestSetup-CreateVirtualNetwork($resourceGroup)
{
    $virtualNetworkName = Get-VirtualNetworkName
	$location = Get-Location -ProviderNamespace "microsoft.network" -ResourceType "virtualNetworks" -PreferredLocation "West US"  
    $virtualNetwork = New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -AddressPrefix "10.0.0.0/8"
	return $virtualNetwork
}

function Get-RandomZoneName
{
	$prefix = getAssetName;
	return $prefix + ".pstest.test" ;
}

function Get-RandomLinkName
{
	$prefix = getAssetName;
	return $prefix + ".testlink" ;
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

function Create-VirtualNetworkLink([bool] $registrationEnabled)
{
	$zoneName = Get-RandomZoneName
	$linkName = Get-RandomLinkName
    $resourceGroup = TestSetup-CreateResourceGroup

	$createdZone = New-AzPrivateDnsZone -Name $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Tag @{tag1="value1"}
	$createdVirtualNetwork = TestSetup-CreateVirtualNetwork $resourceGroup
	if($registrationEnabled)
	{
		$createdLink = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Name $linkName -Tag @{tag1="value1"} -VirtualNetworkId $createdVirtualNetwork.Id -EnableRegistration
	}
	else
	{
		$createdLink = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Name $linkName -Tag @{tag1="value1"} -VirtualNetworkId $createdVirtualNetwork.Id
	}
	return $createdLink
}