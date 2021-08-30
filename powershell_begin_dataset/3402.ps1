














function Test-AvailabilitySet
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        $asetName = 'avs' + $rgname;
        $nonDefaultUD = 2;
        $nonDefaultFD = 3;

        New-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Location $loc -PlatformUpdateDomainCount $nonDefaultUD -PlatformFaultDomainCount $nonDefaultFD -Sku 'Classic';

        $asets = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname;
        Assert-NotNull $asets;
        Assert-AreEqual $asetName $asets[0].Name;

        $aset = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName;
        Assert-NotNull $aset;
        Assert-AreEqual $aset.Name $asetName;
        Assert-AreEqual $nonDefaultUD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $nonDefaultFD $aset.PlatformFaultDomainCount;
        Assert-False {$aset.Managed};
        Assert-AreEqual 'Classic' $aset.Sku;

        $aset | Update-AzureRmAvailabilitySet -Managed;
        $aset = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName;

        Assert-NotNull $aset;
        Assert-AreEqual $aset.Name $asetName;
        Assert-AreEqual $nonDefaultUD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $nonDefaultFD $aset.PlatformFaultDomainCount;
        Assert-AreEqual 'Aligned' $aset.Sku;

        $aset | Update-AzureRmAvailabilitySet -Sku 'Aligned';
        $aset = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName;

        Assert-NotNull $aset;
        Assert-AreEqual $aset.Name $asetName;
        Assert-AreEqual $nonDefaultUD $aset.PlatformUpdateDomainCount;
        Assert-AreEqual $nonDefaultFD $aset.PlatformFaultDomainCount;
        Assert-AreEqual 'Aligned' $aset.Sku;

        Remove-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name $asetName -Force;
        
        $asets = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname;
        Assert-AreEqual $asets $null;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
