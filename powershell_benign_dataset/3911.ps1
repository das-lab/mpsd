














function Test-GetNodeFileContentByTask
{
    param([string]$jobId, [string]$taskId, [string]$nodeFilePath, [string]$fileContent)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $stream = New-Object System.IO.MemoryStream 

    try
    {
        $nodeFile = Get-AzBatchNodeFile -JobId $jobId -TaskId $taskId -Path $nodeFilePath -BatchContext $context
        $nodeFile | Get-AzBatchNodeFileContent -BatchContext $context -DestinationStream $stream
        
        $stream.Position = 0
        $sr = New-Object System.IO.StreamReader $stream
        $downloadedContents = $sr.ReadToEnd()

        
        Assert-True { $downloadedContents.Contains($fileContent) }
    }
    finally
    {
        if ($sr -ne $null)
        {
            $sr.Dispose()
        }
        $stream.Dispose()
    }
}


function Test-GetNodeFileContentByComputeNode
{
    param([string]$poolId, [string]$computeNodeId, [string]$nodeFilePath, [string]$fileContent)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $stream = New-Object System.IO.MemoryStream 

    try
    {
        $nodeFile = Get-AzBatchNodeFile -PoolId $poolId -ComputeNodeId $computeNodeId -Path $nodeFilePath -BatchContext $context
        $nodeFile | Get-AzBatchNodeFileContent -BatchContext $context -DestinationStream $stream
        
        $stream.Position = 0
        $sr = New-Object System.IO.StreamReader $stream
        $downloadedContents = $sr.ReadToEnd()

        
        Assert-True { $downloadedContents.Contains($fileContent) }
    }
    finally
    {
        if ($sr -ne $null)
        {
            $sr.Dispose()
        }
        $stream.Dispose()
    }
}


function Test-GetRDPFile
{
    param([string]$poolId, [string]$computeNodeId)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $stream = New-Object System.IO.MemoryStream 
    $rdpContents = "full address"

    try
    {
        $computeNode = Get-AzBatchComputeNode -PoolId $poolId -Id $computeNodeId -BatchContext $context
        $computeNode | Get-AzBatchRemoteDesktopProtocolFile -BatchContext $context -DestinationStream $stream
        
        $stream.Position = 0
        $sr = New-Object System.IO.StreamReader $stream
        $downloadedContents = $sr.ReadToEnd()

        
        Assert-True { $downloadedContents.Contains($rdpContents) }
    }
    finally
    {
        if ($sr -ne $null)
        {
            $sr.Dispose()
        }
        $stream.Dispose()
    }
}


function Test-DeleteNodeFileByTask 
{
    param([string]$jobId, [string]$taskId, [string]$filePath)
    
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    Get-AzBatchNodeFile -JobId $jobId -TaskId $taskId -Path $filePath -BatchContext $context | Remove-AzBatchNodeFile -Force -BatchContext $context
    
    
    $file = Get-AzBatchNodeFile -JobId $jobId -TaskId $taskId -Filter "startswith(name,'$filePath')" -BatchContext $context

    Assert-AreEqual $null $file
}


function Test-DeleteNodeFileByComputeNode 
{
    param([string]$poolId, [string]$computeNodeId, [string]$filePath)
    
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    Get-AzBatchNodeFile $poolId $computeNodeId $filePath -BatchContext $context | Remove-AzBatchNodeFile -Force -BatchContext $context

    
    $file = Get-AzBatchNodeFile $poolId $computeNodeId -Filter "startswith(name,'$filePath')" -BatchContext $context

    Assert-AreEqual $null $file
}