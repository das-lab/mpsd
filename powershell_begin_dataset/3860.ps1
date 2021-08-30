













function Test-NewExchangePeering()
{

	$resourceName = getAssetName "NewExchangePeeringCVS"
    $resourceGroup = "testCarrier"
    $peeringLocation = "Berlin"
	$kind = IsDirect $false
	Write-Debug "Getting the Facility Information"
	try {
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn.Id
	$facility = Get-AzPeeringLocation -PeeringLocation $peeringLocation -Kind $kind
	$microsoftIpAddressV4 = $facility[0].MicrosoftIPv4Address.Split(',') | Select-Object -First 1
	$microsoftIpAddressV6 = $facility[0].MicrosoftIPv6Address.Split(',') | Select-Object -First 1
	$facilityId = $facility[0].PeeringDBFacilityId
	$peeringLocation = $facility[0].PeeringLocation
	Write-Debug "Creating Connections"
	$connection1 = NewExchangeConnectionV4V6 $facilityId $microsoftIpAddressV4 $microsoftIpAddressV6
	$connection2 = NewExchangeConnectionV4V6 $facilityId $microsoftIpAddressV4 $microsoftIpAddressV6
	Write-Debug "Created $connection1 $connection1"
    $tags = @{"tfs_$randNum" = "Active"; "tag2" = "value2"}
	Write-Debug "Tags: $tags";
	Write-Debug "Creating Resource $resourceName"
    $createdPeering = New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation -PeerAsnResourceId $asn -ExchangeConnection $connection1,$connection2 -Tag $tags
	Assert-NotNull $createdPeering
	Assert-NotNull $createdPeering.Connections.ConnectionIdentifier
	}
	finally{
		$isRemoved = Remove-AzPeerAsn -Name $peerAsn.Name -Force -PassThru;
		Assert-True {$isRemoved}
	}
}

function Test-NewExchangePeeringPipe
{

	$resourceName = getAssetName "NewExchangePeeringCVS"
    $resourceGroup = "testCarrier"
    $peeringLocation = "Amsterdam"
	$kind = IsDirect $false
	try{
	Write-Debug "Getting the Facility Information"
	$facility = Get-AzPeeringLocation -PeeringLocation $peeringLocation -Kind $kind
	$microsoftIpAddressV4 = $facility[0].MicrosoftIPv4Address
	$microsoftIpAddressV6 = $facility[0].MicrosoftIPv6Address
	$facilityId = $facility[0].PeeringDBFacilityId
	$peeringLocation = $facility[0].PeeringLocation
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn.Id
	Write-Debug "Creating Connections"
	$connection1 = NewExchangeConnectionV4V6 $facilityId $microsoftIpAddressV4 $microsoftIpAddressV6
    $tags = @{"tfs_$randNum" = "Active"; "tag2" = "value2"}
	Write-Debug "Creating Resource $resourceName"
	$createdPeering = New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation -PeerAsnResourceId $asn -Tag $tags -ExchangeConnection $connection1
	Assert-NotNull $createdPeering
	Assert-NotNull $createdPeering.Connections.ConnectionIdentifier
	}
	catch{}
	finally{
	$isRemoved = Remove-AzPeerAsn -Name $peerAsn.Name -Force -PassThru
		Assert-True {$isRemoved}
	}
}
