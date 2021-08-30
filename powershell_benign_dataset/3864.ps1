













function Test-GetLegacyKindExchangeAshburn
{
try{

	$peerAsn = makePeerAsn 15224;
    $legacy = Get-AzLegacyPeering -Kind Exchange -PeeringLocation Ashburn 
	Assert-NotNull $legacy
	Assert-True {$legacy.Count -ge 1}
	}finally {
			$isRemoved = Remove-AzPeerAsn -Name $peerAsn.Name -Force -PassThru
		Assert-True {$isRemoved}
	}
}


function Test-GetLegacyKindDirectAmsterdam
{
try{

	$peerAsn = makePeerAsn 20940
    $legacy = Get-AzLegacyPeering -Kind Direct -PeeringLocation Amsterdam 
	Assert-NotNull $legacy
	Assert-True {$legacy.Count -ge 1}
	}
	finally {
		$isRemoved = Remove-AzPeerAsn -Name $peerAsn.Name -Force -PassThru
		Assert-True {$isRemoved}
	}
}

