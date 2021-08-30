














function Test-RemoveComputeNodes
{
    param([string]$poolId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $deallocationOption = ([Microsoft.Azure.Batch.Common.ComputeNodeRebootOption]::Terminate)
    $resizeTimeout = ([TimeSpan]::FromMinutes(8))

    
    $computeNodes = Get-AzBatchComputeNode -PoolId $poolId -BatchContext $context
    $computeNodeId = $computeNodes[0].Id
    $computeNodeId2 = $computeNodes[1].Id
    Remove-AzBatchComputeNode -PoolId $poolId @($computeNodeId, $computeNodeId2) -Force -BatchContext $context

    
    $select = "id,state"
    $computeNodes = Get-AzBatchComputeNode -PoolId $poolId -Select $select -BatchContext $context
    $start = [DateTime]::Now
    $timeout = Compute-TestTimeout 30
    $end = $start.AddSeconds($timeout)
    while ($computeNodes[0].State -ne 'LeavingPool' -and $computeNodes[1].State -ne 'LeavingPool')
    {
        if ([DateTime]::Now -gt $end)
        {
            throw [System.TimeoutException] "Timed out waiting for compute nodes to enter LeavingPool state"
        }
        Start-TestSleep 1000
        $computeNodes = Get-AzBatchComputeNode -PoolId $poolId -Select $select -BatchContext $context
    }
}


function Test-RebootAndReimageComputeNode
{
    param([string]$poolId, [string]$computeNodeId, [string]$computeNodeId2)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $rebootOption = ([Microsoft.Azure.Batch.Common.ComputeNodeRebootOption]::Terminate)
    $reimageOption = ([Microsoft.Azure.Batch.Common.ComputeNodeReimageOption]::Terminate)

    
    Get-AzBatchComputeNode $poolId $computeNodeId -BatchContext $context | Restart-AzBatchComputeNode -RebootOption $rebootOption -BatchContext $context
    $computeNode = Get-AzBatchComputeNode -PoolId $poolId $computeNodeId -BatchContext $context
    Assert-AreEqual 'Rebooting' $computeNode.State

    
    Get-AzBatchComputeNode $poolId $computeNodeId2 -BatchContext $context | Reset-AzBatchComputeNode -ReimageOption $reimageOption -BatchContext $context
    $computeNode2 = Get-AzBatchComputeNode -PoolId $poolId $computeNodeId2 -BatchContext $context
    Assert-AreEqual 'Reimaging' $computeNode2.State
}


function Test-DisableAndEnableComputeNodeScheduling
{
    param([string]$poolId, [string]$computeNodeId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $disableOption = ([Microsoft.Azure.Batch.Common.DisableComputeNodeSchedulingOption]::Terminate)
    Get-AzBatchComputeNode $poolId $computeNodeId -BatchContext $context | Disable-AzBatchComputeNodeScheduling -DisableSchedulingOption $disableOption -BatchContext $context

    $computeNode = Get-AzBatchComputeNode -PoolId $poolId $computeNodeId -Select "id,schedulingState" -BatchContext $context
    Assert-AreEqual 'Disabled' $computeNode.SchedulingState

    $computeNode | Enable-AzBatchComputeNodeScheduling -BatchContext $context

    $computeNode = Get-AzBatchComputeNode -PoolId $poolId $computeNodeId -Select "id,schedulingState" -BatchContext $context
    Assert-AreEqual 'Enabled' $computeNode.SchedulingState
}


function Test-GetRemoteLoginSettings
{
    param([string]$poolId, [string]$computeNodeId)
    
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $remoteLoginSettings = Get-AzBatchComputeNode $poolId $computeNodeId -BatchContext $context | Get-AzBatchRemoteLoginSettings -BatchContext $context

    Assert-AreNotEqual $null $remoteLoginSettings.IPAddress
    Assert-AreNotEqual $null $remoteLoginSettings.Port
}

