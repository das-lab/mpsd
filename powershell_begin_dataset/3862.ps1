













function Test-NewExchangeConnectionV4V6
{
	
	$kind = isDirect $false;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $false $false 0 0
	$sessionv6 = newIpV6Address $false $false 0 0
	Write-Debug "Created IPs $sessionv4"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
    $createdConnection = New-AzPeeringExchangeConnectionObject -PeeringDbFacilityId $facilityId -MaxPrefixesAdvertisedIPv4 $maxv4 -MaxPrefixesAdvertisedIPv6 $maxv6 -PeerSessionIPv4Address $sessionv4 -PeerSessionIPv6Address $sessionv6 -MD5AuthenticationKey $md5
	Assert-AreEqual $md5 $createdConnection.BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-AreEqual $maxv4 $createdConnection.BgpSession.MaxPrefixesAdvertisedV4
    Assert-AreEqual $maxv6 $createdConnection.BgpSession.MaxPrefixesAdvertisedv6
	Assert-AreEqual $sessionv4 $createdConnection.BgpSession.PeerSessionIPv4Address
    Assert-AreEqual $sessionv6 $createdConnection.BgpSession.PeerSessionIPv6Address
}

function Test-NewExchangeConnectionV4
{
	
	$kind = isDirect $false;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $false $false 0 0
	$sessionv6 = $null
	Write-Debug "Created IPs $sessionv4"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = $null
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
    $createdConnection = New-AzPeeringExchangeConnectionObject -PeeringDbFacilityId $facilityId -MaxPrefixesAdvertisedIPv4 $maxv4 -PeerSessionIPv4Address $sessionv4 -MD5AuthenticationKey $md5
	Assert-AreEqual $md5 $createdConnection.BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-AreEqual $maxv4 $createdConnection.BgpSession.MaxPrefixesAdvertisedV4
    Assert-AreEqual $maxv6 $createdConnection.BgpSession.MaxPrefixesAdvertisedv6
	Assert-AreEqual $sessionv4 $createdConnection.BgpSession.PeerSessionIPv4Address
    Assert-AreEqual $sessionv6 $createdConnection.BgpSession.PeerSessionIPv6Address
}

function Test-NewExchangeConnectionV6
{
	
	$kind = isDirect $false;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv6 = newIpV6Address $false $false 0 0
	Write-Debug "Created IPs $sessionv4"
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
    $createdConnection = New-AzPeeringExchangeConnectionObject -PeeringDbFacilityId $facilityId -MaxPrefixesAdvertisedIPv6 $maxv6 -PeerSessionIPv6Address $sessionv6 -MD5AuthenticationKey $md5
	Assert-AreEqual $md5 $createdConnection.BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-AreEqual $null $createdConnection.BgpSession.MaxPrefixesAdvertisedV4
    Assert-AreEqual $maxv6 $createdConnection.BgpSession.MaxPrefixesAdvertisedv6
	Assert-AreEqual $null $createdConnection.BgpSession.PeerSessionIPv4Address
    Assert-AreEqual $sessionv6 $createdConnection.BgpSession.PeerSessionIPv6Address
}

function Test-NewExchangeConnectionWrongV4
{
	
	$kind = isDirect $false;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $false $false 0 0
	$sessionv6 = newIpV6Address $false $false 0 0
	Write-Debug "Created IPs $sessionv4"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
	Assert-ThrowsContains {New-AzPeeringExchangeConnectionObject -PeeringDbFacilityId $facilityId -MaxPrefixesAdvertisedIPv4 $maxv4 -MaxPrefixesAdvertisedIPv6 $maxv6 -PeerSessionIPv4Address $sessionv4 -PeerSessionIPv6Address $sessionv6 -MD5AuthenticationKey $md5} "Parameter name: Invalid Prefix"
}