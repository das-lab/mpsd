
$rgName='MyResourceGroup'
$location='eastus'


$cred = Get-Credential -Message "Enter a username and password for the virtual machine."


New-AzResourceGroup -Name $rgName -Location $location


$as = New-AzAvailabilitySet -ResourceGroupName $rgName -Location $location `
  -Name MyAvailabilitySet -Sku Aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2


$subnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet' -AddressPrefix 10.0.0.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name MyVnet `
  -AddressPrefix 10.0.0.0/16 -Location $location -Subnet $subnet


$publicIpLB = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-LoadBalancer' `
  -Location $location -AllocationMethod Dynamic

$publicIpContoso = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Contoso' `
  -Location $location -AllocationMethod Dynamic

$publicIpFabrikam = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Fabrikam' `
  -Location $location -AllocationMethod Dynamic


$feipcontoso = New-AzLoadBalancerFrontendIpConfig -Name 'FeContoso' -PublicIpAddress $publicIpContoso
$feipfabrikam = New-AzLoadBalancerFrontendIpConfig -Name 'FeFabrikam' -PublicIpAddress $publicIpFabrikam


$bepoolContoso = New-AzLoadBalancerBackendAddressPoolConfig -Name 'BeContoso'
$bepoolFabrikam = New-AzLoadBalancerBackendAddressPoolConfig -Name 'BeFabrikam'


$probe = New-AzLoadBalancerProbeConfig -Name 'MyProbe' -Protocol Http -Port 80 `
  -RequestPath / -IntervalInSeconds 360 -ProbeCount 5


$contosorule = New-AzLoadBalancerRuleConfig -Name 'LBRuleContoso' -Protocol Tcp `
  -Probe $probe -FrontendPort 5000 -BackendPort 5000 `
  -FrontendIpConfiguration $feipContoso -BackendAddressPool $bePoolContoso

$fabrikamrule = New-AzLoadBalancerRuleConfig -Name 'LBRuleFabrikam' -Protocol Tcp `
  -Probe $probe -FrontendPort 5000 -BackendPort 5000 `
  -FrontendIpConfiguration $feipFabrikam -BackendAddressPool $bePoolfabrikam


$lb = New-AzLoadBalancer -ResourceGroupName $rgName -Name 'MyLoadBalancer' -Location $location `
  -FrontendIpConfiguration $feipcontoso,$feipfabrikam -BackendAddressPool $bepoolContoso,$bepoolfabrikam `
  -Probe $probe -LoadBalancingRule $contosorule,$fabrikamrule




$publicipvm1 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name MyPublicIp-Vm1 `
  -location $location -AllocationMethod Dynamic


$ipconfig1 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig1' `
  -Subnet $vnet.subnets[0] -Primary  

$ipconfig2 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig2' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolContoso
 
$ipconfig3 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig3' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolfabrikam 


$nicVM1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
-Name 'MyNic-VM1' -IpConfiguration $ipconfig1, $ipconfig2, $ipconfig3


$vmConfig = New-AzVMConfig -VMName 'myVM1' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM1' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVM1.Id


$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig





$publicipvm1 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Vm2' `
  -location $location -AllocationMethod Dynamic


$ipconfig1 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig1' `
  -Subnet $vnet.subnets[0] -Primary  

$ipconfig2 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig2' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolContoso 

$ipconfig3 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig3' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolfabrikam 


$nicVM2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
-Name 'MyNic-VM2' -IpConfiguration $ipconfig1, $ipconfig2, $ipconfig3


$vmConfig = New-AzVMConfig -VMName 'myVM2' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM2' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVM2.Id


$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

