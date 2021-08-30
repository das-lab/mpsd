














function Test-Run
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement

    $endDate = [DateTime]::Parse("04/08/2017")
    $startDate = $endDate.AddDays(-10)
        
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
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force

        $Run = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -PipelineName $pipelineName -DataFactoryName $dfname -Parameter @{"OutputBlobName"="test";}
        Assert-True { Stop-AzDataFactoryV2PipelineRun -ResourceGroupName $rgname -PipelineRunId $Run -DataFactoryName $dfname -PassThru}

        
        Get-AzDataFactoryV2ActivityRun -ResourceGroupName $rgname -DataFactoryName $dfname -PipelineRunId $Run -RunStartedBefore $endDate -RunStartedAfter $startDate
        Get-AzDataFactoryV2ActivityRun -DataFactory $df -PipelineRunId $Run -RunStartedBefore $endDate -RunStartedAfter $startDate

        
        Get-AzDataFactoryV2PipelineRun -ResourceGroupName $rgname -DataFactoryName $dfname -PipelineRunId $Run
        Get-AzDataFactoryV2PipelineRun -DataFactory $df -PipelineRunId $Run
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-CancelRunNegative
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement

    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
        
        $Run = "someGuid"
        Assert-ThrowsContains { Stop-AzDataFactoryV2PipelineRun -ResourceGroupName $rgname -DataFactoryName $dfname -PipelineRunId $Run } "ReferencedPipelineRunNotFound" 
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}
