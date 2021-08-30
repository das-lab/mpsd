














function Test-SimpleNewVm
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $x = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel

        Assert-AreEqual $vmname $x.Name;
        Assert-Null $x.Identity
        Assert-False { $x.AdditionalCapabilities.UltraSSDEnabled };

        $nic = Get-AzNetworkInterface -ResourceGroupName $vmname  -Name $vmname
        Assert-NotNull $nic
        Assert-False { $nic.EnableAcceleratedNetworking }
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmFromSIGImage
{
    
    
    
    
    
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $x = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -Location "East US 2" -Size "Standard_D2s_v3" -Image "/subscriptions/9e223dbe-3399-4e19-88eb-0975f02ac87f/resourceGroups/SIGTestGroupoDoNotDelete/providers/Microsoft.Compute/galleries/SIGTestGalleryDoNotDelete/images/SIGTestImageWindowsDoNotDelete" 

        Assert-AreEqual $vmname $x.Name;
        Assert-Null $x.Identity
        Assert-False { $x.AdditionalCapabilities.UltraSSDEnabled };

        $nic = Get-AzNetworkInterface -ResourceGroupName $vmname  -Name $vmname
        Assert-NotNull $nic
        Assert-False { $nic.EnableAcceleratedNetworking }
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmWithUltraSSD
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        
        
        
        $x = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -Location "eastus2" -EnableUltraSSD -Zone 2 -Size "Standard_D2s_v3"

        Assert-AreEqual $vmname $x.Name;
        Assert-Null $x.Identity
        Assert-True { $x.AdditionalCapabilities.UltraSSDEnabled };

        $nic = Get-AzNetworkInterface -ResourceGroupName $vmname  -Name $vmname
        Assert-NotNull $nic
        Assert-False { $nic.EnableAcceleratedNetworking }
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmWithAccelNet
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $x = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -Size "Standard_D12_v2"

        Assert-AreEqual $vmname $x.Name;
        Assert-Null $x.Identity

        $nic = Get-AzNetworkInterface -ResourceGroupName $vmname  -Name $vmname
        Assert-NotNull $nic
        Assert-True { $nic.EnableAcceleratedNetworking }
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmSystemAssignedIdentity
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $x = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -SystemAssignedIdentity

        Assert-AreEqual $vmname $x.Name;
        Assert-AreEqual "SystemAssigned" $x.Identity.Type     
        Assert-NotNull  $x.Identity.PrincipalId
        Assert-NotNull  $x.Identity.TenantId
        Assert-Null $x.Identity.IdentityIds     
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-NewVmWin10
{
    $vmname = Get-ResourceName
    
    try {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
            [string]$domainNameLabel = "$vmname-$vmname".tolower();
        $x = New-AzVM `
                  -Name $vmname `
                  -Credential $cred `
                  -DomainNameLabel $domainNameLabel `
                  -ImageName "Win10" `
                  -DataDiskSizeInGb 32,64

            Assert-AreEqual 2 $x.StorageProfile.DataDisks.Count
        Assert-AreEqual $vmname $x.Name; 
        Assert-Null $x.Identity
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmUserAssignedIdentitySystemAssignedIdentity
{
    
    $vmname = "UAITG123456"

    try
    {
        
        
        
        
        
        
        
        
        
        
        
        $newUserId = "/subscriptions/24fb23e3-6ba3-41f0-9b6e-e41131d5d61e/resourcegroups/UAITG123456/providers/Microsoft.ManagedIdentity/userAssignedIdentities/UAITG123456Identity"

        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $x = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -UserAssignedIdentity $newUserId -SystemAssignedIdentity

        Assert-AreEqual $vmname $x.Name;
        Assert-AreEqual "UserAssigned" $x.Identity.Type     
        Assert-NotNull  $x.Identity.PrincipalId
        Assert-NotNull  $x.Identity.TenantId
        Assert-NotNull $x.Identity.UserAssignedIdentities
        Assert-AreEqual 1 $x.Identity.UserAssignedIdentities.Count
        Assert-True { $x.Identity.UserAssignedIdentities.ContainsKey($newUserId) }
        Assert-NotNull  $x.Identity.UserAssignedIdentities[$newUserId].PrincipalId
        Assert-NotNull  $x.Identity.UserAssignedIdentities[$newUserId].ClientId
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmWithAvailabilitySet
{
    
    $rgname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$vmname = $rgname
        [string]$asname = $rgname
        [string]$domainNameLabel = "$vmname-$rgname".tolower();

        
        $r = New-AzResourceGroup -Name $rgname -Location "eastus"
        $a = New-AzAvailabilitySet `
            -ResourceGroupName $rgname `
            -Name $asname `
            -Location "eastus" `
            -Sku "Aligned" `
            -PlatformUpdateDomainCount 2 `
            -PlatformFaultDomainCount 2

        $x = New-AzVM `
            -ResourceGroupName $rgname `
            -Name $vmname `
            -Credential $cred `
            -DomainNameLabel $domainNameLabel `
            -AvailabilitySetName $asname

        Assert-AreEqual $vmname $x.Name;        
        Assert-AreEqual $a.Id $x.AvailabilitySetReference.Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SimpleNewVmWithDefaultDomainName
{
    
    $rgname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string] $vmname = "ps9301"

        
        $x = New-AzVM -ResourceGroupName $rgname -Name $vmname -Credential $cred

        Assert-AreEqual $vmname $x.Name
        $fqdn = $x.FullyQualifiedDomainName
        $split = $fqdn.Split(".")
        Assert-AreEqual "eastus" $split[1] 
        Assert-AreEqual "cloudapp" $split[2]
        Assert-AreEqual "azure" $split[3]
        Assert-AreEqual "com" $split[4]
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmWithDefaultDomainName2
{
    
    $rgname = Get-ResourceName
    $rgname2 = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string] $vmname = "vm"

        
        $x = New-AzVM `
            -ResourceGroupName $rgname `
            -Name $vmname `
            -Credential $cred `
            -ImageName "ubuntults"

        
        $x2 = New-AzVM `
            -ResourceGroupName $rgname2 `
            -Name $vmname `
            -Credential $cred `
            -ImageName "ubuntults"
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $rgname2
    }
}


function Test-SimpleNewVmWithAvailabilitySet2
{
    
    $rgname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$vmname = "myVM"
        [string]$asname = "myAvailabilitySet"

        
        $r = New-AzResourceGroup -Name $rgname -Location "eastus"
        $a = New-AzAvailabilitySet `
            -ResourceGroupName $rgname `
            -Name $asname `
            -Location "eastus" `
            -Sku "Aligned" `
            -PlatformUpdateDomainCount 2 `
            -PlatformFaultDomainCount 2

        $x = New-AzVM `
            -ResourceGroupName $rgname `
            -Name $vmname `
            -Credential $cred `
            -VirtualNetworkName "myVnet" `
            -SubnetName "mySubnet" `
            -OpenPorts 80,3389 `
            -PublicIpAddressName "myPublicIpAddress" `
            -SecurityGroupName "myNetworkSecurityGroup" `
            -AvailabilitySetName $asname `
            -DomainNameLabel "myvm-ad9300"

        Assert-AreEqual $vmname $x.Name;        
        Assert-AreEqual $a.Id $x.AvailabilitySetReference.Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SimpleNewVmImageName
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower()

        
        $imgversion = Get-VMImageVersion -publisher "MicrosoftWindowsServer" -offer "WindowsServer" -sku "2016-Datacenter"
        $x = New-AzVM `
            -Name $vmname `
            -Credential $cred `
            -DomainNameLabel $domainNameLabel `
            -ImageName ("MicrosoftWindowsServer:WindowsServer:2016-Datacenter:" + $imgversion)

        Assert-AreEqual $vmname $x.Name
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmImageNameMicrosoftSqlUbuntu
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "xsd3490285".tolower()

        
        $x = New-AzVM `
            -Name $vmname `
            -Credential $cred `
            -DomainNameLabel $domainNameLabel `
            -ImageName "MicrosoftSQLServer:SQL2017-Ubuntu1604:Enterprise:latest"

        Assert-AreEqual $vmname $x.Name
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmPpg
{
    
    $rgname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        $ppgname = "MyPpg"
        $vmname = "MyVm"
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $rg = New-AzResourceGroup -Name $rgname -Location "eastus"
        $ppg = New-AzProximityPlacementGroup `
            -ResourceGroupName $rgname `
            -Name $ppgname `
            -Location "eastus"
        $vm = New-AzVM -Name $vmname -ResourceGroup $rgname -Credential $cred -DomainNameLabel $domainNameLabel -ProximityPlacementGroup $ppgname

        Assert-AreEqual $vm.ProximityPlacementGroup.Id $ppg.Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SimpleNewVmPpgId
{
    
    $rgname = Get-ResourceName
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        $ppgname = "MyPpg"
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $rg = New-AzResourceGroup -Name $rgname -Location "eastus"
        $ppg = New-AzProximityPlacementGroup `
            -ResourceGroupName $rgname `
            -Name $ppgname `
            -Location "eastus"
        $vm = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -ProximityPlacementGroup $ppg.Id

        Assert-AreEqual $vm.ProximityPlacementGroup.Id $ppg.Id
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
        Clean-ResourceGroup $vmname
    }
}


function Test-SimpleNewVmBilling
{
    
    $vmname = Get-ResourceName

    try
    {
        $username = "admin01"
        $password = Get-PasswordForVM | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        [string]$domainNameLabel = "$vmname-$vmname".tolower();

        
        $vm = New-AzVM -Name $vmname -Credential $cred -DomainNameLabel $domainNameLabel -EvictionPolicy 'Deallocate' -Priority 'Low' -MaxPrice 0.2;

        Assert-AreEqual $vmname $vm.Name;
        Assert-AreEqual 'Deallocate' $vm.EvictionPolicy;
        Assert-AreEqual 'Low' $vm.Priority;     
        Assert-AreEqual 0.2 $vm.BillingProfile.MaxPrice;
    }
    finally
    {
        
        Clean-ResourceGroup $vmname
    }
}
