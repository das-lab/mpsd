














function Get-TestResourceGroupName($action)
{
    return "pstestrg" + $action
}


function Get-TestActionRuleName($action)
{
    return "pstestar" + $action
}


function Get-ProviderLocation($provider)
{
    
    "eastus"
}


function CleanUp($rgname, $actionRuleName)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzActionRule -ResourceGroupName $rgname -Name $actionRuleName
        Remove-AzResourceGroup -Name $rgname -Force
    }
}