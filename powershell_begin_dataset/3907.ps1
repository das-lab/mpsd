














function Test-ComputeNodeUserEndToEnd
{
    param([string]$poolId, [string]$computeNodeId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $userName = "userendtoend"
    $password1 = ConvertTo-SecureString "Password1234!" -AsPlainText -Force

    
    New-AzBatchComputeNodeUser -PoolId $poolId -ComputeNodeId $computeNodeId -Name $userName -Password $password1 -BatchContext $context

    
    
    
    $password2 = ConvertTo-SecureString "Abcdefghijk1234!" -AsPlainText -Force
    Set-AzBatchComputeNodeUser $poolId $computeNodeId $userName $password2 -ExpiryTime ([DateTime]::Now.AddDays(5)) -BatchContext $context

    
    Remove-AzBatchComputeNodeUser -PoolId $poolId -ComputeNodeId $computeNodeId -Name $userName -BatchContext $context

    
    
    Assert-Throws { Remove-AzBatchComputeNodeUser -PoolId $poolId -ComputeNodeId $computeNodeId -Name $userName -BatchContext $context }
}