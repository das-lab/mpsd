













function Test-GetLocationKindDirect {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Direct 
        Assert-NotNull $location
        Assert-True { $location.Count -gt 30 }
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}

function Test-GetLocationKindExchange {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Exchange 
        Assert-NotNull $location
        Assert-True { $location.Count -gt 60 }
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}

function Test-GetLocationKindExchangeSeattle {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Exchange -PeeringLocation seattle
        Assert-NotNull $location
        Assert-AreEqual 5 $location.Count
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}

function Test-GetLocationKindDirectSeattle {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Direct -DirectPeeringType Edge -PeeringLocation sea
        Assert-NotNull $location
		Assert-True { $location.Count -ge 2 }
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}


function Test-GetLocationKindDirectSeattle99999WithLocation {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Direct -DirectPeeringType Edge -PeeringLocation sea -PeeringDbFacilityId  99999
        Assert-NotNull $location
		Assert-True { $location.Count -eq 1 }
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}


function Test-GetLocationKindDirectSeattle99999 {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Direct -DirectPeeringType Edge -PeeringDbFacilityId  99999
        Assert-NotNull $location
		Assert-True { $location.Count -eq 1 }
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}


function Test-GetLocationKindDirectAmsterdam {
    try {
        $asn = 65000
        $asnPeerName = makePeerAsn $asn
        $location = Get-AzPeeringLocation -Kind Direct -DirectPeeringType Cdn -PeeringLocation Amsterdam
        Assert-NotNull $location
		Assert-True { $location.Count -ge 1 }
    }
    finally {
        Remove-AzPeerAsn -Name $asnPeerName -Force
    }
}