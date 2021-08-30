














function Test-LinkedService
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsname = "foo"
   
        $actual = New-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname -File .\Resources\linkedService.json -Force
        $expected = Get-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.LinkedServiceName $actual.LinkedServiceName

        Remove-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname -Force
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-LinkedServiceWithDataFactoryParameter
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsname = "foo"
   
        $actual = New-AzDataFactoryLinkedService -DataFactory $df -Name $lsname -File .\Resources\linkedService.json -Force
        $expected = Get-AzDataFactoryLinkedService -DataFactory $df -Name $lsname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.LinkedServiceName $actual.LinkedServiceName

        Remove-AzDataFactoryLinkedService -DataFactory $df -Name $lsname -Force
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-LinkedServicePiping
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsname = "foo"
   
        New-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname -File .\Resources\linkedService.json -Force
        
        Get-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname | Remove-AzDataFactoryLinkedService -Force
                
        
        Assert-ThrowsContains { Get-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname } "LinkedServiceNotFound"
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}