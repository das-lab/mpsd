














function Test-SetNewIP {
    $peer = Get-AzPeering -ResourceGroupName testCarrier -Name "NewExchangePeeringCVS2160"
    $peerIpAddress = $peer.Connections[0].BgpSession.PeerSessionIPv4Address
    $offset = getPeeringVariable "offSet" (Get-Random -Maximum 100 -Minimum 1 | % { $_ * 2 } )
    $newIpAddress = getPeeringVariable "newIpAddress" (changeIp "$peerIpAddress/32" $false $offset $false )
    $peer.Connections[0] = $peer.Connections[0] | Set-AzPeeringExchangeConnectionObject -PeerSessionIPv4Address $newIpAddress
    Assert-ThrowsContains { $peering = $peer | Update-AzPeering } "updates are not yet supported"
}

function Test-SetNewIPv6 {
    $peer = Get-AzPeering -ResourceGroupName testCarrier -Name "NewExchangePeeringCVS2160"
    $peerIpAddress = getPeeringVariable "IpAddress" (newIpV6Address $false $false 0 0)
    $peer.Connections[0] = $peer.Connections[0] | Set-AzPeeringExchangeConnectionObject -PeerSessionIPv6Address $peerIpAddress
	Assert-ThrowsContains { $peering = $peer | Update-AzPeering } "InternalServerError"
}

function Test-SetNewBandwidth {
    $peers = Get-AzPeering -Kind Direct
    $peer = $peers | Select-Object -First 1
    $bandwidth = $peer.Connections[0].BandwidthInMbps
    $bandwidth = getPeeringVariable "newBandwidth" (Get-Random -Maximum 2 -Minimum 1 | % { $_ * 10000 } | % { $_ + $bandwidth })
    $peer.Connections[0] = $peer.Connections[0] | Set-AzPeeringDirectConnectionObject -BandwidthInMbps $bandwidth 
     Assert-ThrowsContains { $setPeer = $peer | Update-AzPeering } "ErrorCode"
}

function Test-SetNewMd5Hash {
    $peers = Get-AzPeering -Kind Exchange 
	$peer = $peers | Select-Object -First 1
    $hash = getHash
    $connection = $peer.Connections[0] | Set-AzPeeringExchangeConnectionObject -MD5AuthenticationKey $hash
    Assert-ThrowsContains { $setPeer = Update-AzPeering -ResourceId $peer.Id -ExchangeConnection $connection } "ErrorCode"
}