















function Test-JobCRUD
{
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $jobId1 = "job1"
    $jobId2 = "job2"

    try
    {
        
        $poolInfo1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolInformation
        $poolInfo1.PoolId = "testPool"
        New-AzBatchJob -Id $jobId1 -PoolInformation $poolInfo1 -BatchContext $context

        $poolInfo2 = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolInformation
        $poolInfo2.PoolId = "testPool2"
        New-AzBatchJob -Id $jobId2 -PoolInformation $poolInfo2 -Priority 3 -BatchContext $context

        
        $jobs = Get-AzBatchJob -Filter "id eq '$jobId1' or id eq '$jobId2'" -BatchContext $context
        $job1 = $jobs | Where-Object { $_.Id -eq $jobId1 }
        $job2 = $jobs | Where-Object { $_.Id -eq $jobId2 }
        Assert-NotNull $job1
        Assert-NotNull $job2

        
        $job2.Priority = $newPriority = $job2.Priority + 2
        $job2 | Set-AzBatchJob -BatchContext $context
        $updatedJob = Get-AzBatchJob -Id $jobId2 -BatchContext $context
        Assert-AreEqual $newPriority $updatedJob.Priority
    }
    finally
    {
        
        Remove-AzBatchJob -Id $jobId1 -Force -BatchContext $context
        Remove-AzBatchJob -Id $jobId2 -Force -BatchContext $context

        foreach ($job in Get-AzBatchJob -BatchContext $context)
        {
            Assert-True { ($job.Id -ne $jobId1 -and $job.Id -ne $jobId2) -or ($job.State.ToString().ToLower() -eq 'deleting') }
        }
    }
}


function Test-DisableEnableTerminateJob
{
    param([string]$jobId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    Disable-AzBatchJob $jobId Terminate -BatchContext $context

    
    Start-TestSleep 10000

    
    $job = Get-AzBatchJob $jobId -BatchContext $context
    Assert-AreEqual 'Disabled' $job.State

    $job | Enable-AzBatchJob -BatchContext $context

    
    $job = Get-AzBatchJob -Filter "id eq '$jobId'" -BatchContext $context
    Assert-AreEqual 'Active' $job.State

    
    $job | Stop-AzBatchJob -BatchContext $context

    
    $job = Get-AzBatchJob $jobId -BatchContext $context
    Assert-True { ($job.State.ToString().ToLower() -eq 'terminating') -or ($job.State.ToString().ToLower() -eq 'completed') }
}


function Test-JobWithTaskDependencies
{
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $jobId = "testJob4"

    try
    {
        $osFamily = 4
        $targetOS = "*"
        $cmd = "cmd /c dir /s"
        $taskId = "taskId1"

        $paasConfiguration = New-Object Microsoft.Azure.Commands.Batch.Models.PSCloudServiceConfiguration -ArgumentList @($osFamily, $targetOSVersion)

        $poolSpec = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolSpecification
        $poolSpec.TargetDedicated = $targetDedicated = 3
        $poolSpec.VirtualMachineSize = $vmSize = "small"
        $poolSpec.CloudServiceConfiguration = $paasConfiguration
        $autoPoolSpec = New-Object Microsoft.Azure.Commands.Batch.Models.PSAutoPoolSpecification
        $autoPoolSpec.PoolSpecification = $poolSpec
        $autoPoolSpec.AutoPoolIdPrefix = $autoPoolIdPrefix = "TestSpecPrefix"
        $autoPoolSpec.KeepAlive =  $FALSE
        $autoPoolSpec.PoolLifeTimeOption = $poolLifeTime = ([Microsoft.Azure.Batch.Common.PoolLifeTimeOption]::Job)
        $poolInformation = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolInformation
        $poolInformation.AutoPoolSpecification = $autoPoolSpec

        $taskIds = @("2","3")
        $taskIdRange = New-Object Microsoft.Azure.Batch.TaskIdRange(1,10)
        $dependsOn = New-Object Microsoft.Azure.Batch.TaskDependencies -ArgumentList @([string[]]$taskIds, [Microsoft.Azure.Batch.TaskIdRange[]]$taskIdRange)
        New-AzBatchJob -Id $jobId -BatchContext $context -PoolInformation $poolInformation -usesTaskDependencies
        New-AzBatchTask -Id $taskId -CommandLine $cmd -BatchContext $context -DependsOn $dependsOn -JobId $jobId
        $job = Get-AzBatchJob -Id $jobId -BatchContext $context

        Assert-AreEqual $job.UsesTaskDependencies $TRUE
        $task = Get-AzBatchTask -JobId $jobId -Id $taskId -BatchContext $context
        Assert-AreEqual $task.DependsOn.TaskIdRanges.End 10
        Assert-AreEqual $task.DependsOn.TaskIdRanges.Start 1
        Assert-AreEqual $task.DependsOn.TaskIds[0] 2
        Assert-AreEqual $task.DependsOn.TaskIds[1] 3
    }
    finally
    {
        Remove-AzBatchJob -Id $jobId -Force -BatchContext $context
    }
}



function IfJobSetsAutoFailure-ItCompletesWhenAnyTaskFails
{
    param([string]$jobId, [string]$taskId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $osFamily = 4
    $targetOS = "*"
    $cmd = "cmd /c exit 3"

    $paasConfiguration = New-Object Microsoft.Azure.Commands.Batch.Models.PSCloudServiceConfiguration -ArgumentList @($osFamily, $targetOSVersion)

    $poolSpec = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolSpecification
    $poolSpec.TargetDedicatedComputeNodes = $targetDedicated = 3
    $poolSpec.VirtualMachineSize = $vmSize = "small"
    $poolSpec.CloudServiceConfiguration = $paasConfiguration
    $autoPoolSpec = New-Object Microsoft.Azure.Commands.Batch.Models.PSAutoPoolSpecification
    $autoPoolSpec.PoolSpecification = $poolSpec
    $autoPoolSpec.AutoPoolIdPrefix = $autoPoolIdPrefix = "TestSpecPrefix"
    $autoPoolSpec.KeepAlive =  $FALSE
    $autoPoolSpec.PoolLifeTimeOption = $poolLifeTime = ([Microsoft.Azure.Batch.Common.PoolLifeTimeOption]::Job)
    $poolInformation = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolInformation
    $poolInformation.AutoPoolSpecification = $autoPoolSpec

    $ExitConditions = New-Object Microsoft.Azure.Commands.Batch.Models.PSExitConditions
    $ExitOptions = New-Object Microsoft.Azure.Commands.Batch.Models.PSExitOptions
    $ExitOptions.JobAction =  [Microsoft.Azure.Batch.Common.JobAction]::Terminate
    $ExitCodeRangeMapping = New-Object Microsoft.Azure.Commands.Batch.Models.PSExitCodeRangeMapping -ArgumentList @(2, 4, $ExitOptions)
    $ExitConditions.ExitCodeRanges = [Microsoft.Azure.Commands.Batch.Models.PSExitCodeRangeMapping[]]$ExitCodeRangeMapping

    New-AzBatchJob -Id $jobId -BatchContext $context -PoolInformation $poolInformation -OnTaskFailure PerformExitOptionsJobAction
    New-AzBatchTask -Id $taskId -CommandLine $cmd -BatchContext $context -JobId $jobId -ExitConditions $ExitConditions
}