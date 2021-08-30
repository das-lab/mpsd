
















function Test-DataFlowDebugScenario
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

		
        $session = Start-AzDataFactoryV2DataFlowDebugSession -DataFactory $df

		
		$list = Get-AzDataFactoryV2DataFlowDebugSession -DataFactory $df
		Assert-AreEqual 1 $list.Count

		
		Add-AzDataFactoryV2DataFlowDebugSessionPackage -DataFactory $df -PackageFile .\Resources\dataFlowDebugPackage.json -SessionId $session.SessionId

		
        $result = Invoke-AzDataFactoryV2DataFlowDebugSessionCommand -DataFactory $df -Command executePreviewQuery -SessionId $session.SessionId -StreamName source1 -RowLimit 100
		Assert-AreEqual 'Succeeded' $result.Status
		Assert-NotNull $result.Data

        
		Stop-AzDataFactoryV2DataFlowDebugSession -DataFactory $df -SessionId $session.SessionId -Force
	    $newList = Get-AzDataFactoryV2DataFlowDebugSession -DataFactory $df
		Assert-AreEqual 0 $newList.Count
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}