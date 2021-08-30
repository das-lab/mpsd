














function Test-Table
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        New-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Force
   
        $datasetname = "foo2"
        $actual = New-AzDataFactoryDataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -File .\Resources\dataset.json -Force
        $expected = Get-AzDataFactoryDataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.DatasetName $actual.DatasetName

        Remove-AzDataFactoryDataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -Force
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-TableWithDataFactoryParameter
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        New-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Force
   
        $datasetname = "foo2"
        $actual = New-AzDataFactoryDataset -DataFactory $df -Name $datasetname -File .\Resources\dataset.json -Force
        $expected = Get-AzDataFactoryDataset -DataFactory $df -Name $datasetname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.DatasetName $actual.DatasetName

        Remove-AzDataFactoryDataset -DataFactory $df -Name $datasetname -Force
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-TablePiping
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        New-AzDataFactoryLinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Force
   
        $datasetname = "foo2"
        New-AzDataFactoryDataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -File .\Resources\dataset.json -Force
        
        Get-AzDataFactoryDataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname | Remove-AzDataFactoryDataset -Force

        
		
        Assert-ThrowsContains { Get-AzDataFactoryDataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname } "TableNotFound"
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}