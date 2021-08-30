













function Test-GetPeeringServiceProviders {
    
    $name = "TestPeer1"
    $provider = Get-AzPeeringServiceProvider
    Assert-NotNull $provider
    Assert-AreEqual $name $provider[0].ServiceProviderName
}


function Test-GetPeeringServiceLocations {
    $locations = Get-AzPeeringServiceLocation -Country "United States"
    Assert-NotNull $locations
    $state = $locations | Where-Object { $_.Name -match "Washington" }
    Assert-NotNull "Washington" $state
    $locations = Get-AzPeeringServiceLocation -Country "United States"
    Assert-NotNull $locations
}


function Test-GetPeeringServiceByResourceGroup {
    
    $name = getAssetName "myPeeringService";
    $loc = "Florida"
    $provider = "AS56845-Global1191"
    $resourceGroup = "Building40"
    $peeringService = New-AzPeeringService -ResourceGroupName $resourceGroup -Name $name -PeeringLocation $loc -PeeringServiceProvider $provider
    Assert-NotNull $peeringService
    Assert-AreEqual $peeringService.Name $name
    Assert-AreEqual $loc $peeringService.PeeringServiceLocation
    Assert-AreEqual $provider $peeringService.PeeringServiceProvider
    $peeringService = Get-AzPeeringService -ResourceGroupName $resourceGroup -Name $name
    Assert-NotNull $peeringService
    Assert-AreEqual $peeringService.Name $name
    Assert-AreEqual $loc $peeringService.PeeringServiceLocation
    Assert-AreEqual $provider $peeringService.PeeringServiceProvider
}


function Test-GetPeeringServiceByResourceId {
    
    $name = getAssetName "myPeeringService";
    $loc = "Florida"
    $provider = "AS56845-Global1191"
    $resourceGroup = "Building40"
    $peeringService = New-AzPeeringService -ResourceGroupName $resourceGroup -Name $name -PeeringLocation $loc -PeeringServiceProvider $provider
    Assert-NotNull $peeringService
    Assert-AreEqual $peeringService.Name $name
    Assert-AreEqual $loc $peeringService.PeeringServiceLocation
    Assert-AreEqual $provider $peeringService.PeeringServiceProvider
    $peeringService = Get-AzPeeringService -ResourceId $peeringService.Id
    Assert-NotNull $peeringService
    Assert-AreEqual $peeringService.Name $name
    Assert-AreEqual $loc $peeringService.PeeringServiceLocation
    Assert-AreEqual $provider $peeringService.PeeringServiceProvider
}


function Test-ListPeeringService {
    $peeringService = Get-AzPeeringService
    Assert-NotNull $peeringService
}


function Test-NewPeeringService {
    
    $name = getAssetName "myPeeringService";
    $loc = "Florida"
    $provider = "AS56845-Global1191"
    $resourceGroup = "Building40"
    $peeringService = New-AzPeeringService -ResourceGroupName $resourceGroup -Name $name -PeeringLocation $loc -PeeringServiceProvider $provider
    Assert-NotNull $peeringService
    Assert-AreEqual $peeringService.Name $name
    Assert-AreEqual $loc $peeringService.PeeringServiceLocation
    Assert-AreEqual $provider $peeringService.PeeringServiceProvider
}


function Test-NewPeeringServicePrefix {
    
    $name = getAssetName "myPeeringService";
    $prefixName = getAssetName "myPrefix";
	$loc = "Florida"
    $provider = "AS56845-Global1191"
    $resourceGroup = "Building40"
    $prefix = newIpV4Address $true $true 0 4
	$peeringService = New-AzPeeringService -ResourceGroupName $resourceGroup -Name $name -PeeringLocation $loc -PeeringServiceProvider $provider
    $peeringService = Get-AzPeeringService -ResourceGroupName $resourceGroup -Name $name
    $prefixService = $peeringService | New-AzPeeringServicePrefix -Name $prefixName -Prefix $prefix
    Assert-NotNull $prefixService
    
    $getPrefixService = Get-AzPeeringServicePrefix -ResourceGroupName $resourceGroup -PeeringServiceName $name -Name $prefixName
    Assert-NotNull $getPrefixService

    
    $isRemoved = Remove-AzPeeringServicePrefix -ResourceId $getPrefixService.Id -Force -PassThru
    Assert-AreEqual $isRemoved $true
}
