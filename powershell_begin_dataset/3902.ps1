















function Test-AddApplication
{
    
    $applicationName = "test"
    $applicationVersion = "foo"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzBatchApplication -AccountName $context.AccountName -ApplicationName $applicationName -ResourceGroupName $context.ResourceGroupName
        $getapp = Get-AzBatchApplication -AccountName $context.AccountName -ApplicationName $applicationName -ResourceGroupName $context.ResourceGroupName

        Assert-AreEqual $getapp.Id $addAppPack.Id
    }
    finally
    {
        Remove-AzBatchApplication  -AccountName $context.AccountName -ApplicationName $applicationName -ResourceGroupName $context.ResourceGroupName
    }
}