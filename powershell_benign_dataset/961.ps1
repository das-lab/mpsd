
$rgName='MyResourceGroup'
$location='eastus'


$cred = Get-Credential -Message 'Enter a username and password for the virtual machine.'


New-AzResourceGroup -Name $rgName -Location $location


$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix '10.0.1.0/24'
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix '10.0.2.0/24'

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix '10.0.0.0/16' `
  -Location $location -Subnet $fesubnet, $besubnet


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-ALL' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTPS-All' -Description 'Allow HTTPS' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 443


$rule3 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description 'Allow RDP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389


$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name "MyNsg-FrontEnd" -SecurityRules $rule1,$rule2,$rule3


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix 10.0.1.0/24 -NetworkSecurityGroup $nsg


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Deny-Internet-All' -Description "Deny all Internet" `
  -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 `
  -SourceAddressPrefix * -SourcePortRange * `
  -DestinationAddressPrefix Internet -DestinationPortRange *


$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name "MyNsg-BackEnd" -SecurityRules $rule1


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-backEnd' `
  -AddressPrefix 10.0.2.0/24 -NetworkSecurityGroup $nsg


$publicipvm = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-FrontEnd' `
  -location $location -AllocationMethod Dynamic


$nicVMfe = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name MyNic-FrontEnd -PublicIpAddress $publicipvm -Subnet $vnet.Subnets[0]


$nicVMbe = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name MyNic-BackEnd -Subnet $vnet.Subnets[1]


$vmConfig = New-AzVMConfig -VMName 'myVM' -VMSize Standard_DS2 | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version 'latest'
    
$vmconfig = Add-AzVMNetworkInterface -VM $vmConfig -id $nicVMfe.Id -Primary
$vmconfig = Add-AzVMNetworkInterface -VM $vmConfig -id $nicVMbe.Id


$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig
