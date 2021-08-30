














function Test-Trigger
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\scheduletrigger.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername

        Verify-Trigger $expected $actual $rgname $dfname $triggername

        Remove-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-StartTriggerThrowsWithoutPipeline
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\scheduletrigger.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername

        Verify-Trigger $expected $actual $rgname $dfname $triggername

        Assert-ThrowsContains {Start-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force} "BadRequest"
        
        Remove-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-TriggerRun
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "dsIn" -File .\Resources\dataset-dsIn.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds0_0" -File .\Resources\dataset-ds0_0.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds1_0" -File .\Resources\dataset-ds1_0.json -Force

        $pipelineName = "samplePipeline"   
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force

        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\scheduleTriggerWithPipeline.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername

        Verify-Trigger $expected $actual $rgname $dfname $triggername
        
        $startDate = [DateTime]::Parse("09/10/2017")
        Start-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $started = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Started' $started.RuntimeState 
        
        if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
            Start-Sleep -s 150
        }
        
        $endDate = $startDate.AddYears(1)
        $triggerRuns = Get-AzDataFactoryV2TriggerRun -ResourceGroupName $rgname -DataFactoryName $dfname -TriggerName $triggername -TriggerRunStartedAfter $startDate -TriggerRunStartedBefore $endDate
        
        if($triggerRuns.Count -lt 1)
        {
            throw "Expected atleast 1 trigger run"
        }
         
        Stop-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $stopped = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Stopped' $stopped.RuntimeState 

        Remove-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-BlobEventTriggerSubscriptions
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "dsIn" -File .\Resources\dataset-dsIn.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds0_0" -File .\Resources\dataset-ds0_0.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds1_0" -File .\Resources\dataset-ds1_0.json -Force

        $pipelineName = "samplePipeline"   
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force

        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\blobeventtrigger.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername

        Verify-Trigger $expected $actual $rgname $dfname $triggername
        
        $startDate = [DateTime]::Parse("09/10/2017")
		Add-AzDataFactoryV2TriggerSubscription -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
		$status = Get-AzDataFactoryV2TriggerSubscriptionStatus -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
		while ($status.Status -ne "Enabled"){
			if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
				Start-Sleep -s 150
			}
			$status = Get-AzDataFactoryV2TriggerSubscriptionStatus -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
		}
        
        Start-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $started = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Started' $started.RuntimeState 
        
		Remove-AzDataFactoryV2TriggerSubscription -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force

        Stop-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $stopped = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Stopped' $stopped.RuntimeState 

        Remove-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-BlobEventTriggerSubscriptionsByInputObject
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "dsIn" -File .\Resources\dataset-dsIn.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds0_0" -File .\Resources\dataset-ds0_0.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds1_0" -File .\Resources\dataset-ds1_0.json -Force

        $pipelineName = "samplePipeline"   
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force

        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\blobeventtrigger.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername

        Verify-Trigger $expected $actual $rgname $dfname $triggername
        
		Add-AzDataFactoryV2TriggerSubscription $actual
		$status = Get-AzDataFactoryV2TriggerSubscriptionStatus $actual
		while ($status.Status -ne "Enabled"){
			if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
				Start-Sleep -s 150
			}
			$status = Get-AzDataFactoryV2TriggerSubscriptionStatus $actual
		}
        
        Start-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $started = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Started' $started.RuntimeState 
        
		Remove-AzDataFactoryV2TriggerSubscription $started -Force

        Stop-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $stopped = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Stopped' $stopped.RuntimeState 

        Remove-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-BlobEventTriggerSubscriptionsByResourceId
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $lsName = "foo1"
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $rgname -DataFactoryName $dfname -File .\Resources\linkedService.json -Name $lsName -Force

        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "dsIn" -File .\Resources\dataset-dsIn.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds0_0" -File .\Resources\dataset-ds0_0.json -Force
        Set-AzDataFactoryV2Dataset -ResourceGroupName $rgname -DataFactoryName $dfname -Name "ds1_0" -File .\Resources\dataset-ds1_0.json -Force

        $pipelineName = "samplePipeline"   
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $rgname -Name $pipelineName -DataFactoryName $dfname -File ".\Resources\pipeline.json" -Force

        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\blobeventtrigger.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername

        Verify-Trigger $expected $actual $rgname $dfname $triggername
        
		Add-AzDataFactoryV2TriggerSubscription -ResourceId $expected.Id
		$status = Get-AzDataFactoryV2TriggerSubscriptionStatus -ResourceId $expected.Id
		while ($status.Status -ne "Enabled"){
			if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
				Start-Sleep -s 150
			}
			$status = Get-AzDataFactoryV2TriggerSubscriptionStatus -ResourceId $expected.Id
		}
        
        Start-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $started = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Started' $started.RuntimeState 
        
		Remove-AzDataFactoryV2TriggerSubscription -ResourceId $expected.Id -Force

        Stop-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
        $stopped = Get-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername
        
        Assert-AreEqual 'Stopped' $stopped.RuntimeState 

        Remove-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}


function Test-TriggerWithResourceId
{
    $dfname = Get-DataFactoryName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $dflocation = Get-ProviderLocation DataFactoryManagement
        
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

    try
    {
        $df = Set-AzDataFactoryV2 -ResourceGroupName $rgname -Name $dfname -Location $dflocation -Force
     
        $triggername = "foo"
        $expected = Set-AzDataFactoryV2Trigger -ResourceGroupName $rgname -DataFactoryName $dfname -Name $triggername -File .\Resources\scheduletrigger.json -Force
        $actual = Get-AzDataFactoryV2Trigger -ResourceId $expected.Id

        Verify-Trigger $expected $actual $rgname $dfname $triggername

        Remove-AzDataFactoryV2Trigger -ResourceId $expected.Id -Force
    }
    finally
    {
        CleanUp $rgname $dfname
    }
}



function Verify-Trigger ($expected, $actual, $rgname, $dfname, $name)
{
    Verify-AdfSubResource $expected $actual $rgname $dfname $triggername
    Assert-AreEqual $expected.RuntimeState $actual.RuntimeState
}
