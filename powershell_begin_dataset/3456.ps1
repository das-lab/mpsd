














function Test-Dataset
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $linkedServicename = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File (Join-Path 'Resources' 'linkedService.json') -Name $linkedServicename -Force
   
        $datasetname = "foo2"
        $expected = Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -File (Join-Path 'Resources' 'dataset.json') -Force
        $actual = Get-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname

        Verify-AdfSubResource $expected $actual $rgname $dfname $datasetname

        Remove-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-DatasetWithResourceId
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $linkedServicename = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File (Join-Path 'Resources' 'linkedService.json') -Name $linkedServicename -Force
   
        $dsname = "foo2"
        $expected = Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $dsname -File (Join-Path 'Resources' 'dataset.json') -Force
        $actual = Get-AzDataFactoryV2Dataset -ResourceId $expected.Id

        Verify-AdfSubResource $expected $actual $rgname $dfname $dsname

        Remove-AzDataFactoryV2Dataset -ResourceId $expected.Id -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-DatasetWithDataFactoryParameter
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $linkedServicename = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File (Join-Path 'Resources' 'linkedService.json') -Name $linkedServicename -Force
   
        $datasetname = "foo2"
        $actual = Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -File (Join-Path 'Resources' 'dataset.json') -Force
        $expected = Get-AzDataFactoryV2Dataset -DataFactory $df -Name $datasetname

        Verify-AdfSubResource $expected $actual $rgname $dfname $datasetname

        Remove-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-DatasetPiping
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        $linkedServicename = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File (Join-Path 'Resources' 'linkedService.json') -Name $linkedServicename -Force
   
        $datasetname = "foo2"
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname -File (Join-Path 'Resources' 'dataset.json') -Force
        
        Get-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname | Remove-AzDataFactoryV2Dataset -Force

        
        Assert-ThrowsContains { Get-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name $datasetname } "NotFound"
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}
