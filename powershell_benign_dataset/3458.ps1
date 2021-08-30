














function Test-LinkedService
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsname = "foo"
        $expected = Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname -File .\Resources\linkedService.json -Force
        $actual = Get-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname

        Verify-AdfSubResource $expected $actual $rgname $dfname $lsname

        Remove-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-LinkedServiceWithResourceId
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
        $expected = Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $linkedServicename -Force
        $actual = Get-AzDataFactoryV2LinkedService -ResourceId $expected.Id

        Verify-AdfSubResource $expected $actual $rgname $dfname $linkedServicename

        Remove-AzDataFactoryV2LinkedService -ResourceId $expected.Id -Force
    }
    finally
    {
        CleanUp $rgname $dfname
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
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsname = "foo"
        $expected = Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DatafactoryName $dfname -Name $lsname -File .\Resources\linkedService.json -Force
        $actual = Get-AzDataFactoryV2LinkedService -DataFactory $df -Name $lsname

        Verify-AdfSubResource $expected $actual $rgname $dfname $lsname

        Remove-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DatafactoryName $dfname -Name $lsname -Force
    }
    finally
    {
        CleanUp $rgname $dfname
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
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsname = "foo"
   
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname -File .\Resources\linkedService.json -Force
        
        Get-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname | Remove-AzDataFactoryV2LinkedService -Force
                
        
        Assert-ThrowsContains { Get-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -Name $lsname } "NotFound"
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}
