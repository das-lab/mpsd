

$RG="AzfwSampleScriptEastUS"
$Location="East US"


$securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("AzfwUser", $securePassword)



New-AzResourceGroup -Name $RG -Location $Location


$VnetName=$RG+"Vnet"
New-AzVirtualNetwork -ResourceGroupName $RG -Name $VnetName -AddressPrefix 192.168.0.0/16 -Location $Location


$vnet = Get-AzVirtualNetwork -ResourceGroupName $RG -Name $VnetName
Add-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.1.0/24
Add-AzVirtualNetworkSubnetConfig -Name JumpBoxSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24
Add-AzVirtualNetworkSubnetConfig -Name ServersSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.2.0/24
Set-AzVirtualNetwork -VirtualNetwork $vnet


$LBPipName = $RG + "PublicIP"
$LBPip = New-AzPublicIpAddress -Name $LBPipName  -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Standard
$JumpBoxpip = New-AzPublicIpAddress -Name "JumpHostPublicIP"  -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Basic


$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow


$NsgName = $RG+"NSG"
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RG -Location $Location -Name $NsgName -SecurityRules $nsgRuleRDP


$vnet = Get-AzVirtualNetwork -ResourceGroupName $RG -Name $VnetName
$JumpBoxSubnetId = $vnet.Subnets[1].Id

$JumpBoxNic = New-AzNetworkInterface -Name JumpBoxNic -ResourceGroupName $RG -Location $Location -SubnetId $JumpBoxSubnetId -PublicIpAddressId $JumpBoxpip.Id -NetworkSecurityGroupId $nsg.Id
$JumpBoxConfig = New-AzVMConfig -VMName JumpBox -VMSize Standard_DS1_v2 | Set-AzVMOperatingSystem -Windows -ComputerName JumpBox -Credential $cred | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version latest | Add-AzVMNetworkInterface -Id $JumpBoxNic.Id
New-AzVM -ResourceGroupName $RG -Location $Location -VM $JumpBoxConfig


$ServersSubnetId = $vnet.Subnets[2].Id
$ServerVmNic = New-AzNetworkInterface -Name ServerVmNic -ResourceGroupName $RG -Location $Location -SubnetId $ServersSubnetId
$ServerVmConfig = New-AzVMConfig -VMName ServerVm -VMSize Standard_DS1_v2 | Set-AzVMOperatingSystem -Windows -ComputerName ServerVm -Credential $cred | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version latest | Add-AzVMNetworkInterface -Id $ServerVmNic.Id
New-AzVM -ResourceGroupName $RG -Location $Location -VM $ServerVmConfig


$GatewayName = $RG + "Azfw"
$Azfw = New-AzFirewall -Name $GatewayName -ResourceGroupName $RG -Location $Location -VirtualNetworkName $vnet.Name -PublicIpName $LBPip.Name


$Azfw = Get-AzFirewall -ResourceGroupName $RG
$Rule = New-AzFirewallApplicationRule -Name R1 -Protocol "http:80","https:443" -TargetFqdn "*microsoft.com"
$RuleCollection = New-AzFirewallApplicationRuleCollection -Name RC1 -Priority 100 -Rule $Rule -ActionType "Allow"
$Azfw.ApplicationRuleCollections = $RuleCollection
Set-AzFirewall -AzureFirewall $Azfw


$Azfw = Get-AzFirewall -ResourceGroupName $RG
$AzfwRouteName = $RG + "AzfwRoute"
$AzfwRouteTableName = $RG + "AzfwRouteTable"
$IlbCA = $Azfw.IpConfigurations[0].PrivateIPAddress
$AzfwRoute = New-AzRouteConfig -Name $AzfwRouteName -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $IlbCA
$AzfwRouteTable = New-AzRouteTable -Name $AzfwRouteTableName -ResourceGroupName $RG -location $Location -Route $AzfwRoute


$vnet.Subnets[2].RouteTable = $AzfwRouteTable
Set-AzVirtualNetwork -VirtualNetwork $vnet
