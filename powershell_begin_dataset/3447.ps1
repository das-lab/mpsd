














function Test-Hub
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $hubname = "SampleHub"
   
        $actual = New-AzDataFactoryHub -ResourceGroupName $rgname -DataFactoryName $dfname -Name $hubname -File .\Resources\hub.json -Force
        $expected = Get-AzDataFactoryHub -ResourceGroupName $rgname -DataFactoryName $dfname -Name $hubname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.HubName $actual.HubName

        Remove-AzDataFactoryHub -ResourceGroupName $rgname -DataFactoryName $dfname -Name $hubname -Force
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-HubWithDataFactoryParameter
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $hubname = "SampleHub"
   
        $actual = New-AzDataFactoryHub -DataFactory $df -Name $hubname -File .\Resources\hub.json -Force
        $expected = Get-AzDataFactoryHub -DataFactory $df -Name $hubname

        Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
        Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
        Assert-AreEqual $expected.HubName $actual.HubName

        Remove-AzDataFactoryHub -DataFactory $df -Name $hubname -Force
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}


function Test-HubPiping
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        New-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $hubname = "SampleHub"
   
        New-AzDataFactoryHub -ResourceGroupName $rgname -DataFactoryName $dfname -Name $hubname -File .\Resources\hub.json -Force
        
        Get-AzDataFactoryHub -ResourceGroupName $rgname -DataFactoryName $dfname -Name $hubname | Remove-AzDataFactoryHub -Force

        
        Assert-ThrowsContains { Get-AzDataFactoryHub -ResourceGroupName $rgname -DataFactoryName $dfname -Name $hubname } "HubNotFound"
    }
    finally
    {
        Clean-DataFactory $rgname $dfname
    }
}