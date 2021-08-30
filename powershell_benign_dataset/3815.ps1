














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
