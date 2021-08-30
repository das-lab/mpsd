
$rgName='MyResourceGroup'
$location='eastus'


New-AzResourceGroup -Name $rgName -Location $location


$vnet1 = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'Vnet1' -AddressPrefix '10.0.0.0/16' -Location $location


$vnet2 = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'Vnet2' -AddressPrefix '10.1.0.0/16' -Location $location


Add-AzVirtualNetworkPeering -Name 'LinkVnet1ToVnet2' -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet2.Id


Add-AzVirtualNetworkPeering -Name 'LinkVnet2ToVnet1' -VirtualNetwork $vnet2 -RemoteVirtualNetworkId $vnet1.Id
