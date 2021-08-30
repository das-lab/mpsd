














function Test-PoolCRUD
{
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    
    $poolId1 = "pool1"
    $poolId2 = "pool2"

    try
    {
        
        $osFamily = "4"
        $targetOSVersion = "*"
        $targetDedicated = 0
        $vmSize = "small"
        $paasConfiguration = New-Object Microsoft.Azure.Commands.Batch.Models.PSCloudServiceConfiguration -ArgumentList @($osFamily, $targetOSVersion)
        New-AzBatchPool $poolId1 -CloudServiceConfiguration $paasConfiguration -TargetDedicated $targetDedicated -VirtualMachineSize $vmSize -BatchContext $context

        $vmSize = "standard_a1"
        $publisher = "Canonical"
        $offer = "UbuntuServer"
        $osSKU = "16.04.0-LTS"
        $nodeAgent = "batch.node.ubuntu 16.04"
        $imageRef = New-Object Microsoft.Azure.Commands.Batch.Models.PSImageReference -ArgumentList @($offer, $publisher, $osSKU)
        $iaasConfiguration = New-Object Microsoft.Azure.Commands.Batch.Models.PSVirtualMachineConfiguration -ArgumentList @($imageRef, $nodeAgent)
        New-AzBatchPool $poolId2 -VirtualMachineConfiguration $iaasConfiguration -TargetDedicated $targetDedicated -VirtualMachineSize $vmSize -BatchContext $context

        
        $pools = Get-AzBatchPool -Filter "id eq '$poolId1' or id eq '$poolId2'" -BatchContext $context
        $pool1 = $pools | Where-Object { $_.Id -eq $poolId1 }
        $pool2 = $pools | Where-Object { $_.Id -eq $poolId2 }
        Assert-NotNull $pool1
        Assert-NotNull $pool2

        
        $startTaskCmd = "/bin/bash -c 'echo start task'"
        $startTask = New-Object Microsoft.Azure.Commands.Batch.Models.PSStartTask -ArgumentList @($startTaskCmd)
        $pool2.StartTask = $startTask
        $pool2 | Set-AzBatchPool -BatchContext $context
        $updatedPool = Get-AzBatchPool $poolId2 -BatchContext $context
        Assert-AreEqual $startTaskCmd $updatedPool.StartTask.CommandLine
    }
    finally
    {
        
        Remove-AzBatchPool -Id $poolId1 -Force -BatchContext $context
        Remove-AzBatchPool -Id $poolId2 -Force -BatchContext $context

        
        foreach ($p in Get-AzBatchPool -BatchContext $context)
        {
            Assert-True { ($p.Id -ne $poolId1 -and $p.Id -ne $poolId2) -or ($p.State.ToString().ToLower() -eq 'deleting') }
        }
    }
}


function Test-ResizeAndStopResizePool
{
    param([string]$poolId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    
    $pool = Get-AzBatchPool -Id $poolId -BatchContext $context
    $initialTargetDedicated = $pool.TargetDedicatedComputeNodes

    $newTargetDedicated = $initialTargetDedicated + 1
    Start-AzBatchPoolResize -Id $poolId -TargetDedicatedComputeNodes $newTargetDedicated -BatchContext $context

    
    $pool = Get-AzBatchPool -Id $poolId -BatchContext $context
    Assert-AreEqual $newTargetDedicated $pool.TargetDedicatedComputeNodes

    
    $pool | Stop-AzBatchPoolResize -BatchContext $context

    
    $pool = Get-AzBatchPool -Id $poolId -BatchContext $context
    Assert-AreEqual 'Stopping' $pool.AllocationState
}


function Test-AutoScaleActions
{
    param([string]$poolId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $formula = '$TargetDedicatedNodes=0'
    $interval = ([TimeSpan]::FromMinutes(8))

    
    $pool = Get-AzBatchPool $poolId -BatchContext $context
    Assert-False { $pool.AutoScaleEnabled }

    $pool | Enable-AzBatchAutoScale -AutoScaleFormula $formula -AutoScaleEvaluationInterval $interval -BatchContext $context

    
    
    $pool = Get-AzBatchPool -Filter "id eq '$poolId'" -BatchContext $context
    Assert-True { $pool.AutoScaleEnabled }
    Assert-AreEqual $interval $pool.AutoScaleEvaluationInterval

    
    $testFormula = '$TargetDedicatedNodes=1'
    $evalResult = Test-AzBatchAutoScale $poolId $testFormula -BatchContext $context

    
    Assert-True { $evalResult.Results.Contains($testFormula) }

    
    $pool | Disable-AzBatchAutoScale -BatchContext $context

    
    $pool = Get-AzBatchPool $poolId -BatchContext $context
    Assert-False { $pool.AutoScaleEnabled }
}


function Test-ChangeOSVersion
{
    param([string]$poolId, [string]$specificOSVersion)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    
    $pool = Get-AzBatchPool $poolId -BatchContext $context
    Assert-AreNotEqual $specificOSVersion $pool.CloudServiceConfiguration.TargetOSVersion

    $pool | Set-AzBatchPoolOSVersion -TargetOSVersion $specificOSVersion -BatchContext $context
    
    
    $pool = Get-AzBatchPool $poolId -BatchContext $context
    Assert-AreEqual $specificOSVersion $pool.CloudServiceConfiguration.TargetOSVersion
}