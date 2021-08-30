













function Test-NewPeerAsn()
{
	
	$asnId = 65000
	$asnPeerName = getAssetName "Global"
	$asnPeer = getAssetName 
	[string[]]$emails = "noc@$asnPeer.com","noc@$asnPeerName.com"
	$phone = getAssetName
	try{
	New-AzPeerAsn -Name $asnPeerName -PeerName $asnPeer -PeerAsn $asnId -Email $emails -Phone $phone
	$asn = Get-AzPeerAsn -Name $asnPeerName
	Assert-NotNull $asn
	Assert-AreEqual "None" $asn.ValidationState
	Assert-AreEqual $asnPeerName $asn.Name
	Assert-AreEqual $asnId $asn.PeerAsnProperty
	Assert-AreEqual $asnPeer $asn.PeerName
	Assert-True {$emails | % {$_ -like "noc@*.com"}}
	}
	finally{
		Remove-AzPeerAsn -Name $asnPeerName -Force
	}
}

function Test-GetPeerAsn
{
	
	$asnId = 65000
	$asnPeerName = getAssetName "Global"
	$asnPeer = getAssetName 
	[string[]]$emails = "noc@$asnPeer.com","noc@$asnPeerName.com"
	$phone = getAssetName
	try{
	$created = New-AzPeerAsn -Name $asnPeerName -PeerName $asnPeer -PeerAsn $asnId -Email $emails -Phone $phone
	$asn = Get-AzPeerAsn -Name $asnPeerName
	Assert-NotNull $asn
	Assert-NotNull $created
	Assert-AreEqual $created.ValidationState $asn.ValidationState
	Assert-AreEqual $created.Name $asn.Name
	Assert-AreEqual $created.PeerAsnProperty $asn.PeerAsnProperty
	Assert-AreEqual $created.PeerName $asn.PeerName
	Assert-True {$emails | % {$_ -like "noc@*.com"}}
	}
	finally{
		Remove-AzPeerAsn -Name $asnPeerName -Force
	}
}

function Test-ListPeerAsn
{
	
	makePeerAsn 65000
	makePeerAsn 65001
	makePeerAsn 65002
	try{
	$asn = Get-AzPeerAsn
	Assert-NotNull $asn
	Assert-True {$asn.Count -ge 3}
	}
	finally{
		Get-AzPeerAsn | Where-Object {$_.Name -match "Global"} | Remove-AzPeerAsn -Force
	}
	$cleaner = Get-AzPeerAsn | Where-Object {$_.Name -match "Global"}
	Assert-Null $cleaner
}


function Test-SetPeerAsn
{
	$createdPeerAsn = makePeerAsn 65000
	Assert-NotNull $createdPeerAsn
	$name = $createdPeerAsn.Name
	$getPeerAsn = Get-AzPeerAsn -Name $name
	
	$email = getAssetName
	$email = "$email@$name.com"
	$getPeerAsn | Set-AzPeerAsn -Email $email
	$peerasn = Get-AzPeerAsn
	Assert-True { $peerasn.PeerContactInfo.Emails | Where-Object { $_ -match "$email" } | % {$_ -like $email} }
	Remove-AzPeerAsn -Name $name -Force
}

function Test-RemovePeerAsn
{
	$createdPeerAsn = makePeerAsn 65000
	Assert-NotNull $createdPeerAsn
	$name = $createdPeerAsn.Name
	$getPeerAsn = Get-AzPeerAsn -Name $name
	Assert-NotNull $getPeerAsn
	$remove = Remove-AzPeerAsn $name -PassThru -Force
	Assert-NotNull $remove
	Assert-AreEqual $remove "$true"
	Assert-ThrowsContains {Get-AzPeerAsn -Name $name} "Error"
}
