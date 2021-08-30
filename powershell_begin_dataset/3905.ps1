














function Test-JobScheduleCRUD
{
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $jsId1 = "jobSchedule1"
    $jsId2 = "jobSchedule2"

    try
    {
        
        $jobSpec1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSJobSpecification
        $jobSpec1.PoolInformation = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolInformation
        $jobSpec1.PoolInformation.PoolId = "testPool"
        $schedule1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSSchedule
        New-AzBatchJobSchedule -Id $jsId1 -JobSpecification $jobSpec1 -Schedule $schedule1 -BatchContext $context

        $jobSpec2 = New-Object Microsoft.Azure.Commands.Batch.Models.PSJobSpecification
        $jobSpec2.PoolInformation = New-Object Microsoft.Azure.Commands.Batch.Models.PSPoolInformation
        $jobSpec2.PoolInformation.PoolId = "testPool2"
        $schedule2 = New-Object Microsoft.Azure.Commands.Batch.Models.PSSchedule
        $schedule2.DoNotRunUntil = New-Object System.DateTime -ArgumentList @(2020, 01, 01, 12, 30, 0)
        New-AzBatchJobSchedule -Id $jsId2 -JobSpecification $jobSpec2 -Schedule $schedule2 -BatchContext $context

        
        $jobSchedules = Get-AzBatchJobSchedule -Filter "id eq '$jsId1' or id eq '$jsId2'" -BatchContext $context
        $jobSchedule1 = $jobSchedules | Where-Object { $_.Id -eq $jsId1 }
        $jobSchedule2 = $jobSchedules | Where-Object { $_.Id -eq $jsId2 }
        Assert-NotNull $jobSchedule1
        Assert-NotNull $jobSchedule2

        
        $jobSchedule2.Schedule.DoNotRunUntil = $newDoNotRunUntil = New-Object System.DateTime -ArgumentList @(2025, 01, 01, 12, 30, 0)
        $jobSchedule2 | Set-AzBatchJobSchedule -BatchContext $context
        $updatedJobSchedule = Get-AzBatchJobSchedule -Id $jsId2 -BatchContext $context
        Assert-AreEqual $newDoNotRunUntil $updatedJobSchedule.Schedule.DoNotRunUntil
    }
    finally
    {
        
        Remove-AzBatchJobSchedule -Id $jsId1 -Force -BatchContext $context
        Remove-AzBatchJobSchedule -Id $jsId2 -Force -BatchContext $context

        foreach ($js in Get-AzBatchJobSchedule -BatchContext $context)
        {
            Assert-True { ($js.Id -ne $jsId1 -and $js.Id -ne $jsId2) -or ($js.State.ToString().ToLower() -eq 'deleting') }
        }
    }
}


function Test-DisableEnableTerminateJobSchedule
{
    param([string]$jobScheduleId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    Disable-AzBatchJobSchedule $jobScheduleId -BatchContext $context

    
    $jobSchedule = Get-AzBatchJobSchedule $jobScheduleId -BatchContext $context
    Assert-AreEqual 'Disabled' $jobSchedule.State

    $jobSchedule | Enable-AzBatchJobSchedule -BatchContext $context

    
    $jobSchedule = Get-AzBatchJobSchedule -Filter "id eq '$jobScheduleId'" -BatchContext $context
    Assert-AreEqual 'Active' $jobSchedule.State

    
    $jobSchedule | Stop-AzBatchJobSchedule -BatchContext $context

    
    $jobSchedule = Get-AzBatchJobSchedule $jobScheduleId -BatchContext $context
    Assert-True { ($jobSchedule.State.ToString().ToLower() -eq 'terminating') -or ($jobSchedule.State.ToString().ToLower() -eq 'completed') }
}