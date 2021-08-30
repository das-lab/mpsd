













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
