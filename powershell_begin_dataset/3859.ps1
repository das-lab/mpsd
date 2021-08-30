













function Test-ConvertLegacyKindExchangeAshburn {
    try {
        
        $peerAsn = makePeerAsn 11164;
        $name = getPeeringVariable "Name" "AS11164_Ashburn_Exchange"
        $rg = getPeeringVariable "ResourceGroupName" "Building40"
        $legacy = Get-AzLegacyPeering -Kind Exchange -PeeringLocation Ashburn 
		Assert-NotNull $peerAsn.Id
        Assert-NotNull $legacy
        Assert-True { $legacy.Count -ge 1 }
        $peering = $legacy | New-AzPeering -ResourceGroupName $rg -Name $name -PeerAsnResourceId $peerAsn.Id -Tag @{ "tfs_813288" = "Approved" }
        $peering = Get-AzPeering -ResourceGroupName $rg -Name $name
        Assert-NotNull $peering
    }
    finally {
        $isRemoved = Remove-AzPeerAsn -Name $peerAsn.Name -Force -PassThru
        Assert-True { $isRemoved }
    }
}


function Test-ConvertLegacyKindExchangeAmsterdamWithNewConnection {
    try {
        
        $peerAsn = makePeerAsn 15224
        $name = getPeeringVariable "Name" "AS15224_Amsterdam_Exchange"
        $rg = getPeeringVariable "ResourceGroupName" "Building40"
        $legacy = Get-AzLegacyPeering -Kind Exchange -PeeringLocation Amsterdam 
        Assert-NotNull $legacy
        Assert-True { $legacy.Count -ge 1 }
        
        
        $ipaddress = getPeeringVariable "ipaddress" " 80.249.211.62 "
        $facilityId = 26
        $maxv4 = maxAdvertisedIpv4
        $connection = New-AzPeeringExchangeConnectionObject -PeeringDbFacilityId $facilityId -MaxPrefixesAdvertisedIPv4 $maxv4 -PeerSessionIPv4Address $ipaddress
        $peering = $legacy | New-AzPeering -ResourceGroupName $rg -Name $name -PeerAsnResourceId $peerAsn.Id -ExchangeConnection $connection -Tag @{ "tfs_813288" = "Approved" }
    }
    finally {
        $isRemoved = Remove-AzPeerAsn -Name $peerAsn.Name -Force -PassThru
        Assert-True { $isRemoved }
    }
}

