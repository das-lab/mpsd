













function Test-NewDirectConnectionWithV4V6
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $true $true 0 0
	$sessionv6 = newIpV6Address $true $true 0 0
	Write-Debug "Created IPs $sessionv4 $SessionPrefixV6"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
    $createdConnection = New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV4 $sessionv4 -SessionPrefixV6 $sessionv6 -MaxPrefixesAdvertisedIPv4 $maxv4 -MaxPrefixesAdvertisedIPv6 $maxv6 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5
    Assert-AreEqual $md5 $createdConnection.BgpSession.Md5AuthenticationKey
    Assert-AreEqual $bandwidth $createdConnection.BandwidthInMbps 
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-AreEqual $sessionv4 $createdConnection.BgpSession.SessionPrefixV4
    Assert-AreEqual $sessionv6 $createdConnection.BgpSession.SessionPrefixV6
	Assert-AreEqual $false $createdConnection.UseForPeeringService
	Assert-AreEqual "Peer" $createdConnection.SessionAddressProvider

		removePeerAsn $asn
	

}

function Test-NewDirectConnectionWithV4
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Amsterdam"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $true $true 0 0
	Write-Debug "Created IPs $sessionv4"
	$maxv4 = maxAdvertisedIpv4
	Write-Debug "Created maxAdvertised $maxv4"
	
    $createdConnection = New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV4 $sessionv4 -MaxPrefixesAdvertisedIPv4 $maxv4 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5
	Get-AzPeerAsn
    Assert-AreEqual $md5 $createdConnection.BgpSession.Md5AuthenticationKey
    Assert-AreEqual $bandwidth $createdConnection.BandwidthInMbps 
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-AreEqual $sessionv4 $createdConnection.BgpSession.SessionPrefixV4
    Assert-Null $createdConnection.BgpSession.SessionPrefixV6
	Assert-AreEqual $false $createdConnection.UseForPeeringService
	Assert-AreEqual "Peer" $createdConnection.SessionAddressProvider

		removePeerAsn $asn
	
}

function Test-NewDirectConnectionWithV6
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv6 = newIpV6Address $true $true 0 0
	Write-Debug "Created IPs $SessionPrefixV6"
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv6"
	
    $createdConnection = New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV6 $sessionv6 -MaxPrefixesAdvertisedIPv6 $maxv6 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5
    Assert-AreEqual $md5 $createdConnection.BgpSession.Md5AuthenticationKey
    Assert-AreEqual $bandwidth $createdConnection.BandwidthInMbps 
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-Null $createdConnection.BgpSession.SessionPrefixV4
    Assert-AreEqual $sessionv6 $createdConnection.BgpSession.SessionPrefixV6
	Assert-AreEqual $false $createdConnection.UseForPeeringService
	Assert-AreEqual "Peer" $createdConnection.SessionAddressProvider

		removePeerAsn $asn
	
}

function Test-NewDirectConnectionNoSession
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $true $true 0 0
	$sessionv6 = newIpV6Address $true $true 0 0
	Write-Debug "Created IPs $sessionv4 $SessionPrefixV6"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
    $createdConnection = New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -BandwidthInMbps $bandwidth -UseForPeeringService
    Assert-AreEqual $bandwidth $createdConnection.BandwidthInMbps 
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-Null $createdConnection.BgpSession
	Assert-AreEqual $true $createdConnection.UseForPeeringService
	Assert-AreEqual "Peer" $createdConnection.SessionAddressProvider

		removePeerAsn $asn
}

function Test-NewDirectConnectionHighBandwidth
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	
	$bandwidth = getBandwidth
	
	$bandwidth = [int]$bandwidth * 10
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $true $true 0 0
	$sessionv6 = newIpV6Address $true $true 0 0
	Write-Debug "Created IPs $sessionv4 $SessionPrefixV6"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
	Assert-ThrowsContains { New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV6 $sessionv6 -MaxPrefixesAdvertisedIPv6 $maxv6 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5 } "The $bandwidth argument is greater than the maximum allowed range of 100000"

		removePeerAsn $asn
	
}

function Test-NewDirectConnectionLowBandwidth
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	
	$wrongBandwidth = 0
	
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$sessionv4 = newIpV4Address $true $true 0 0
	$sessionv6 = newIpV6Address $true $true 0 0
	Write-Debug "Created IPs $sessionv4 $SessionPrefixV6"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
	Assert-ThrowsContains {New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV6 $sessionv6 -MaxPrefixesAdvertisedIPv6 $maxv6 -BandwidthInMbps $wrongBandwidth -MD5AuthenticationKey $md5} "The $wrongBandwidth argument is less than the minimum allowed range of 10000"

		removePeerAsn $asn
	
}

function Test-NewDirectConnectionWrongV6
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	
	$sessionv6 = newIpV6Address $true $true 0 0
	$wrongv6 = changeIp $sessionv6 $true 1 $true
	Write-Debug "Created IPs wrong $wrongv6 correct $sessionv6"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
	Assert-ThrowsContains {New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV6 $wrongv6 -MaxPrefixesAdvertisedIPv6 $maxv6 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5} "Invalid Prefix: $wrongv6, must be"

		removePeerAsn $asn
	
}

function Test-NewDirectConnectionWrongV4
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	
	$sessionv4 = newIpV4Address $true $true 0 0
	$wrongv4 = changeIp $sessionv4 $false 1 $true
	Write-Debug "Created IPs wrong $wrongv4 correct $sessionv4"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
	Assert-ThrowsContains {New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV4 $wrongv4 -MaxPrefixesAdvertisedIPv4 $maxv4 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5.ToString} "Invalid Prefix: $wrongv4, must be "

		removePeerAsn $asn
	
}


function Test-NewDirectConnectionWithMicrosoftIpProvidedAddress
{
	$asn = makePeerAsn 65000
	
	$kind = isDirect $true;
	$loc = "Los Angeles"
	$peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	Write-Debug "Creating Connection at $facilityId"
	
    $createdConnection = New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -MicrosoftProvidedIPAddress -BandwidthInMbps $bandwidth -UseForPeeringService
    Assert-AreEqual $bandwidth $createdConnection.BandwidthInMbps 
	Assert-AreEqual $facilityId $createdConnection.PeeringDBFacilityId 
    Assert-AreEqual $null $createdConnection.BgpSession
    Assert-AreEqual $true $createdConnection.UseForPeeringService
	Assert-AreEqual "Microsoft" $createdConnection.SessionAddressProvider
	removePeerAsn $asn
	
}


function Test-NewDirectConnectionWithNoPeeringFacility
{
$asn = makePeerAsn 65000
	Assert-ThrowsContains {New-AzPeeringDirectConnectionObject -PeeringDbFacilityId} "Missing an argument for parameter 'PeeringDBFacilityId'"
		removePeerAsn $asn
}


function Test-NewDirectConnectionWithNoBgpSession
{
	$asn = makePeerAsn 65000
	$peeringLocation = Get-AzPeeringLocation -Kind Direct
	$index = Get-Random -Maximum ($peeringLocation.Count -1) -Minimum 1
	$facilityId = $peeringLocation[$index].PeeringDBFacilityId
	$bandwidth = getBandwidth
	$connection = New-AzPeeringDirectConnectionObject -PeeringDBFacilityId $facilityId -BandwidthInMbps $bandwidth
	Assert-AreEqual $facilityId $connection.PeeringDBFacilityId
	Assert-AreEqual $bandwidth $connection.BandwidthInMbps
	Assert-AreEqual "Peer" $connection.SessionAddressProvider

		removePeerAsn $asn
	
}


function Test-NewDirectConnectionWithMicrosoftSession
{
	$asn = makePeerAsn 65000
	$peeringLocation = Get-AzPeeringLocation -Kind Direct
	$index = Get-Random -Maximum ($peeringLocation.Count -1) -Minimum 1
	$facilityId = $peeringLocation[$index].PeeringDBFacilityId
	$bandwidth = getBandwidth
	$connection = New-AzPeeringDirectConnectionObject -PeeringDBFacilityId $facilityId -BandwidthInMbps $bandwidth -MicrosoftProvidedIPAddress
	Assert-AreEqual $facilityId $connection.PeeringDBFacilityId
	Assert-AreEqual $bandwidth $connection.BandwidthInMbps
	Assert-AreEqual "Microsoft" $connection.SessionAddressProvider
	Assert-False {$connection.UseForPeeringService}

		removePeerAsn $asn
	
}

function Test-NewDirectConnectionWithMicrosoftSessionWithPeeringService
{
	$asn = makePeerAsn 65000
	$peeringLocation = Get-AzPeeringLocation -Kind Direct
	$index = Get-Random -Maximum ($peeringLocation.Count -1) -Minimum 1
	$facilityId = $peeringLocation[$index].PeeringDBFacilityId
	$bandwidth = getBandwidth
	$connection = New-AzPeeringDirectConnectionObject -PeeringDBFacilityId $facilityId -BandwidthInMbps $bandwidth -MicrosoftProvidedIPAddress -UseForPeeringService
	Assert-AreEqual $facilityId $connection.PeeringDBFacilityId
	Assert-AreEqual $bandwidth $connection.BandwidthInMbps
	Assert-AreEqual "Microsoft" $connection.SessionAddressProvider
	Assert-True {$connection.UseForPeeringService}

		removePeerAsn $asn
	
}


function Test-NewDirectConnectionWithMicrosoftSessionInvalidV4
{
	$asn = makePeerAsn 65000
	$peeringLocation = Get-AzPeeringLocation -Kind Direct
	$index = Get-Random -Maximum ($peeringLocation.Count -1) -Minimum 1
	$facilityId = $peeringLocation[$index].PeeringDBFacilityId
	$bandwidth = getBandwidth
	Assert-ThrowsContains {New-AzPeeringDirectConnectionObject -PeeringDBFacilityId $facilityId -BandwidthInMbps $bandwidth -SessionPrefixV4 4.4.4.4 -MicrosoftProvidedIPAddress} "Parameter set cannot be resolved using the specified named parameters"

		removePeerAsn $asn
	
}


function Test-NewDirectConnectionWithMicrosoftSessionInvalidV6
{
	$asn = makePeerAsn 65000
	$peeringLocation = Get-AzPeeringLocation -Kind Direct
	$index = Get-Random -Maximum ($peeringLocation.Count -1) -Minimum 1
	$facilityId = $peeringLocation[$index].PeeringDBFacilityId
	$bandwidth = getBandwidth
	Assert-ThrowsContains {New-AzPeeringDirectConnectionObject -PeeringDBFacilityId $facilityId -BandwidthInMbps $bandwidth -SessionPrefixV6 "fe01::40ef" -MicrosoftProvidedIPAddress} "Parameter set cannot be resolved using the specified named parameters"

		removePeerAsn $asn
	
}