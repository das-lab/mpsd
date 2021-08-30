














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-DataFactoryName
{
    return getAssetName
}


function Get-ProviderLocation($provider)
{
    
    "West Europe"
}


function CleanUp($rgname, $dfname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Force
        Remove-AzResourceGroup -Name $rgname -Force
    }
}


function Verify-AdfSubResource ($expected, $actual, $rgname, $dfname, $name)
{
    Assert-NotNull $actual.Id
    Assert-NotNull $actual.ETag
    Assert-NotNull $actual.Name
    Assert-NotNull $actual.ResourceGroupName
    Assert-NotNull $actual.DataFactoryName

    Assert-AreEqual $rgname $actual.ResourceGroupName
    Assert-AreEqual $dfname $actual.DataFactoryName
    Assert-AreEqual $name $actual.Name

    Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
    Assert-AreEqual $expected.DataFactoryName $actual.DataFactoryName
    Assert-AreEqual $expected.Id $actual.Id
    Assert-AreEqual $expected.ETag $actual.ETag
    Assert-AreEqual $expected.Name $actual.Name
}
