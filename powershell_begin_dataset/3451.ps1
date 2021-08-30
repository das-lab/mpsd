














function Test-GetNonExistingDataFactory
{	
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force
    
    
    Assert-ThrowsContains { Get-AzDataFactory -ResourceGroupName $rgname -Name $dfname } "ResourceNotFound"    
}


function Test-CreateDataFactory
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $actual = New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $expected = Get-AzDataFactory -ResourceGroupName $rgname -Name $dfname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-DeleteDataFactoryWithDataFactoryParameter
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    $df = New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force        
    Remove-AzDataFactory -DataFactory $df -Force
}


function Test-DataFactoryPiping
{	
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

    Get-AzDataFactory -ResourceGroupName $rgname | Remove-AzDataFactory -Force

    
    Assert-ThrowsContains { Get-AzDataFactory -ResourceGroupName $rgname -Name $dfname } "ResourceNotFound"
}