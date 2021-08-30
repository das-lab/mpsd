













function Run-ComputeCloudExceptionTests
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
        
        $loc = Get-ComputeVMLocation;
        New-AzureRmResourceGroup -Name $rgname -Location $loc -Force;

        $compare = "*Resource*not found*OperationID : *";
        Assert-ThrowsLike { $s1 = Get-AzureRmVM -ResourceGroupName $rgname -Name 'test' } $compare;
        Assert-ThrowsLike { $s2 = Get-AzureRmVM -ResourceGroupName 'foo' -Name 'bar' } $compare;
        Assert-ThrowsLike { $s3 = Get-AzureRmAvailabilitySet -ResourceGroupName $rgname -Name 'test' } $compare;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
