














function Test-PublicIpAddressCRUD
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $job = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel -AsJob
      $job | Wait-Job
	  $actual = $job | Receive-Job
	  $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName	
      Assert-AreEqual $expected.Name $actual.Name	
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState
      Assert-AreEqual $domainNameLabel $expected.DnsSettings.DomainNameLabel
      
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName  
      Assert-AreEqual $list[0].Name $actual.Name    
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqual "Dynamic" $list[0].PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState
      Assert-AreEqual $domainNameLabel $list[0].DnsSettings.DomainNameLabel

      $list = Get-AzPublicIpAddress -ResourceGroupName "*"
      Assert-True { $list.Count -ge 0 }

      $list = Get-AzPublicIpAddress -Name "*"
      Assert-True { $list.Count -ge 0 }

      $list = Get-AzPublicIpAddress -ResourceGroupName "*" -Name "*"
      Assert-True { $list.Count -ge 0 }
      
      
      $job = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force -AsJob
	  $job | Wait-Job
	  $delete = $job | Receive-Job
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-NoDomainNameLabel
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $expected.Name $actual.Name   
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $expected.ProvisioningState

      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName  
      Assert-AreEqual $list[0].Name $actual.Name    
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqual "Dynamic" $list[0].PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState

      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-StaticAllocation
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Static
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $expected.Name $actual.Name   
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Static" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.IpAddress
      Assert-AreEqual "Succeeded" $expected.ProvisioningState

      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName  
      Assert-AreEqual $list[0].Name $actual.Name    
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqual "Static" $list[0].PublicIpAllocationMethod
      Assert-NotNull $list[0].IpAddress
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState

      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-EditDomainNameLavel
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $newDomainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
      $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $publicip.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $publicip.Name $actual.Name   
      Assert-AreEqual $publicip.Location $actual.Location
      Assert-AreEqual "Dynamic" $publicip.PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $publicip.ProvisioningState
      Assert-AreEqual $domainNameLabel $publicip.DnsSettings.DomainNameLabel
      
      $publicip.DnsSettings.DomainNameLabel = $newDomainNameLabel

      
      $job = $publicip | Set-AzPublicIpAddress -AsJob
      $job | Wait-Job

      $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $newDomainNameLabel $publicip.DnsSettings.DomainNameLabel
      
      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-ReverseFqdn
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
      $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $publicip.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $publicip.Name $actual.Name   
      Assert-AreEqual $publicip.Location $actual.Location
      Assert-AreEqual "Dynamic" $publicip.PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $publicip.ProvisioningState
      Assert-AreEqual $domainNameLabel $publicip.DnsSettings.DomainNameLabel
      
      $publicip.DnsSettings.ReverseFqdn = $publicip.DnsSettings.Fqdn

      
      $publicip | Set-AzPublicIpAddress

      $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $publicip.DnsSettings.Fqdn $publicip.DnsSettings.ReverseFqdn
      
      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-IpTag
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent

    try
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      $IpTag = New-AzPublicIpTag -IpTagType "FirstPartyUsage" -Tag "/Sql"

      Assert-AreEqual $IpTag.IpTagType "FirstPartyUsage"
      Assert-AreEqual $IpTag.Tag "/Sql"

	  
	  $IpTag2 = New-AzPublicIpTag -IpTagType "RoutingPreference" -Tag "/Internet"

      Assert-AreEqual $IpTag2.IpTagType "RoutingPreference"
      Assert-AreEqual $IpTag2.Tag "/Internet"

      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel -IpTag $IpTag
      $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $publicip.ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $publicip.Name $actual.Name
      Assert-AreEqual $publicip.Location $actual.Location
      Assert-AreEqual "Dynamic" $publicip.PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $publicip.ProvisioningState
      Assert-AreEqual $domainNameLabel $publicip.DnsSettings.DomainNameLabel

      
      $publicip | Set-AzPublicIpAddress

      $publicip = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual "FirstPartyUsage" $publicip.IpTags.IpTagType
      Assert-AreEqual "/Sql" $publicip.IpTags.Tag

      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete

      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressIpVersion
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rname1 = Get-ResourceName
    $rname2 = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $expected.Name $actual.Name   
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState
      Assert-AreEqual $domainNameLabel $expected.DnsSettings.DomainNameLabel
      Assert-AreEqual $expected.PublicIpAddressVersion IPv4
      
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName  
      Assert-AreEqual $list[0].Name $actual.Name    
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqual "Dynamic" $list[0].PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState
      Assert-AreEqual $domainNameLabel $list[0].DnsSettings.DomainNameLabel
      Assert-AreEqual $list[0].PublicIpAddressVersion IPv4

      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname1 -location $location -AllocationMethod Dynamic -IpAddressVersion IPv4
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname1
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $expected.Name $actual.Name   
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState      
      Assert-AreEqual $expected.PublicIpAddressVersion IPv4
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname2 -location $location -AllocationMethod Dynamic -IpAddressVersion IPv6
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname2
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $expected.Name $actual.Name   
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState      
      Assert-AreEqual $expected.PublicIpAddressVersion IPv6

      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete

      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname1 -PassThru -Force
      Assert-AreEqual true $delete

      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname2 -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

function Get-NameById($Id, $ResourceType)
{
    $name = $Id.Substring($Id.IndexOf($ResourceType + '/') + $ResourceType.Length + 1);
    if ($name.IndexOf('/') -ne -1)
    {
        $name = $name.Substring(0, $name.IndexOf('/'));
    }
    return $name;
}


function Test-PublicIpAddressVmss
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Compute/virtualMachineScaleSets"
    $location = Get-ProviderLocation $resourceTypeParent

    try
    {
        . ".\AzureRM.Resources.ps1"

        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        $vmssName = "vmssip"
        $templateFile = (Resolve-Path ".\ScenarioTests\Data\VmssDeploymentTemplate.json").Path
        New-AzResourceGroupDeployment -Name $rgname -ResourceGroupName $rgname -TemplateFile $templateFile;

        $listAllResults = Get-AzPublicIpAddress -ResourceGroupName $rgname -VirtualMachineScaleSetName $vmssName;
        Assert-NotNull $listAllResults;

        $listFirstResultId = $listAllResults[0].Id;
        $vmIndex = Get-NameById $listFirstResultId "virtualMachines";
        $nicName = Get-NameById $listFirstResultId "networkInterfaces";
        $ipConfigName = Get-NameById $listFirstResultId "ipConfigurations";
        $ipName = Get-NameById $listFirstResultId "publicIPAddresses";

        $listResults = Get-AzPublicIpAddress -ResourceGroupName $rgname -VirtualMachineScaleSetName $vmssName -VirtualmachineIndex $vmIndex -NetworkInterfaceName $nicName -IpConfigurationName $ipConfigName;
        Assert-NotNull $listResults;
        Assert-AreEqualObjectProperties $listAllResults[0] $listResults[0] "List and list all results should contain equal items";

        $vmssIp = Get-AzPublicIpAddress -ResourceGroupName $rgname -VirtualMachineScaleSetName $vmssName -VirtualmachineIndex $vmIndex -NetworkInterfaceName $nicName -IpConfigurationName $ipConfigName -Name $ipName;
        Assert-NotNull $vmssIp;
        Assert-AreEqualObjectProperties $vmssIp $listResults[0] "List and get results should contain equal items";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-BasicSku
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel -Sku Basic
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
      Assert-AreEqual $expected.Name $actual.Name   
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqualObjectProperties $expected.Sku $actual.Sku
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState
      Assert-AreEqual $domainNameLabel $expected.DnsSettings.DomainNameLabel
      
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName  
      Assert-AreEqual $list[0].Name $actual.Name    
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqualObjectProperties $list[0].Sku $actual.Sku
      Assert-AreEqual "Dynamic" $list[0].PublicIpAllocationMethod
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState
      Assert-AreEqual $domainNameLabel $list[0].DnsSettings.DomainNameLabel
      
      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-StandardSku
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Static -Sku Standard -DomainNameLabel $domainNameLabel
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $expected.Name $actual.Name
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqualObjectProperties $expected.Sku $actual.Sku
      Assert-AreEqual "Static" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.IpAddress
      Assert-AreEqual "Succeeded" $expected.ProvisioningState

      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $list[0].Name $actual.Name
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqualObjectProperties $list[0].Sku $actual.Sku
      Assert-AreEqual "Static" $list[0].PublicIpAllocationMethod
      Assert-NotNull $list[0].IpAddress
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState

      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressZones
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $zones = "1";
    $rglocation = Get-ProviderLocation ResourceManagement
    $location = Get-ProviderLocation "Microsoft.Network/publicIpAddresses" "Central US"

    try
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }

      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Dynamic -Zone $zones;
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $expected.Name $actual.Name
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState
      Assert-AreEqual $zones $expected.Zones[0]
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-PublicIPPrefix
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/publicIpAddresses"
    $location = Get-ProviderLocation $resourceTypeParent
   
    try 
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
      
      
      $prefixname = $rname + "prfx"
      $PublicIpPrefix = New-AzPublicIpPrefix -ResourceGroupName $rgname -name $prefixname -location $location -Sku Standard -prefixLength 30
      $expectedPublicIpPrefix = Get-AzPublicIpPrefix -ResourceGroupName $rgname -name $prefixname
      Assert-AreEqual $expectedPublicIpPrefix.ResourceGroupName $PublicIpPrefix.ResourceGroupName
      Assert-AreEqual $expectedPublicIpPrefix.Name $PublicIpPrefix.Name
      Assert-AreEqual $expectedPublicIpPrefix.Location $PublicIpPrefix.Location
      Assert-AreEqualObjectProperties $expectedPublicIpPrefix.Sku $PublicIpPrefix.Sku
      Assert-NotNull $expectedPublicIpPrefix.IPPrefix

      
      $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -AllocationMethod Static -Sku Standard -DomainNameLabel $domainNameLabel -PublicIPPrefix $expectedPublicIpPrefix
      $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $expected.Name $actual.Name
      Assert-AreEqual $expected.Location $actual.Location
      Assert-AreEqualObjectProperties $expected.Sku $actual.Sku
      Assert-AreEqual "Static" $expected.PublicIpAllocationMethod
      Assert-NotNull $expected.IpAddress
      Assert-AreEqual "Succeeded" $expected.ProvisioningState

      
      $list = Get-AzPublicIpAddress -ResourceGroupName $rgname
      Assert-AreEqual 1 @($list).Count
      Assert-AreEqual $list[0].ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $list[0].Name $actual.Name
      Assert-AreEqual $list[0].Location $actual.Location
      Assert-AreEqualObjectProperties $list[0].Sku $actual.Sku
      Assert-AreEqual "Static" $list[0].PublicIpAllocationMethod
      Assert-NotNull $list[0].IpAddress
      Assert-AreEqual "Succeeded" $list[0].ProvisioningState

      
      $delete = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force
      Assert-AreEqual true $delete
      
      $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-PublicIpAddressCRUD-IdleTimeout
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $location = Get-ProviderLocation "Microsoft.Network/publicIpAddresses"

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation 

        
        $actual = New-AzPublicIpAddress -ResourceGroupName $rgname -name $rname -location $location -IdleTimeoutInMinutes 15 -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel
        $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName 
        Assert-AreEqual $expected.Name $actual.Name 
        Assert-AreEqual $expected.Location $actual.Location
        Assert-NotNull $expected.ResourceGuid
        Assert-AreEqual "Dynamic" $expected.PublicIpAllocationMethod
        Assert-AreEqual "Succeeded" $expected.ProvisioningState
        Assert-AreEqual $domainNameLabel $expected.DnsSettings.DomainNameLabel
        Assert-AreEqual 15 $expected.IdleTimeoutInMinutes

        
        $actual.IdleTimeoutInMinutes = 30
        $actual = Set-AzPublicIpAddress -PublicIpAddress $actual
        $expected = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $rname
        Assert-AreEqual 30 $expected.IdleTimeoutInMinutes

        
        $job = Remove-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName -name $rname -PassThru -Force -AsJob
        $job | Wait-Job
        $delete = $job | Receive-Job
        Assert-AreEqual true $delete

        $list = Get-AzPublicIpAddress -ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual 0 @($list).Count

        $list = Get-AzPublicIpAddress | Where-Object { $_.ResourceGroupName -eq $actual.ResourceGroupName -and $_.Name -eq $actual.Name }
        Assert-AreEqual 0 @($list).Count

        
        Assert-ThrowsContains { Set-AzPublicIpAddress -PublicIpAddress $actual } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
