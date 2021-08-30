














function Test-TestStreamingAnalyticsE2E
{
    $resourceGroup = "ASASDK"
    $jobName = "TestJobPS"
	$inputName = "Input"
	$outputName = "Output"
	$transformationName = "transform1"
	$functionName = "scoreTweet"
	$expectedContainerName = "samples"
	$expectedTableName = "Samples"
	$expectedStreamingUnits = 1
	$expectedBatchSize = 10

	
	Assert-Throws { Get-AzStreamAnalyticsJob -Name $jobName -ResourceGroupName $resourceGroup }
	Assert-Throws { Get-AzStreamAnalyticsInput -Name $inputName -JobName $jobName -ResourceGroupName $resourceGroup }
	Assert-Throws { Get-AzStreamAnalyticsOutput -Name $outputName -JobName $jobName -ResourceGroupName $resourceGroup }
	Assert-Throws { Get-AzStreamAnalyticsTransformation -Name $transformationName -JobName $jobName -ResourceGroupName $resourceGroup }
	Assert-Throws { Get-AzStreamAnalyticsFunction -Name $functionName -JobName $jobName -ResourceGroupName $resourceGroup }

	
	$actual =  New-AzStreamAnalyticsJob -File .\Resources\job.json -ResourceGroupName $resourceGroup -Name $jobName -Force
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual "West US" $actual.Location
	Assert-AreEqual "Created" $actual.JobState
	Assert-AreEqual "Succeeded" $actual.ProvisioningState
	Assert-AreEqual $expectedContainerName $actual.Properties.Inputs[0].Properties.Datasource.Container
	Assert-AreEqual $expectedTableName $actual.Properties.Outputs[0].Datasource.Table
	Assert-AreEqual $expectedStreamingUnits $actual.Properties.Transformation.StreamingUnits
	Assert-AreEqual $expectedBatchSize $actual.Properties.Functions[0].Properties.Binding.BatchSize
	$expected = Get-AzStreamAnalyticsJob -Name $jobName -ResourceGroupName $resourceGroup
	Assert-AreEqual $expected.JobName $actual.JobName	
	Assert-AreEqual $expected.Location $actual.Location	
	Assert-AreEqual $expected.JobState $actual.JobState	
	Assert-AreEqual $expected.ProvisioningState $actual.ProvisioningState
	Assert-AreEqual $expected.Properties.Inputs[0].Properties.Datasource.Container $actual.Properties.Inputs[0].Properties.Datasource.Container
	Assert-AreEqual $expected.Properties.Outputs[0].Properties.Datasource.Table $actual.Properties.Outputs[0].Properties.Datasource.Table
	Assert-AreEqual $expected.Properties.Transformation.StreamingUnits $actual.Properties.Transformation.StreamingUnits
	Assert-AreEqual $expected.Properties.Functions[0].Properties.Binding.BatchSize $actual.Properties.Functions[0].Properties.Binding.BatchSize

	
	$actual = Get-AzStreamAnalyticsInput -JobName $jobName -ResourceGroupName $resourceGroup
	Assert-AreEqual $inputName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedContainerName $actual.Properties.Datasource.Container

    
	$actual = Get-AzStreamAnalyticsOutput -JobName $jobName -ResourceGroupName $resourceGroup
	Assert-AreEqual $outputName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedTableName $actual.Properties.Datasource.Table

	
	$actual = Get-AzStreamAnalyticsTransformation -JobName $jobName -Name $transformationName -ResourceGroupName $resourceGroup
	Assert-AreEqual $transformationName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedStreamingUnits $actual.Properties.StreamingUnits

	
	$actual = Get-AzStreamAnalyticsFunction -JobName $jobName -Name $functionName -ResourceGroupName $resourceGroup
	Assert-AreEqual $functionName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedBatchSize $actual.Properties.Binding.BatchSize

	
    $actual = New-AzStreamAnalyticsInput -File .\Resources\Input.json -JobName $jobName -ResourceGroupName $resourceGroup -Force
	Assert-AreEqual $inputName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedContainerName $actual.Properties.Datasource.Container

    
    $actual = Test-AzStreamAnalyticsInput -JobName $jobName -Name Input -ResourceGroupName $resourceGroup
	$expected = "True"
	Assert-AreEqual $expected $actual

	
	$actual = New-AzStreamAnalyticsOutput -File .\Resources\Output.json -JobName $jobName -ResourceGroupName $resourceGroup -Force
	Assert-AreEqual $outputName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedTableName $actual.Properties.Datasource.Table

	
    $actual = Test-AzStreamAnalyticsOutput -JobName $jobName -Name $outputName -ResourceGroupName $resourceGroup	
	$expected = "True"
	Assert-AreEqual $expected $actual

	
	$actual = New-AzStreamAnalyticsTransformation -File .\Resources\Transformation.json -JobName $jobName -ResourceGroupName $resourceGroup -Force
	Assert-AreEqual $transformationName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedStreamingUnits $actual.Properties.StreamingUnits

	
    $actual = New-AzStreamAnalyticsFunction -File .\Resources\Function.json -JobName $jobName -ResourceGroupName $resourceGroup -Force
	Assert-AreEqual $functionName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual $expectedBatchSize $actual.Properties.Binding.BatchSize

	
    $actual = Test-AzStreamAnalyticsFunction -JobName $jobName -Name $functionName -ResourceGroupName $resourceGroup	
	$expected = "True"
	Assert-AreEqual $expected $actual

	
    $actual = Get-AzStreamAnalyticsQuota -Location "West US"	
	$expected = 0
	Assert-AreEqual $expected $actual.CurrentCount

    
    $actual = Start-AzStreamAnalyticsJob -Name $jobName -ResourceGroupName $resourceGroup -OutputStartMode CustomTime -OutputStartTime 2012-12-12T12:12:12Z
	$expected = "True"
	Assert-AreEqual $expected $actual

	
    $actual = Get-AzStreamAnalyticsQuota -Location "West US"	
	$expected = 1
	Assert-AreEqual $expected $actual.CurrentCount

	
	$actual = Get-AzStreamAnalyticsInput -JobName $jobName -ResourceGroupName $resourceGroup
	Assert-NotNull $actual
	Assert-NotNull $actual.Properties.Diagnostics
	Assert-NotNull $actual.Properties.Diagnostics.Conditions
	Assert-NotNull $actual.Properties.Diagnostics.Conditions.Message

	
    $actual = Stop-AzStreamAnalyticsJob -Name $jobName -ResourceGroupName $resourceGroup	
	$expected = "True"
	Assert-AreEqual $expected $actual

	
	$actual = Get-AzStreamAnalyticsDefaultFunctionDefinition -File .\Resources\RetrieveDefaultFunctionDefinitionRequest.json -Name $functionName -JobName $jobName -ResourceGroupName $resourceGroup
	Assert-AreEqual $functionName $actual.Name
	Assert-AreEqual $jobName $actual.JobName
	Assert-AreEqual $resourceGroup $actual.ResourceGroupName
	Assert-AreEqual 1000 $actual.Properties.Binding.BatchSize

	
    $actual = Remove-AzStreamAnalyticsFunction -JobName $jobName -Name $functionName -ResourceGroupName $resourceGroup
	$expected = "True"
	Assert-AreEqual $expected $actual

    
    $actual = Remove-AzStreamAnalyticsOutput -JobName $jobName -Name Output -ResourceGroupName $resourceGroup
	$expected = "True"
	Assert-AreEqual $expected $actual

	
    $actual = Remove-AzStreamAnalyticsInput -JobName $jobName -Name Input -ResourceGroupName $resourceGroup
	$expected = "True"
	Assert-AreEqual $expected $actual

	
	Assert-Throws { Get-AzStreamAnalyticsInput -Name $inputName -JobName $jobName -ResourceGroupName $resourceGroup }
	Assert-Throws { Get-AzStreamAnalyticsOutput -Name $outputName -JobName $jobName -ResourceGroupName $resourceGroup }
	Assert-Throws { Get-AzStreamAnalyticsFunction -Name $functionName -JobName $jobName -ResourceGroupName $resourceGroup }

	
    $actual = Remove-AzStreamAnalyticsJob -Name $jobName -ResourceGroupName $resourceGroup
	$expected = "True"
	Assert-AreEqual $expected $actual

	
	Assert-Throws { Get-AzStreamAnalyticsJob -Name $jobName -ResourceGroupName $resourceGroup }
}