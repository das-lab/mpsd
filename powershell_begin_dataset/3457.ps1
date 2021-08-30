
















function Test-Pipeline
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement

    $endDate = [DateTime]::Parse("9/8/2014")
    $startDate = $endDate.AddHours(-1)
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "dsIn" -File .\Resources\dataset-dsIn.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds0_0" -File .\Resources\dataset-ds0_0.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds1_0" -File .\Resources\dataset-ds1_0.json -Force

        $pipelineName = "samplePipeline"   
        $expected = Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force
        $actual = Get-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname

        Verify-AdfSubResource $expected $actual $rgname $dfname $pipelineName
                
        
        Get-AzDataFactoryV2Pipeline -DataFactory $df -Name $pipelineName | Remove-AzDataFactoryV2Pipeline -Force

        
        Assert-ThrowsContains { Get-AzDataFactoryV2Pipeline -DataFactory $df -Name $pipelineName } "NotFound" 
                
        
        Remove-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -DataFactoryName $dfname -Name $pipelineName -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-PipelineWithResourceId
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement

    $endDate = [DateTime]::Parse("9/8/2014")
    $startDate = $endDate.AddHours(-1)
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "dsIn" -File .\Resources\dataset-dsIn.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds0_0" -File .\Resources\dataset-ds0_0.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds1_0" -File .\Resources\dataset-ds1_0.json -Force

        $pipelineName = "samplePipeline"   
        $actual = Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force
        
        $expected = Get-AzDataFactoryV2Pipeline -ResourceId $actual.Id

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.Name $actual.Name

        Remove-AzDataFactoryV2Pipeline -ResourceId $actual.Id -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}