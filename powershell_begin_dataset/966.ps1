
$rgName='MyResourceGroup'
$location='eastus'


$cred = Get-Credential -Message 'Enter a username and password for the virtual machine.'


New-AzResourceGroup -Name $rgName -Location $location


$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix 10.0.1.0/24
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix 10.0.2.0/24
$dmzsubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-Dmz' -AddressPrefix 10.0.0.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix 10.0.0.0/16 `
  -Location $location -Subnet $fesubnet, $besubnet, $dmzsubnet


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-ALL' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTPS-All' -Description 'Allow HTTPS' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 443


$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
-Name 'MyNsg-FrontEnd' -SecurityRules $rule1,$rule2


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsg


$publicip = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIP-Firewall' `
  -location $location -AllocationMethod Dynamic


$nicVMFW = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'MyNic-Firewall' `
  -PublicIpAddress $publicip -Subnet $vnet.Subnets[2] -EnableIPForwarding


$vmConfig = New-AzVMConfig -VMName 'MyVm-Firewall' -VMSize Standard_DS2 | `
    Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm-Firewall' -Credential $cred | `
    Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nicVMFW.Id
    
$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig


$route = New-AzRouteConfig -Name 'RouteToBackEnd' -AddressPrefix 10.0.2.0/24 `
  -NextHopType VirtualAppliance -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIpAddress


$route2 = New-AzRouteConfig -Name 'RouteToInternet' -AddressPrefix 0.0.0.0/0 `
  -NextHopType VirtualAppliance -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIpAddress


$routeTableFEtoBE = New-AzRouteTable -Name 'MyRouteTable-FrontEnd' -ResourceGroupName $rgName `
  -location $location -Route $route, $route2


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' -AddressPrefix 10.0.1.0/24 `
  -NetworkSecurityGroup $nsg -RouteTable $routeTableFEtoBE
  

$route = New-AzRouteConfig -Name 'RouteToFrontEnd' -AddressPrefix '10.0.1.0/24' -NextHopType VirtualAppliance `
  -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIPAddress


$route2 = New-AzRouteConfig -Name 'RouteToInternet' -AddressPrefix '0.0.0.0/0' -NextHopType VirtualAppliance `
  -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIPAddress


$routeTableBE = New-AzRouteTable -Name 'MyRouteTable-BackEnd' -ResourceGroupName $rgName `
  -location $location -Route $route, $route2


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix '10.0.2.0/24' -RouteTable $routeTableBE
