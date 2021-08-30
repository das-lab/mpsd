
$rgName='MyResourceGroup'
$location='eastus'


$cred = Get-Credential -Message "Enter a username and password for the virtual machine."


New-AzResourceGroup -Name $rgName -Location $location


$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix '10.0.1.0/24'
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix '10.0.2.0/24'
$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix '10.0.0.0/16' `
  -Location $location -Subnet $fesubnet, $besubnet


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80


$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389



$nsgfe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name 'MyNsg-FrontEnd' -SecurityRules $rule1,$rule2


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsgfe


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SQL-FrontEnd' -Description "Allow SQL" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix '10.0.1.0/24' -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 1433


$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389


$nsgbe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name "MyNsg-BackEnd" -SecurityRules $rule1,$rule2


Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix '10.0.2.0/24' -NetworkSecurityGroup $nsgbe


$publicipvm1 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Web' `
  -location $location -AllocationMethod Dynamic


$nicVMweb = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic-Web' -PublicIpAddress $publicipvm1 -NetworkSecurityGroup $nsgfe -Subnet $vnet.Subnets[0]


$vmConfig = New-AzVMConfig -VMName 'MyVm-Web' -VMSize 'Standard_DS2' | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm-Web' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVMweb.Id

$vmweb = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig


$publicipvm2 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name MyPublicIP-Sql `
  -location $location -AllocationMethod Dynamic


$nicVMsql = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name MyNic-Sql -PublicIpAddress $publicipvm2 -NetworkSecurityGroup $nsgbe -Subnet $vnet.Subnets[1] 


$vmConfig = New-AzVMConfig -VMName 'MyVm-Sql' -VMSize 'Standard_DS2' | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm-Sql' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftSQLServer' -Offer 'SQL2016-WS2016' `
  -Skus 'Web' -Version latest | Add-AzVMNetworkInterface -Id $nicVMsql.Id

$vmsql = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig


$rule3 = New-AzNetworkSecurityRuleConfig -Name 'Deny-Internet-All' -Description "Deny Internet All" `
  -Access Deny -Protocol Tcp -Direction Outbound -Priority 300 `
  -SourceAddressPrefix * -SourcePortRange * `
  -DestinationAddressPrefix Internet -DestinationPortRange *


$nsgbe.SecurityRules.add($rule3)

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsgbe
