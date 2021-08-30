














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
    
    "Brazil South"
}


function Clean-DataFactory($rgname, $dfname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzDataFactory -ResourceGroupName $rgname -Name $dfname -Force
    }
}


function Clean-Tags
{
    Get-AzTag | Remove-AzTag -Force
}
