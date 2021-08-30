













function Run-ComputeCloudExceptionTests
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        $compare = "*Resource*not found*OperationID : *";
        Assert-ThrowsLike { $s1 = Get-AzVM -ResourceGroupName $rgname -Name 'test' } $compare;
        Assert-ThrowsLike { $s2 = Get-AzVM -ResourceGroupName 'foo' -Name 'bar' } $compare;
        Assert-ThrowsLike { $s3 = Get-AzAvailabilitySet -ResourceGroupName $rgname -Name 'test' } $compare;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
